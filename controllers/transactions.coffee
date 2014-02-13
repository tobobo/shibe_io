Transaction = require '../models/transaction'

module.exports =
  index: (req, res) ->
    if req.query.confirmation_code
      query =
        confirmation_code: req.query.confirmation_code
    if query
      Transaction.find query, (err, transactions) =>
        res.write Transaction.serialize transactions
        res.end()
    else
      res.write JSON.stringify
        transactions: []
        meta:
          error: "Cannot get all transactions."
      res.end()
