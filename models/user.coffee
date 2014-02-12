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
  activationEmailSent:
    type: Boolean
    default: false
  active: 
    type: Boolean
    default: false

userSchema.methods.updateBalanceFromDeposits = ->
  console.log 'updating balance from deposits'
  new RSVP.Promise (resolve, reject) =>
    prev_deposited = @deposited
    console.log 'finding transactions'
    Transaction.find
      receiverId: @id
      status: Transaction.STATUS.DEPOSIT
    , (err, transactions) =>
      console.log 'found', transactions.length, 'transactions'
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
    console.log "#{@email} has deposited #{amount}"
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


userSchema.post 'save', (user) ->
  unless user.activationEmailSent
    user.sendActivationEmail()
  if user.active and not user.depositAddress?
    user.createDepositAddress()


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
    meta:
      meta

module.exports = mongoose.model 'User', userSchema
