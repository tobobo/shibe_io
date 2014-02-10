mongoose = require 'mongoose'
passportLocalMongoose = require 'passport-local-mongoose'
crypto = require 'crypto'

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
  active: 
    type: Boolean
    default: false

defaults =
  createdAt: ->
    new Date

  activationToken: ->
    crypto.createHash('md5').update(Math.random.toString()).digest('hex')

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
