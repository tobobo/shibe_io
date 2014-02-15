mongoose = require('mongoose')
db_url = process.env.SHIBE_DB_URL

module.exports.mongoose = mongoose
reconnectTimer = 1

module.exports.connect = connect = (cb) ->
  mongoose.connect db_url, cb

module.exports.url = db_url

mongoose.connection.on 'open', ->
  reconnectTimer = 1

mongoose.connection.on 'error', (err) ->
  console.log 'mongo error', err

mongoose.connection.on 'disconnected', ->
  console.log "mongo disconnected. reconnecting in #{reconnectTimer} second#{if reconnectTimer > 1 then 's' else ''}..."
  setTimeout ->
    reconnectTimer *= 2
    connect()
  , reconnectTimer*1000
