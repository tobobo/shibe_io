origin_middleware = require '../utils/origin_middleware.coffee'

describe 'origin middleware', ->

  next = ->

  it 'allows subdomains of shibe.io', ->
    origin = 'http://www.shibe.io'

    req = 
      headers:
        origin: origin

    originHeader = null

    res =
      header: (key, val) ->
        if key == 'Access-Control-Allow-Origin'
          originHeader = val

    origin_middleware req, res, next

    expect originHeader
      .toBe origin

  it 'allows localhost', ->
    origin = 'localhost:1234'

    req = 
      headers:
        origin: origin

    originHeader = null

    res =
      header: (key, val) ->
        if key == 'Access-Control-Allow-Origin'
          originHeader = val

    origin_middleware req, res, next

    expect originHeader
      .toBe origin


  it 'denies others', ->
    origin = 'arbitrary.url'

    req = 
      headers:
        origin: origin

    originHeader = undefined

    res =
      header: (key, val) ->
        if key == 'Access-Control-Allow-Origin'
          originHeader = val

    origin_middleware req, res, next

    expect originHeader
      .toBe undefined


