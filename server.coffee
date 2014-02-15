require 'newrelic'
express = require "express"
passport = require 'passport'
db = require "./config/db"
db.connect()

app = express()

MongoStore = require('connect-mongo') express

app.use express.static('public')
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser(process.env.SHIBE_SESSION_SECRET)
app.use express.session
  secret: process.env.SHIBE_SESSION_SECRET
  store: new MongoStore
    collection: 'shibe-sessions'
    url: db.url
  , (db) ->
    console.log 'mongo store connected'
  cookie:
    maxAge: 60*60*1000
    domain: process.env.SHIBE_COOKIE_DOMAIN

app.use passport.initialize()
app.use passport.session()

app.use (req, res, next) ->
  if req.user
    console.log 'reqest user id:', req.user._id
  next()

# app.use (req, res, next) ->
#     console.log('-- session --');
#     console.dir(req.session);
#     console.log('-------------');
#     console.log('-- cookies --');
#     console.dir(req.cookies);
#     console.log('-------------');
#     console.log('-- signed cookies --');
#     console.dir(req.signedCookies);
#     console.log('-------------');
#     next()

app.use require('./utils/origin_middleware.coffee')

require("./config/routes.coffee")(app)

db.mongoose.connection.on 'open', ->
  app.listen Number(process.env.PORT or 8888)
