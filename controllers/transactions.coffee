Transaction = require '../models/transaction'

module.exports =
  index: (req, res) ->
    if req.query.confirmationCode
      query =
        confirmationCode: req.query.confirmationCode
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
