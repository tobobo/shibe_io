mongoose = require 'mongoose'
RSVP = require '../utils/rsvp'
mailer = require '../config/mailer'

transactionSchema = require '../models/transaction'
userSchema = require '../models/user'
mandrillEvents = require '../utils/mandrill_events'

# post save hooks

transactionSchema.pre 'save', (transaction, callback) ->
  @assignUsers().then (transaction) =>
    transaction.sendEmails()
  .then (transaction) =>
    console.log 'transaction', transaction
    transaction.execute()
  .then (transaction) =>
    console.log 'transaction', transaction
    transaction.updateBalances()
  .then (transaction) =>
    console.log 'transaction', transaction
    callback null, transaction

userSchema.post 'save', (user) ->
  unless user.activationEmailSent
    user.sendActivationEmail()
  if user.active and not user.depositAddress?
    user.createDepositAddress()
  if user.active and not user.transactionsAccepted
    user.acceptTransactions()

# transaction schema methods that need users


transactionSchema.methods.assignUsers = ->
  if @usersAssigned
    RSVP.resolve @
  else
    RSVP.all [@from, @to].map (address) =>
      new RSVP.Promise (resolve, reject) ->
        if address?
          User.findOne
            email: address
          , (err, user) ->
            if user?
              resolve user
            else
              resolve undefined
        else
          resolve undefined
    .then (users) =>
      if users[0]? then @senderId = users[0].id
      if users[1]?
        @receiverId = users[1].id
        @acceptance = Transaction.ACCEPTANCE.ACCEPTED
      @usersAssigned = true
      RSVP.resolve @

transactionSchema.methods.sendEmails = ->
  if @status == Transaction.STATUS.PENDING
    senderMailData =
      from: mailer.default_from
      to: @from
      subject: "Re: #{@subject}"
      body: "You sent #{@amount} DOGE to #{@to}. To confirm this transaction, go to #{@confirmationURL()}"

    receiverMailData =
      from: mailer.default_from
      to: @to
      subject: "Re: #{@subject}"
      body: "#{@from} has sent you #{@amount} DOGE. What a joyous occasion! We'll let you know when they've confirmed the transaction."

    RSVP.all [senderMailData, receiverMailData].map (mailData) =>
      new RSVP.Promise (resolve, reject) =>
        mailer.sendMail mailData, (err, result) =>
          if err then reject err
          else resolve result
    .then (results) =>
      @status = Transaction.STATUS.ANNOUNCED
      RSVP.resolve @
    
  else
    RSVP.resolve @

transactionSchema.methods.confirmWithCredentials = (email, password) ->
  (=>
    console.log 'really confirming'
    if email == @from
      if @senderId?
        User.findById(@senderId).exec()
      else
        RSVP.resolve new User
          email: email
    else
      RSVP.reject "Cannot confirm transaction with that email."
  )().then (user) =>
    new RSVP.Promise (resolve, reject) =>
      if user.active
        user.authenticate password, (err, user) =>
          if err? then reject "Authentication error."
          else resolve user
      else
        user.setPassword password, (err, user) =>
          if err? then reject "error setting password"
          else resolve user
  .then (user) =>
    new RSVP.Promise (resolve, reject) =>
      if user.isModified()
        user.save (err, user) =>
          if err? then reject "error saving user"
          else resolve user
      else
        resolve user
  .then (user) =>
    if user.balance >= @amount
      @confirmation = Transaction.CONFIRMATION.ACCEPTED
    else
      @confirmation = Transaction.CONFIRMATION.INSUFFICIENT_FUNDS
    RSVP.resolve @

transactionSchema.methods.acceptWithCredentials = (email, password) ->
  (=>
    if email == @from
      if @receiverId?
        User.findById(@receiverId).exec()
      else
        RSVP.resolve new User
          email: email
          active: true
          activationEmailSent: true
    else
      if @receiverId?
        RSVP.reject "cannot confirm for that user"
      else
        RSVP.resolve new User
          email: email
  )().then (user) =>
    new RSVP.Promise (resolve, reject) =>
      if @receiverId?
        user.authenticate password, (err, user) =>
          if err? then reject "Authentication error."
          else resolve user
      else
        @receiverId = user.id
        if user.active
          user.setPassword password, (err, user) =>
            if err? then reject "error setting password"
            else resolve user
        else
          resolve user
  .then (user) =>
    if user.active
      @acceptance = Transaction.ACCEPTANCE.ACCEPTED
    else
      @acceptance = Transaction.ACCEPTANCE.NEEDS_EMAIL_CONFIRMATION
    new RSVP.Promise (resolve, reject) =>
      if user.isModified()
        user.save (user, err) =>
          if err? then reject "error saving user"
          else resolve @
      else
        resolve @


transactionSchema.methods.processWithCredentials = (parameters) ->
  transactionParams = undefined
  console.log 'here'
  email = parameters.userEmail.trim().toLowerCase()
  console.log 'there'
  password = parameters.userPassword
  if parameters.acceptanceCode?
    @acceptWithCredentials email, password
  else if parameters.confirmationCode?
    console.log 'confirming'
    @confirmWithCredentials email, password
  else
    RSVP.reject "no code"

transactionSchema.methods.execute = (parameters) =>
  if @acceptance == Transaction.ACCEPTANCE.ACCEPTED and @confirmation == Transaction.CONFIRMATION.ACCEPTED and @status not in [Transaction.STATUS.COMPLETE, Transaction.STATUS.DEPOSIT]
    @status = Transaction.STATUS.COMPLETE
    new RSVP.Promise (resolve, reject) =>
      sender = new User
        id: @senderId
      receiver = new User
        id: @receiverId
      RSVP.all [sender, receiver].map (user) =>
        user.updateBalance @
      .then (users) =>
        RSVP.resolve @
  else if @status == Transaction.STATUS.DEPOSIT
    RSVP.resolve @
  else
    RSVP.resolve @

transactionSchema.methods.updateBalances = (parameters) =>
  if @status == Transaction.STATUS.COMPLETE and not @executed
    users = []
    [@senderId, @receiverId].forEach (userId) =>
      if userId?
        users.push new User
          id: userId
    RSVP.all users.map (user) =>
      new RSVP.Promise (resolve, reject) =>
        user.updateBalance @
    .then (users) =>
      @executed = true
      resolve @
  else
    resolve @


# user methods that need transactions

userSchema.methods.getTransactions = ->
  console.log 'getting transactions'
  Transaction.find({$or: [{senderId: @id}, {receiverId: @id}]}).sort('-createdAt').exec()

userSchema.methods.acceptTransactions = ->
  new RSVP.Promise (resolve, reject) ->
    Transaction.find
      receiverId: @id
      acceptance: Transaction.ACCEPTANCE.NEEDS_EMAIL_CONFIRMATION
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

userSchema.methods.updateBalance = (transaction) ->
  sent = 0
  received = 0
  deposited = 0
  console.log 'updating balance'
  @getTransactions().then (transactions) =>
    console.log 'found transactions'
    if transaction?
      transactions.push transaction
    new RSVP.Promise (resolve, reject) =>
      console.log 'going', transactions
      transactions.forEach (transaction) =>
        console.log 'foreaching'
        if transaction.status == Transaction.STATUS.COMPLETE
          if transaction.receiverId == @id
            if transaction.senderId?
              received += transaction.amount
            else
              deposited += transaction.amount
          else if transaction.senderId == @id
            sent += transaction.amount
      if @received != received or @deposited != deposited or @sent != sent
        @received = received
        @deposited = deposited
        @sent = sent
        @balance = @deposited + @received - @sent
        @save (err, user) =>
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

Transaction.createFromEmail = (emails) ->
  transactionPromises = mandrillEvents.process(emails).map (transaction) ->
    new RSVP.Promise (resolve, reject) ->
      transactionModel = new Transaction transaction
      transactionModel.save (transaction, err) ->
        if err != undefined
          transaction._error = err
        resolve transaction
  RSVP.all(transactionPromises)      

# constants

constants =
  STATUS: ['PENDING', 'ANNOUNCED', 'DEPOSIT', 'COMPLETE', 'WITHDRAWAL', 'ERROR', 'EXECUTED']
  CONFIRMATION: ['PENDING', 'ACCEPTED', 'INSUFFICIENT_FUNDS']
  ACCEPTANCE: ['PENDING', 'ACCEPTED', 'NEEDS_EMAIL_CONFIRMATION']

for c, a of constants
  Transaction[c] = {}
  for i, v of a
    Transaction[c][i] = v
    Transaction[c][v] = parseInt(i) 

# exports

module.exports = 
  Transaction: Transaction
  transactionSchema: transactionSchema
  User: User
  userSchema: userSchema
