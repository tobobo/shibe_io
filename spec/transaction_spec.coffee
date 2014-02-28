models = require '../models/models'
User = models.User
Transaction = models.Transaction
mongoose = require 'mongoose'
RSVP = require 'rsvp'
mongoose.connect process.env.SHIBE_DB_URL
console.log 'heyyyyy'
describe 'transaction', ->

  it 'can be created between existing users', (done) ->

    mongoose.connection.on 'open', ->
      console.log 'connection open'
      depositAmount = 50
      transactionAmount = 10
      senderData = 
        email: "onesender#{(new Date).getTime()}@what.com"
        password: "asjdfkasdfjlfjkld"
      receiverData = 
        email: "onereceiver#{(new Date).getTime()}@what.com"
        password: "sldkjfkldjsfjkflds"
      userPromises = [senderData, receiverData].map (userData) =>
        new RSVP.Promise (resolve, reject) =>
          user = new User userData
          user.save (err, user) =>
            console.log 'saved user', user, err
            user.setPassword userData.password, (err, user) =>
              console.log 'set password', user, err
              resolve user
      console.log 'wut'
      RSVP.all(userPromises).then (users) =>
        console.log 'users', users
        new RSVP.Promise (resolve, reject) =>
          deposit = new Transaction
            amount: depositAmount
            status: Transaction.STATUS.COMPLETE
            receiverId: users[0].id
          console.log 'deposit be', deposit
          deposit.save (err, deposit) =>
            console.log 'saved deposit', arguments
            resolve users
      .then (users) =>
        new RSVP.Promise (resolve, reject) =>
          setTimeout =>
            users[0].updateBalance()
          , 500
      .then (users) =>
        console.log 'here', users[0].id, users[1].id
        new RSVP.Promise (resolve, reject) =>
          exchange = new Transaction
            amount: transactionAmount
            from: users[0].email
            to: users[1].email
            senderId: users[0].id
            receiverId: users[1].id
          console.log 'transaction pre save', exchange
          exchange.save (transaction, err) =>
            console.log 'saved transaction', err, transaction
            resolve transaction
      .then (transaction) =>
        transaction.processWithCredentials
          confirmationCode: transaction.confirmationCode
          userEmail: senderData.email
          userPassword: senderData.password
      .then (transaction) =>
        console.log 'what', transaction
        done()
  , 15000