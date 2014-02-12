mongoose = require 'mongoose'
passportLocalMongoose = require 'passport-local-mongoose'
crypto = require 'crypto'
mailer = require '../config/mailer'
doge_api = require '../config/doge_api'

RSVP = require 'rsvp'

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
    addressLabel = "#{@email.replace(/\W/g, '_')}#{Math.floor(Math.random()*1000000)}"
    doge_api.getNewAddress addressLabel
    .then (address) =>
      new RSVP.Promise (resolve, reject) =>
        @depositAddress = address
        @save().then (err, user) ->
          resolve user
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
      _id: @_id
      email: @email
      active: @active
    meta:
      meta

module.exports = mongoose.model 'User', userSchema
