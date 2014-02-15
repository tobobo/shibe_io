mandrill_events = require '../utils/mandrill_events'
RSVP = require 'rsvp'
models = require '../models/models'
Transaction = models.Transaction

module.exports =
  index: (req, res, data) ->
    transactions = mandrill_events.process req.body.mandrill_events

    transactionPromises = transactions.map (transaction) ->
      new RSVP.Promise (resolve, reject) ->
        transaction = new Transaction transaction
        transaction.save (err, transaction) ->
          transaction._error = err
          resolve transaction

    RSVP.all(transactionPromises).then (transactions) ->      
      res.write Transaction.serialize transactions,
        success: 'Transactions saved'
      res.end()
