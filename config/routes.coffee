incoming = require "../controllers/incoming.coffee"
users = require "../controllers/users.coffee"

module.exports = (app) ->

  app.get '/', (req, res) ->
    res.write 'hello world'
    res.end()

  app.post '/incoming', incoming.index

  app.post '/users/new', users.new
