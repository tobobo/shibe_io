origin_middleware = require '../utils/origin_middleware.coffee'

describe 'origin middleware', ->

  next = ->

  it 'allows subdomains of shibe.io', ->
    host = 'http://www.shibe.io'

    req = 
      headers:
        host: host

    originHeader = null

    res =
      header: (key, val) ->
        if key == 'Access-Control-Allow-Origin'
          originHeader = val

    origin_middleware req, res, next

    expect originHeader
      .toBe host

  it 'allows localhost', ->
    host = 'localhost:1234'

    req = 
      headers:
        host: host

    originHeader = null

    res =
      header: (key, val) ->
        if key == 'Access-Control-Allow-Origin'
          originHeader = val

    origin_middleware req, res, next

    expect originHeader
      .toBe host


  it 'denies others', ->
    host = 'arbitrary.url'

    req = 
      headers:
        host: host

    originHeader = undefined

    res =
      header: (key, val) ->
        if key == 'Access-Control-Allow-Origin'
          originHeader = val

    origin_middleware req, res, next

    expect originHeader
      .toBe undefined


