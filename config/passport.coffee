module.exports = require('passport')
LocalStrategy = require('passport-local').Strategy
User = require '../models/user.coffee'

module.exports.use new LocalStrategy(User.authenticate())

module.exports.serializeUser User.serializerUser()
