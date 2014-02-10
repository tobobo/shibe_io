passport = require('passport')
http = require 'http'
LocalStrategy = require('passport-local').Strategy
User = require '../models/user.coffee'

passport.use new LocalStrategy(User.authenticate())

passport.serializeUser (user, done) ->
  done null, user._id

passport.deserializeUser (id, done) ->
  User.findById id, (err, user) ->
    done err, user

req = http.IncomingMessage.prototype;

passportLogin = req.logIn

req.logIn = (user, res, options, done) ->
  if typeof options == 'function'
    done = options
    options = {}

  options = options || {}

  newCallback = (err) ->
    unless err?
      console.log res
      res.cookie 'shibe', user._id, 
        maxAge: 3600000
    if done
      done.apply arguments

  passportLogin.call this, user, options, newCallback


module.exports = passport
