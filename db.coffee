mongoose = require('mongoose')
db_url = 'mongodb://localhost/shibe-io-test'

(connect = ->
  mongoose.connect(db_url)
)()

module.exports = connection = mongoose.connection

connection.on 'error', (err) ->
  console.log err

connection.on 'open', ->
  console.log 'connection to mongodb opened'

connection.on 'disconnected', ->
  connect()
