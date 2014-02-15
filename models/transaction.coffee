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
  acceptanceCode: String
  acceptanceCodeCreatedAt: Date
  usersAssigned:
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
  acceptance:
    type: Number
    default: 0
  confirmation:
    type: Number
    default: 0

defaults = 
  createdAt: ->
    new Date

  confirmationCodeCreatedAt: ->
    new Date

  confirmationCode: ->
    crypto.createHash('md5').update(Math.random().toString()).digest('hex')

  acceptanceCodeCreatedAt: ->
    new Date

  acceptanceCode: ->
    crypto.createHash('md5').update(Math.random().toString()).digest('hex')

  id: ->
    crypto.createHash('md5').update(Math.random().toString()).digest('hex')

for k, v of defaults
  transactionSchema.path(k).default v

transactionSchema.methods.confirmationURL = ->
  "#{process.env.SHIBE_FRONTEND_URL}/confirm/#{@confirmationCode}"

transactionSchema.methods.serializeToObj = (additionalFields) ->
  object = 
    id: @id
    from: @from
    to: @to
    senderId: @senderId
    receiverId: @receiverId
    amount: @amount
    createdAt: @createdAt
    subject: @subject
    status: @status
    confirmation: @confirmation
    acceptance: @acceptance
  if additionalFields? then for field in additionalFields
    object[field] = @[field]

  object


transactionSchema.methods.serialize = (meta, additionalFields) ->
  JSON.stringify
    transaction: @serializeToObj additionalFields
    meta: meta

module.exports = transactionSchema
