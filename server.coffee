express = require "express"
db = require "./config/db"
db.connect()

app = express()

app.use express.bodyParser()
app.use require('./utils/origin_middleware.coffee')

require("./config/routes.coffee")(app)

db.mongoose.connection.on 'open', ->
  app.listen Number(process.env.PORT or 8888)
