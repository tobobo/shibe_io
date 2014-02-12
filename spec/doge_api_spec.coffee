doge_api = require '../config/doge_api'

api_key = doge_api.api_key

describe 'doge_api', ->
  it 'gets a balance', (done) ->
    doge_api.getBalance().then (result) ->
      expect true
      done()
    , (error) ->
      expect false
      done()
  , 10000

  it 'gets amount received by address', (done) ->
    doge_api.getReceivedByAddress('DFNb5jMMXBWPgKzgtB6nEztTkp9YTUGN1w').then (result) ->
      expect true
      done()
    , (error) ->
      expect false
      done()

  it 'cannot get amount received for a bad address', (done) ->
    doge_api.getReceivedByAddress('asdf').then (result) ->
      expect false
      done()
    , (error) ->
      expect true
      done()

  it 'cannot get a balance without an api key', (done) ->
    doge_api.api_key = undefined
    doge_api.getBalance().then (result) ->
      expect false
      done()
    , (error) ->
      expect true
      done()

    doge_api.api_key = api_key

  it 'cannot get a balance with a bad api key', (done) ->
    doge_api.api_key = 'asdf'
    doge_api.getBalance().then (result) ->
      expect false
      done()
    , (error) ->
      expect true
      done()

    doge_api.api_key = api_key

  address_label = "test_addr#{Math.floor(Math.random()*10000000)}"

  it 'makes a new address', (done) ->
    doge_api.getNewAddress address_label
    .then (result) ->
      expect true
      done()
    , (error) ->
      expect false
      done()

