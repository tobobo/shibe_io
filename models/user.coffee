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
    to: this.email
    subject: 'Activate your Shibe.io Account'
    body: "your token is #{process.env.SHIBE_FRONTEND_URL}/activate/#{this.activationToken}"
  mailer.sendMail mailData, (err, result) =>
    if err?
      if cb?
        cb err, this
    else
      console.log "sent activation email", mailData
      this.activationEmailSent = true
      this.save (err, user) ->
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
      _id: this._id
      email: this.email
      active: this.active
    meta:
      meta

module.exports = mongoose.model 'User', userSchema
