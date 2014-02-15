mongoose = require 'mongoose'
RSVP = require 'rsvp'

transactionSchema = require '../models/transaction'
userSchema = require '../models/user'

# post save hooks

transactionSchema.post 'save', (transaction) ->
  status = parseInt(transaction.status)
  pending = parseInt(Transaction.STATUS.PENDING)
  if status == pending and transaction.from? and transaction.to? and not transaction.usersAssigned
    transaction.assignUsers().then (transaction) =>
      transaction.sendEmails()
  transaction.process()

userSchema.post 'save', (user) ->
  unless user.activationEmailSent
    user.sendActivationEmail()
  if user.active and not user.depositAddress?
    user.createDepositAddress()
  if user.active and not user.transactionsAccepted
    user.acceptTransactions()

# transaction schema methods that need users

transactionSchema.methods.assignUsers = ->
  userPromises = [@from, @to].map (address) =>
    new RSVP.Promise (resolve, reject) =>
      User.find
        email: address
      , (err, users) =>
        resolve users[0]

  RSVP.all(userPromises).then (users) =>
    new RSVP.Promise (resolve, reject) =>
      if users[0]?
        resolve users
      else
        console.log 'creating new sender user'
        sender = new User
          email: @from
        sender.save (err, sender) =>
          console.log 'created new sender user'
          users[0] = sender
          resolve users
  .then (users) =>
    new RSVP.Promise (resolve, reject) =>
      @senderId = users[0].id if users[0]?
      @receiverId = users[1].id if users[1]?
      @usersAssigned = true
      @save (err, transaction) ->
        resolve transaction

transactionSchema.methods.process = ->
  if (parseInt(@status) not in [parseInt(Transaction.STATUS.COMPLETE), parseInt(Transaction.STATUS.DEPOSIT)]) and parseInt(@confirmation) == parseInt(Transaction.CONFIRMATION.ACCEPTED) and parseInt(@acceptance) == parseInt(Transaction.ACCEPTANCE.ACCEPTED)
    console.log 'marking transaction as complete'
    @status = Transaction.STATUS.COMPLETE

    new RSVP.Promise (resolve, reject) =>
      @save (err, transaction) =>
        console.log 'transaction complete'
        resolve transaction
    .then (transaction) =>
      userPromises = [transaction.senderId, transaction.receiverId].map (userId) =>
        User.findOne
          _id: userId
        .exec().then (user) =>
          console.log "updating balance for #{user._id}"
          console.log 'updating user'
          user.updateBalance()

      RSVP.all(userPromises)
    .then (users) =>
      new RSVP.Promise (resolve, reject) =>
        @save (err, transaction) =>
          console.log 'transaction complete'
          resolve transaction
    .catch (reason) =>
      RSVP.reject reason

transactionSchema.methods.sendEmails = ->
  status = parseInt @status
  pending = parseInt Transaction.STATUS.PENDING
  if status == pending and @senderId? and @receiverId?
    console.log 'has stuff'
    userPromises = [@senderId, @receiverId].map (userId) ->
      new RSVP.Promise (resolve, reject) ->
        User.find
          _id: userId
        , (err, users) ->
          console.log users
          resolve users[0]

    RSVP.all(userPromises).then (users) =>
      sender = users[0]
      receiver = users[1]

      console.log sender.email, receiver.email

      senderMailData =
        from: mailer.default_from
        to: sender.email
        subject: "Re: #{@subject}"
        body: "You sent #{@amount} DOGE to #{receiver.email}. To confirm this transaction, go to #{@confirmationURL()}"

      receiverMailData =
        from: mailer.default_from
        to: receiver.email
        subject: "Re: #{@subject}"
        body: "#{sender.email} has sent you #{@amount} DOGE. What a joyous occasion! We'll let you know when they've confirmed the transaction."

      emailPromises = [senderMailData, receiverMailData].map (mailData) =>
        new RSVP.Promise (resolve, reject) =>
          mailer.sendMail mailData, (err, result) =>
            if err then reject err
            else resolve result

      RSVP.all(emailPromises).then (emails) =>
        new RSVP.Promise (resolve, reject) =>
          @status = Transaction.STATUS.ANNOUNCED
          @save (err, transaction) =>
            resolve transaction
      .catch (reason) =>
        console.log "Error sending emails for transaction #{@id}"
        console.log "reason:", reason


# user methods that need transactions

userSchema.methods.getTransactions = ->
  Transaction.find({$or: [{senderId: @id}, {receiverId: @id}]}).exec()

userSchema.methods.acceptTransactions = ->
  new RSVP.Promise (resolve, reject) ->
    Transaction.find
      receiverId: @id
      acceptance: Transaction.ACCEPTANCE.PENDING
    , (err, transactions) ->
      resolve transactions
  .then (transactions) =>
    if transactions.length > 0
      transactionPromises = transactions.map (transaction) ->
        new RSVP.Promise (resolve, reject) ->
          transaction.acceptance = Transaction.ACCEPTANCE.ACCEPTED
          transaction.save (err, transaction) ->
            resolve transaction
      RSVP.all transactionPromises
    else
      RSVP.resolve transactions
  .then (transactions) =>
    new RSVP.Promise (resolve, reject) =>
      @transactionsAccepted = true
      @save (err, user) ->
        resolve transactions

userSchema.methods.updateBalance = ->
  console.log "updating balance for @id"
  sent = 0
  received = 0
  deposited = 0
  @getTransactions().then (transactions) =>
    console.log 'gotten transactions'
    console.log 'transactions length', transactions.length
    new RSVP.Promise (resolve, reject) =>
      transactions.forEach (transaction) =>
        console.log 'divvying transaction', transaction.receiverId == @id, parseInt(transaction.status) == parseInt(Transaction.STATUS.DEPOSIT), 
        if transaction.receiverId == @id
          received += transaction.amount
          console.log 'added to received'
        else if parseInt(transaction.status) == parseInt(Transaction.STATUS.DEPOSIT)
          deposited += transaction.amount
          console.log 'added to deposit'
        else if transaction.senderId == @id
          console.log 'added to sent'
          sent += transaction.amount
      console.log 'got values'
      if @received != received or @deposited != deposited or @sent != sent
        @received = received
        @deposited = deposited
        @sent = sent
        @balance = @deposited + @received - @sent
        console.log @balance, @deposited, @received, @sent
        @save (err, user) =>
          console.log 'saved user'
          resolve user
      else
        resolve @

# Models

Transaction = mongoose.model 'Transaction', transactionSchema
User = mongoose.model 'User', userSchema

# serialization class functions

Transaction.serialize = (transactions, meta, additionalFields) ->
  JSON.stringify
    transactions: transactions.map (transaction) -> transaction.serializeToObj(additionalFields)
    meta: meta

# constants

constants =
  STATUS: ['PENDING', 'ANNOUNCED', 'DEPOSIT', 'COMPLETE']
  CONFIRMATION: ['PENDING', 'ACCEPTED', 'INSUFFICIENT_FUNDS']
  ACCEPTANCE: ['PENDING', 'ACCEPTED']

for c, a of constants
  Transaction[c] = {}
  for i, v of a
    Transaction[c][i] = v
    Transaction[c][v] = i 

# exports

module.exports = 
  Transaction: Transaction
  transactionSchema: transactionSchema
  User: User
  userSchema: userSchema
