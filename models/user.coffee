mongoose = require 'mongoose'
passportLocalMongoose = require 'passport-local-mongoose'
crypto = require 'crypto'
mailer = require '../config/mailer'
doge_api = require '../config/doge_api'
Transaction = require '../models/transaction'

RSVP = require '../utils/rsvp'

userSchema = new mongoose.Schema
  email:
    type: String
    unique: true
    required: true
    trim: true
    lowercase: true
  createdAt: Date
  balance:
    type: Number
    default: 0
  deposited:
    type: Number
    default: 0
  sent:
    type: Number
    default: 0
  received:
    type: Number
    default: 0
  depositAddress: String
  activationToken: String
  activationTokenCreatedAt: Date
  lastSignIn: Date
  transactionsAccepted:
    type: Boolean
    default: false
  activationEmailSent:
    type: Boolean
    default: false
  active: 
    type: Boolean
    default: false

userSchema.methods.updateBalanceFromDeposits = ->
  new RSVP.Promise (resolve, reject) =>
    prev_deposited = @deposited
    Transaction.find
      receiverId: @id
      status: Transaction.STATUS.DEPOSIT
    , (err, transactions) =>
      if err?
        reject err
      else
        transactionSum = transactions.map (transaction) =>
          transaction.amount
        .reduce (a, b) ->
          a + b
        , 0
        if transactionSum > prev_deposited
          @deposited = transactionSum
          @balance = @deposited + @received - @sent
          @save (err, user) ->
            resolve transactionSum - prev_deposited
        else
          resolve 0

userSchema.methods.checkDeposits = ->
  (=>
    if @depositAddress?
      RSVP.resolve @depositAddress
    else
      @createDepositAddress()
  )().then (address) =>
    doge_api.getReceivedByAddress address
  .then (amount) =>
    amount = parseFloat amount
    prev_amount = @deposited
    new RSVP.Promise (resolve, reject) ->
      if amount > prev_amount
        resolve amount - prev_amount
      else
        resolve 0
  .then (amountDeposited) =>
    new RSVP.Promise (resolve, reject) =>
      if amountDeposited > 0
        transaction = new Transaction
          receiverId: @id
          amount: amountDeposited
          status: Transaction.STATUS.DEPOSIT
        transaction.save (err, transaction) =>
          resolve transaction.amount
      else
        resolve amountDeposited
  .then (amountDeposited) =>
    if amountDeposited > 0
      @updateBalanceFromDeposits()
    else
      RSVP.resolve @balance



userSchema.methods.sendActivationEmail = (cb) ->
  mailData = 
    from: mailer.default_from
    to: @email
    subject: 'Activate your Shibe.io Account'
    body: "your token is #{process.env.SHIBE_FRONTEND_URL}/activate/#{@activationToken}"
  mailer.sendMail mailData, (err, result) =>
    if err?
      if cb?
        cb err, this
    else
      @activationEmailSent = true
      @save (err, user) ->
        if cb?
          cb err, user

userSchema.methods.createDepositAddress = ->
  if @email?
    addressLabel = "#{@email.replace(/\W/g, '')}#{Math.floor(Math.random()*1000000)}"
    doge_api.getNewAddress(addressLabel).then (address) =>
      new RSVP.Promise (resolve, reject) =>
        @depositAddress = address
        @save().then (err, user) ->
          resolve address
    , (error) =>
      console.log 'Deposit address creation error'
  else
    new RSVP.Promise (resolve, reject) ->
      reject "No email address"

userSchema.methods.acceptTransactions = ->
  new RSVP.Promise (resolve, reject) ->
    Transaction.find
      receiverId: @id
      acceptance: Transaction.ACCEPTANCE.PENDING
    , (err, transactions) ->
      resolve transactions
  .then (transactions) =>
    if transactions.length > 0
      transactionPromises = transactions.map (transaction) ->
        new RSVP.Promise (resolve, reject) ->
          transaction.acceptance = Transaction.ACCEPTANCE.ACCEPTED
          transaction.save (err, transaction) ->
            resolve transaction
      RSVP.all transactionPromises
    else
      RSVP.resolve transactions
  .then (transactions) =>
    new RSVP.Promise (resolve, reject) =>
      @transactionsAccepted = true
      @save (err, user) ->
        resolve transactions


userSchema.post 'save', (user) ->
  unless user.activationEmailSent
    user.sendActivationEmail()
  if user.active and not user.depositAddress?
    user.createDepositAddress()
  if user.active and not user.transactionsAccepted
    user.acceptTransactions()


defaults =
  createdAt: ->
    new Date

  activationToken: ->
    crypto.createHash('md5').update(Math.random().toString()).digest('hex')

  activationTokenCreatedAt: ->
    new Date

for k, v of defaults
  userSchema.path(k).default v

userSchema.plugin passportLocalMongoose,
  usernameField: 'email'

userSchema.methods.serialize = (meta) ->
  JSON.stringify
    user:
      id: @id
      email: @email
      active: @active
      depositAddress: @depositAddress
    meta:
      meta

module.exports = mongoose.model 'User', userSchema
