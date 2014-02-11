mongoose = require 'mongoose'
crypto = require 'crypto'
mailer = require '../config/mailer'
RSVP = require 'rsvp'

transactionSchema = new mongoose.Schema
  _id: String
  amount:
    type: Number
    required: true
  createdAt: Date
  senderId: String
  receiverId: String
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

  _id: ->
    crypto.createHash('md5').update(Math.random().toString()).digest('hex')

for k, v of defaults
  transactionSchema.path(k).default v

transactionSchema.post 'save', (transaction) ->
  unless transaction.announced
    transaction.sendEmails()

transactionSchema.methods.sendEmails = ->
  senderMailData =
    from: mailer.default_from
    to: this.from
    subject: "You sent #{this.amount} DOGE to #{@from}"
    body: "You are so generous. Pat yourself on the back."

  receiverMailData =
    from: mailer.default_from
    to: @to
    subject: "#{@to} has sent you #{@amount} DOGE"
    body: "What a joyous occasion!"

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
    console.log "Error sending emails for transaction #{@_id}"

transactionSchema.methods.serializeToObj = ->
  _id: @_id
  from: @from
  to: @to
  senderId: @senderId
  receiverId: @receiverId
  amount: @amount
  announced: @announced
  createdAt: @createdAt

transactionSchema.methods.serialize = (meta) ->
  JSON.stringify
    transaction: @serializeToObj
    meta: meta

Transaction = mongoose.model 'Transaction', transactionSchema

Transaction.serialize = (transactions, meta) ->
  JSON.stringify
    transactions: transactions.map (transaction) -> transaction.serializeToObj()
    meta: meta

module.exports = mongoose.model 'Transaction', transactionSchema
