mandrill_events = require '../utils/mandrill_events'
RSVP = require 'rsvp'
models = require '../models/models'
Transaction = models.Transaction

module.exports =
  index: (req, res, data) ->
    console.log 'incoming!!!'
    Transaction.createFromEmail(req.body.mandrill_events).then (transactions) ->
      console.log 'created transaction from email'
      res.write Transaction.serialize (transactions)
      res.end()
