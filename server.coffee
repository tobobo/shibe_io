express = require "express"

app = express()

app.use express.bodyParser()

app.use (req, res, next) ->
  res.header 'Access-Control-Allow-Origin', '*.shibe.io'
  next()

require("./routes.coffee")(app)

app.listen Number(process.env.PORT or 8888)
