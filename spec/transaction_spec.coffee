models = require '../models/models'
User = models.User
Transaction = models.Transaction
mongoose = require 'mongoose'
RSVP = require 'rsvp'
mongoose.connect process.env.SHIBE_DB_URL

describe 'transaction', ->

  it 'can be created between existing users', (done) ->
    depositAmount = 50
    transactionAmount = 10
    mongoose.connection.on 'open', ->
      from = "oneuser#{(new Date).getTime()}@somewhere.come"
      to = "anotheruser#{(new Date).getTime()}@somewhere.come"
      userPromises = [from, to].map (email) ->
        new RSVP.Promise (resolve, reject) ->
          user = new User
            email: email
            active: true
            transactionsAccepted: true
            activationEmailSent: true
          user.save (err, user) ->
            resolve user
      RSVP.all(userPromises).then (users) ->
        new RSVP.Promise (resolve, reject) ->
          from = users[0]
          to = users[1]
          transaction = new Transaction
            amount: depositAmount
            receiverId: users[0].id
            status: Transaction.STATUS.DEPOSIT
          transaction.save (err, transaction) ->
            resolve users
      .then (users) ->
        new RSVP.Promise (resolve, reject) ->
          from = users[0]
          to = users[1]
          transaction = new Transaction
            amount: transactionAmount
            from: from.email
            to: to.email
            senderId: from.id
            receiverId: to.id
            status: Transaction.STATUS.ANNOUNCED
          transaction.save (err, transaction) ->
            resolve transaction
      .then (transaction) ->
        new RSVP.Promise (resolve, reject) ->
          transaction.confirmation = 1
          transaction.acceptance = 1
          transaction.save (err, transaction) ->
            resolve transaction
      .then (transaction) ->
        new RSVP.Promise (resolve, reject) ->
          setTimeout ->
            userPromises = [transaction.senderId, transaction.receiverId].map (id) ->
              User.findById(id).exec()
            RSVP.all(userPromises).then (users) ->
              resolve users
          , 250
      .then (users) ->
        new RSVP.Promise (resolve, reject) ->
          setTimeout ->
            resolve users
          , 250
      .then (users) ->
        userPromises = [users[0].id, users[1].id].map (userId) ->
          User.findById(userId).exec()
        RSVP.all userPromises
      .then (users) ->
        expect users[0].balance
          .toBe depositAmount - transactionAmount
        expect users[1].balance
          .toBe transactionAmount
        done()


  , 10000

  it 'can be created without an account', (done) ->
    depositAmount = 50
    transactionAmount = 10
    from = "oneuserasdf#{(new Date).getTime()}@somewhere.come"
    to = "anotheruserasdf#{(new Date).getTime()}@somewhere.come"
    transaction = null
    new RSVP.Promise (resolve, reject) ->
      receiver = new User
        email: to
        active: true
        transactionsAccepted: true
        activationEmailSent: true
      receiver.save (err, receiver) ->
        resolve [null, receiver]
    .then (users) ->
      new RSVP.Promise (resolve, reject) ->
        to = users[1]
        transaction = new Transaction
          amount: transactionAmount
          from: from
          to: to.email
          receiverId: to.id
          status: Transaction.STATUS.PENDING
        transaction.save (err, transaction) ->
          resolve transaction
    .then (transaction) ->
      new RSVP.Promise (resolve, reject) ->
        setTimeout ->
          User.findOne({email: from}).exec().then (user) ->
            resolve transaction
        , 500
    .then (transaction) ->
      new RSVP.Promise (resolve, reject) ->
        transaction.confirmation = 2
        transaction.acceptance = 1
        transaction.save (err, transaction) ->
          resolve transaction
    .then (transaction) ->
      RSVP.all [transaction.senderId, transaction.receiverId].map (userId) ->
        User.findById(userId).exec()
    .then (users) ->
      expect users[0].balance
        .toBe 0
      expect users[1].balance
        .toBe 0

      new RSVP.Promise (resolve, reject) ->
        deposit = new Transaction
          amount: depositAmount
          receiverId: users[0].id
          status: Transaction.STATUS.DEPOSIT
        deposit.save (err, deposit) ->
          resolve transaction

    .then (transaction) ->
      new RSVP.Promise (resolve, reject) ->
        setTimeout ->
          transaction.confirmation = Transaction.CONFIRMATION.ACCEPTED
          transaction.save (err, transaction) ->
            resolve transaction
        , 250
    .then (transaction) ->
      new RSVP.Promise (resolve, reject) ->
        setTimeout ->
          RSVP.all [transaction.senderId, transaction.receiverId].map (userId) ->
            User.findById(userId).exec()
          .then (users) ->
            resolve users
        , 250
    .then (users) ->
      expect users[0].balance
        .toBe depositAmount - transactionAmount
      expect users[1].balance
        .toBe transactionAmount

      done()
      db.connection.close()

  it 'can be sent to someone without an account when they use the same email address', (done) ->
    depositAmount = 50
    transactionAmount = 10
    from = "oneuserasdaaf#{(new Date).getTime()}@somewhere.come"
    to = "anotheruseraddsdf#{(new Date).getTime()}@somewhere.come"
    transaction = null
    new RSVP.Promise (resolve, reject) ->
      sender = new User
        email: from
        active: true
        transactionsAccepted: true
        activationEmailSent: true
      sender.save (err, sender) ->
        resolve [sender, null]
    .then (users) ->
      console.log 'made sender'
      new RSVP.Promise (resolve, reject) ->
        from = users[0]
        transaction = new Transaction
          amount: depositAmount
          receiverId: users[0].id
          status: Transaction.STATUS.DEPOSIT
        transaction.save (err, transaction) ->
          resolve users
    .then (users) ->
      console.log 'made deposit'
      new RSVP.Promise (resolve, reject) ->
        console.log 'to is', to
        from = users[0]
        transaction = new Transaction
          amount: transactionAmount
          from: from.email
          senderId: from.id
          to: to
          status: Transaction.STATUS.PENDING
        transaction.save (err, transaction) ->
          resolve transaction
    .then (transaction) ->
      console.log 'made transaction'
      new RSVP.Promise (resolve, reject) ->
        receiver = new User
          email: to
          active: true
          transactionsAccepted: true
          activationEmailSent: true
        receiver.save (err, receiver) ->
          console.log 'receiver saved!', receiver.id
          resolve receiver
    .then (receiver) ->
      new RSVP.Promise (resolve, reject) ->
        setTimeout ->
          console.log 'assigning users'
          console.log 'receiver is', receiver
          transaction.assignUsers().then (transaction) ->
            resolve transaction
        , 500
    .then (transaction) ->
      console.log 'confirming'
      new RSVP.Promise (resolve, reject) ->
        transaction.confirmation = 1
        transaction.acceptance = 1
        transaction.save (err, transaction) ->
          resolve transaction
    .then (transaction) ->
      new RSVP.Promise (resolve, reject) ->
        setTimeout ->
          userPromises = [transaction.senderId, transaction.receiverId].map (userId) ->
            User.findById(userId).exec()
          RSVP.all(userPromises).then (users) ->
            resolve users
        , 500
    .then (users) ->
      expect users[0].balance
        .toBe depositAmount - transactionAmount
      expect users[1].balance
        .toBe transactionAmount
      done()

  , 10000
