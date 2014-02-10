mongoose = require('mongoose')
db_url = process.env.SHIBE_DB_URL

(connect = ->
  mongoose.connect(db_url)
)()

module.exports = connection = mongoose.connection

connection.on 'error', (err) ->
  console.log err

connection.on 'open', ->
  console.log "connection to #{db_url} opened"

connection.on 'disconnected', ->
  connect()
