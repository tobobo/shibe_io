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
      if (query? and (query.confirmationCode? or query.acceptanceCode?)) and transactions.length > 0
        req.logOut res
      res.write Transaction.serialize transactions
      res.end()
    , (error) =>
      res.statusCode = 403
      res.write JSON.stringify
        transactions: []
        meta:
          error: error
      res.end()

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

      Transaction.find query, (err, transactions) =>
        if transactions.length > 0
          req.logOut res
          transaction = transactions[0]
          new RSVP.Promise (resolve, reject) =>
            if req.body.transaction.userEmail? and req.body.transaction.userPassword?
              email = req.body.transaction.userEmail
              password = req.body.transaction.userPassword
              User.find
                email: email
              , (err, users) =>
                if users.length > 0
                  user = users[0]
                  if user.active
                    User.authenticate() user.email, password, (err, user) ->
                      if err?
                        reject "Authentication error"
                      else
                        req.logIn user, res, (error) ->
                          resolve user
                  else
                    console.log 'activating user'
                    user.active = true
                    user.save (err, user) ->
                      user.setPassword password, (err, user) ->
                        req.logIn user, res, (error) ->
                          resolve user
                else if req.body.transaction.acceptanceCode?
                  if email == transaction.to
                    active = true
                    password = password
                  else
                    active = false
                    password = null

                  user = new User
                    email: email
                    active: active
                  user.save (err, user) ->
                    transaction.receiverId = user.id
                    transaction.save (err, transaction) ->
                      if user.active
                        user.setPassword password, (err, user) ->
                          req.logIn user, res, (error) ->
                            resolve user
                      else
                        resolve user
                else
                  reject "Authentication error"
            else
              reject "Please enter a username and password"
          .then (user) ->
            console.log "confirmed by #{user.email}"
            if req.body.transaction.confirmationCode?
              console.log 'there was a confirmation code'
              if parseInt(req.body.transaction.confirmation) == parseInt(Transaction.CONFIRMATION.ACCEPTED)
                if user.balance < transaction.amount
                  console.log 'insufficient funds'
                  transaction.confirmation = Transaction.CONFIRMATION.INSUFFICIENT_FUNDS
                else
                  console.log 'sufficient funds'
                  transaction.confirmation = Transaction.CONFIRMATION.ACCEPTED
              transaction.senderId = user.id

            else if req.body.transaction.acceptanceCode?
              transaction.acceptance = req.body.transaction.acceptance
              transaction.receiverId = user.id

            transaction.save (err, transaction) ->
              res.write transaction.serialize()
              res.end()

          , (error) ->
            res.write JSON.stringify
              transaction: null
              meta:
                error: error
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
