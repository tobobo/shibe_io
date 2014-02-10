express = require "express"
passport = require 'passport'
db = require "./config/db"
db.connect()

app = express()

app.use express.static('public')
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser()
app.use express.session
  secret: process.env.SHIBE_SESSION_SECRET

app.use passport.initialize()
app.use passport.session()

app.use express.methodOverride()

app.use require('./utils/origin_middleware.coffee')

require("./config/routes.coffee")(app)

db.mongoose.connection.on 'open', ->
  app.listen Number(process.env.PORT or 8888)
