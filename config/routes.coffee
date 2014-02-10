incoming = require "../controllers/incoming.coffee"
users = require "../controllers/users.coffee"
passport = require '../config/passport.coffee'

module.exports = (app) ->

  app.get '/', (req, res) ->
    res.write 'hello world'
    res.end()

  app.post '/incoming', incoming.index

  app.post '/users/new', users.new
  app.post '/users/activate', users.activate
  app.post '/users/login', users.login

