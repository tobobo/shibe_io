incoming = require "../controllers/incoming.coffee"

module.exports = (app) ->

  app.get '/', (req, res) ->
    res.write 'hello world'
    res.end()

  app.post '/incoming', incoming.index
