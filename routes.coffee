mandrill_events = require "./mandrill_events.coffee"

module.exports = (app) ->

  app.get '/', (req, res) ->
    res.write 'hello world'
    res.end()

  app.post '/incoming', (req, res, data) ->

    transactions = mandrill_events.process req.body.mandrill_events
    res.write JSON.stringify transactions
    res.end()
