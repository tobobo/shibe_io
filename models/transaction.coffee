mongoose = require 'mongoose'
crypto = require 'crypto'
mailer = require '../config/mailer'
RSVP = require 'rsvp'
User = require '../models/user'

transactionSchema = new mongoose.Schema
  id: String
  amount:
    type: Number
    required: true
  createdAt: Date
  senderId: String
  receiverId: String
  subject: String
  confirmationCode: String
  confirmationCodeCreatedAt: Date
  receptionCode: String
  receptionCodeCreatedAt: Date
  from: 
    type: String
    trim: true
    lowercase: true
  to: 
    type: String
    trim: true
    lowercase: true
  status:
    type: Number
    default: 0

defaults = 
  createdAt: ->
    new Date

  confirmationCodeCreatedAt: ->
    new Date

  confirmationCode: ->
    crypto.createHash('md5').update(Math.random().toString()).digest('hex')

  receptionCodeCreatedAt: ->
    new Date

  receptionCode: ->
    crypto.createHash('md5').update(Math.random().toString()).digest('hex')

  id: ->
    crypto.createHash('md5').update(Math.random().toString()).digest('hex')

for k, v of defaults
  transactionSchema.path(k).default v

transactionSchema.post 'save', (transaction) ->
  status = parseInt(transaction.status)
  pending = parseInt(Transaction.STATUS.PENDING)
  if status == pending and transaction.from? and transaction.to? and not transaction.senderId? or not transaction.receiverId?
    transaction.assignUsers().then (transaction) =>
      transaction.sendEmails()

transactionSchema.methods.confirmationURL = ->
  "#{process.env.SHIBE_FRONTEND_URL}/confirm/#{@confirmationCode}"

transactionSchema.methods.assignUsers = ->
  userPromises = [@from, @to].map (address) =>
    new RSVP.Promise (resolve, reject) =>
      User.find
        email: address
      , (err, users) =>
        if users.length? and users[0]?
          resolve users[0]
        else
          user = new User
            email: address
          user.save (err, user) =>
            resolve user

  RSVP.all(userPromises).then (users) =>
    new RSVP.Promise (resolve, reject) =>
      @senderId = users[0].id
      @receiverId = users[1].id
      @save (err, transaction) ->

        resolve transaction

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

transactionSchema.methods.serializeToObj = ->
  id: @id
  from: @from
  to: @to
  senderId: @senderId
  receiverId: @receiverId
  amount: @amount
  createdAt: @createdAt
  subject: @subject
  status: @status

transactionSchema.methods.serialize = (meta) ->
  JSON.stringify
    transaction: @serializeToObj
    meta: meta

Transaction = mongoose.model 'Transaction', transactionSchema

Transaction.serialize = (transactions, meta) ->
  JSON.stringify
    transactions: transactions.map (transaction) -> transaction.serializeToObj()
    meta: meta

statuses = ['PENDING', 'ANNOUNCED', 'CONFIRMED', 'COMPLETE', 'DEPOSIT']
Transaction.STATUS = {}
for i, v of statuses
  Transaction.STATUS[i] = v
  Transaction.STATUS[v] = i 

module.exports = mongoose.model 'Transaction', transactionSchema
