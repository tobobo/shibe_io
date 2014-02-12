mongoose = require 'mongoose'
passportLocalMongoose = require 'passport-local-mongoose'
crypto = require 'crypto'
mailer = require '../config/mailer'

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
      console.log "sent activation email", mailData
      @activationEmailSent = true
      @save (err, user) ->
        if cb?
          cb err, user

userSchema.post 'save', (user) ->
  unless user.activationEmailSent
    user.sendActivationEmail()


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
