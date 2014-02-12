request = require 'request'
querystring = require 'querystring'
RSVP = require 'rsvp'

doge_api_base_url = 'http://www.dogeapi.com/wow/'
doge_chain_base_url = 'https://dogechain.info/chain/Dogecoin/q/'

doge_api = {}

doge_api.requestDogeApi = (params) ->
  new RSVP.Promise (resolve, reject) ->
    unless doge_api.api_key?
      reject
    params.api_key = doge_api.api_key
    request.get
      url: doge_api_base_url
      qs: params
    , (err, response, body) ->
      body = body.toString()
      if body in ["Unauthorized Shibe", "Invalid API Key"]
        reject()
      else
        resolve body

doge_api.requestDogeChain = (query, address) ->
  new RSVP.Promise (resolve, reject) ->
    request.get "#{doge_chain_base_url}#{query}/#{address}", (err, response, body) ->
      body = body.toString()
      if body == "ERROR: address invalid"
        reject()
      else
        resolve body

doge_api.getBalance = ->
  doge_api.requestDogeApi
    a: 'get_balance'

doge_api.getNewAddress = (label) ->
  doge_api.requestDogeApi
    a: 'get_new_address'
    address_label: label

doge_api.withdraw = (amount, address) ->
  doge_api.requestDogeApi
    a: 'withdraw'
    amount: amount
    address: address

doge_api.getReceivedByAddress = (address) ->
  doge_api.requestDogeChain 'getreceivedbyaddress', address


module.exports = doge_api
