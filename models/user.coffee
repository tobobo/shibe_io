mongoose = require 'mongoose'
passportLocalMongoose = require 'passport-local-mongoose'

userSchema = new mongoose.Schema()

userSchema.plugin passportLocalMongoose,
  usernameField: 'email'

userSchema.methods.serialize = (meta) ->
  JSON.stringify
    user:
      _id: this._id
      email: this.email
    meta:
      meta

module.exports = mongoose.model 'User', userSchema
