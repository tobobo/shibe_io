mandrill_events = require '../utils/mandrill_events'

module.exports =
  index: (req, res, data) ->
    transactions = mandrill_events.process req.body.mandrill_events
    res.write JSON.stringify transactions
    res.end()
