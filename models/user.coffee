mongoose = require 'mongoose'
passportLocalMongoose = require 'passport-local-mongoose'
crypto = require 'crypto'
mailer = require '../config/mailer'
doge_api = require '../config/doge_api'

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
  withdrawalAddress: String
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

userSchema.methods.checkDeposits = ->
  (=>
    console.log 'getting deposit address'
    if @depositAddress?
      RSVP.resolve @depositAddress
    else
      @createDepositAddress()
  )().then (address) =>
    doge_api.getReceivedByAddress address
  .then (amount) =>
    amount = parseFloat amount
    prev_amount = @deposited
    if amount > prev_amount
      RSVP.resolve amount - prev_amount
    else
      RSVP.resolve 0
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
      @updateBalance()
    else
      RSVP.resolve amountDeposited



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
      balance: @balance
      createdAt: @createdAt
    meta:
      meta

module.exports = userSchema
