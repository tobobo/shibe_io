passport = require('passport')
http = require 'http'
LocalStrategy = require('passport-local').Strategy
User = require '../models/user.coffee'

passport.use new LocalStrategy(User.authenticate())

passport.serializeUser (user, done) ->
  console.log 'serialize user'
  console.log user._id
  done null, user._id

passport.deserializeUser (id, done) ->
  console.log 'deserialize user'
  User.findById id, (err, user) ->
    console.log user._id
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
      res.cookie 'shibe', user._id,
        maxAge: 60*60*1000
        domain: process.env.SHIBE_COOKIE_DOMAIN
    if done
      done.apply arguments

  passportLogin.call this, user, options, newCallback

passportLogout = req.logOut

req.logOut = (res) ->
  res.cookie 'shibe', null,
    domain: process.env.SHIBE_COOKIE_DOMAIN
  passportLogout.call this


module.exports = passport
