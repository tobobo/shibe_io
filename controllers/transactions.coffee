Transaction = require '../models/transaction'
User = require '../models/user'
RSVP = require 'rsvp'

module.exports =
  index: (req, res) ->
    if req.query.confirmationCode?
      query =
        confirmationCode: req.query.confirmationCode

    if query?
      Transaction.find query, (err, transactions) =>
        if (query.confirmationCode? or query.acceptanceCode?) and transactions.length > 0
          req.logOut res
        res.write Transaction.serialize transactions
        res.end()
    else
      res.write JSON.stringify
        transactions: []
        meta:
          error: "Cannot get all transactions."
      res.end()

  update: (req, res) ->
    id = req.params.id
    if req.body.transaction?
      confirmationCode = req.body.transaction.confirmationCode
      acceptanceCode = req.body.transaction.acceptanceCode
    if id? and (confirmationCode? or acceptanceCode?)
      query = 
        id: req.params.id
      for p, v of { confirmationCode: req.body.confirmationCode, acceptanceCode: req.body.acceptanceCode }
        if v?
          query[p] = v

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
            if req.body.transaction.confirmationCode?
              transaction.confirmation = req.body.transaction.confirmation
              transaction.senderId = user.id
            else if req.body.acceptanceCode?
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
