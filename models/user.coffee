mongoose = require 'mongoose'
passportLocalMongoose = require 'passport-local-mongoose'

module.exports = mongoose.model 'User', new Schema()

module.exports.plugin passportLocalMongoose,
  usernameField: 'email'
