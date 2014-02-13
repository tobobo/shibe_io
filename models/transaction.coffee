mongoose = require 'mongoose'
crypto = require 'crypto'
mailer = require '../config/mailer'
RSVP = require 'rsvp'

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

  id: ->
    crypto.createHash('md5').update(Math.random().toString()).digest('hex')

for k, v of defaults
  transactionSchema.path(k).default v

transactionSchema.post 'save', (transaction) ->
  if transaction.status == Transaction.STATUS.PENDING
    transaction.sendEmails()

transactionSchema.methods.confirmationURL = ->
  "#{process.env.SHIBE_FRONTEND_URL}/confirm/#{@confirmationCode}"

transactionSchema.methods.sendEmails = ->
  if @status == Transaction.STATUS.PENDING and @from? and @to?
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

    emailPromises = [senderMailData, receiverMailData].map (mailData) =>
      new RSVP.Promise (resolve, reject) =>
        mailer.sendMail mailData, (err, result) =>
          if err then reject err
          else resolve result

    RSVP.all emailPromises
    .then (emails) =>
      new RSVP.Promise (resolve, reject) =>
        @status = Transaction.STATUS.ANNOUNCED
        @save (err, transaction) =>
          resolve transaction
    .catch (reason) =>
      console.log "Error sending emails for transaction #{@id}"

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
