models = require '../models/models'
RSVP = require '../utils/rsvp'

Transaction = models.Transaction
User = models.User

module.exports =
  index: (req, res) ->
    (->
      if req.query.confirmationCode? or req.query.acceptanceCode?
        query = {}
        for p in ['confirmationCode', 'acceptanceCode']
          if req.query[p]?
            query[p] = req.query[p]
        Transaction.find(query).exec()

      else if req.query.userId?
        if req.user? and parseInt(req.query.userId) == parseInt(req.user._id)
          req.user.getTransactions()
        else
          RSVP.reject "Not authorized to get transactions for that user"

      else
        RSVP.reject "Cannot get all transactions"
    )().then (transactions) =>
      console.log 'transactions', transactions
      if (query? and (query.confirmationCode? or query.acceptanceCode?)) and transactions.length > 0
        req.logOut res
      res.write Transaction.serialize transactions
      res.end()
    , (error) =>
      console.log 'error!'
      res.statusCode = 403
      res.write JSON.stringify
        transactions: []
        meta:
          error: error
      res.end()

  new: (req, res) ->
    (->
      if req.body.transaction? and req.body.transaction.senderId?
        if req.body.transaction.senderId == req.user.id
          params =
            receiverAddress: req.body.transaction.receiverAddress
            senderId: req.body.transaction.senderId
            amount: req.body.transaction.amount

          transaction = new Transaction params

          transaction.process()
        else
          RSVP.reject "Cannot create transaction for that user."
      else
        RSVP.reject "No transaction parameters."
    )().then (transaction) =>
      console.log 'made transaction'
      res.write transaction.serialize(),
        success: 'Withdrawal complete.'
      res.end()
    (error) =>
      res.write JSON.serialize
        transaction: null
        error: error

  update: (req, res) ->
    id = req.params.id
    if req.body.transaction?
      confirmationCode = req.body.transaction.confirmationCode
      acceptanceCode = req.body.transaction.acceptanceCode
    if id? and (confirmationCode? or acceptanceCode?)
      query = 
        id: req.params.id
      for v of ['confirmationCode', 'acceptanceCode']
        if req.body[v]?
          query[p] = req.body[v]

      Transaction.findOne query, (err, transaction) =>
        if transaction?
          transaction.processWithCredentials req.body.transaction
          .then (transaction) ->
            res.write transaction.serialize()
            res.end()
        else
          res.write JSON.stringify
            transaction: null
            meta:
              error: "Transaction not found."
          res.end()
    else
      res.statusCode = 422
      res.write JSON.stringify
        transaction: null
        meta:
          error: "Cannot update transaction without id and confirmation or acceptance code."
      res.end()
