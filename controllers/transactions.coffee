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

      Transaction.find query, (err, transactions) =>
        if transactions.length > 0
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
                          console.log 'error', error
                          console.log 'logged in', user.email
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
                  console.log 'creating user'
                  user = new User
                    email: email
                    active: active
                  user.save (err, user) ->
                    console.log "setting receiver id to #{user.id}"
                    transaction.receiverId = user.id
                    transaction.save (err, transaction) ->
                      console.log 'saved transaction'
                      if user.active
                        console.log 'setting user password'
                        user.setPassword password, (err, user) ->
                          req.logIn user, res, (error) ->
                            resolve user
                      else
                        req.logOut res
                        resolve user
                else
                  reject "Authentication error"
            else
              reject "Please enter a username and password"
          .then (user) ->
            console.log "confirmed by #{user.email}"
            if req.body.transaction.confirmationCode?
              if parseInt(req.body.transaction.confirmation) == parseInt(Transaction.CONFIRMATION.ACCEPTED)
                if user.balance < transaction.amount
                  transaction.confirmation = Transaction.CONFIRMATION.INSUFFICIENT_FUNDS
                else
                  transaction.confirmation = Transaction.CONFIRMATION.ACCEPTED
              transaction.senderId = user.id

            else if req.body.transaction.acceptanceCode?
                  
              transaction.acceptance = req.body.transaction.acceptance
              transaction.receiverId = user.id

            transaction.save (err, transaction) ->
              res.write transaction.serialize()
              res.end()

          , (error) ->
            req.logOut res
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
