incoming = require "../controllers/incoming.coffee"
users = require "../controllers/users.coffee"
transactions = require "../controllers/transactions.coffee"
passport = require '../config/passport.coffee'

module.exports = (app) ->

  app.get '/', (req, res) ->
    res.write 'hello world'
    res.end()

  app.post '/incoming', incoming.index

  app.get '/users/:id', users.user
  app.post '/users/new', users.new
  app.post '/users/activate', users.activate
  app.post '/users/login', users.login
  app.delete '/users/logout', users.logout

  app.get '/transactions', transactions.index
  app.post '/transactions', transactions.new
  app.put '/transactions/:id', transactions.update

