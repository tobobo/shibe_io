mongoose = require('mongoose')
db_url = process.env.SHIBE_DB_URL

module.exports.mongoose = mongoose

module.exports.connect = connect = ->
  mongoose.connect db_url

mongoose.connection.on 'error', (err) ->
  console.log 'mongo error', err

mongoose.connection.on 'disconnected', ->
  connect()
