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
  announced:
    type: Boolean
    default: false
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

  id: ->
    crypto.createHash('md5').update(Math.random().toString()).digest('hex')

for k, v of defaults
  transactionSchema.path(k).default v

transactionSchema.post 'save', (transaction) ->
  unless transaction.announced
    transaction.sendEmails()

transactionSchema.methods.sendEmails = ->
  senderMailData =
    from: mailer.default_from
    to: @from
    subject: "Re: #{@subject}"
    body: "You sent #{@amount} DOGE to #{@to}. You are so generous. Pat yourself on the back."

  receiverMailData =
    from: mailer.default_from
    to: @to
    subject: "Re: #{@subject}"
    body: "#{@from} has sent you #{@amount} DOGE. What a joyous occasion!"

  emailPromises = [senderMailData, receiverMailData].map (mailData) =>
    new RSVP.Promise (resolve, reject) =>
      mailer.sendMail mailData, (err, result) =>
        if err then reject err
        else resolve result

  RSVP.all emailPromises
  .then (emails) =>
    @announced = true
    @save()
  .catch (reason) =>
    console.log "Error sending emails for transaction #{@id}"

transactionSchema.methods.serializeToObj = ->
  id: @id
  from: @from
  to: @to
  senderId: @senderId
  receiverId: @receiverId
  amount: @amount
  announced: @announced
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

statuses = ['PENDING', 'COMPLETE', 'DEPOSIT']
Transaction.STATUS = {}
for i, v of statuses
  Transaction.STATUS[i] = v
  Transaction.STATUS[v] = i 

module.exports = mongoose.model 'Transaction', transactionSchema
