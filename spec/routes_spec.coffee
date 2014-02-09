request = require 'request'

host = 'http://127.0.0.1:8888'

describe 'router', ->


  describe 'index', ->

    it 'should have content', (done) ->
      requestHost = 'http://www.shibe.io'
      request.get host,
        headers:
          host: requestHost
      , (error, response, body) ->

        expect response.statusCode
          .toBe 200

        expect body.length 
          .toBeGreaterThan 0

        expect response.headers['access-control-allow-origin']
          .toBe requestHost

        done()

    it 'should not return an access-control header for an incorrect domain', (done) ->
      requestHost = 'http://something.else'
      request.get host,
        headers:
          host: requestHost
      , (error, response, body) ->

        expect response.statusCode
          .toBe 200

        expect response.headers['access-control-allow-origin']
          .toBe undefined

        done()




  describe 'inbox', ->

    it 'should respond to email content', (done) ->

      request.post host + '/incoming',
        headers:
          host: 'whatever'
        form: 
          mandrill_events:
            JSON.stringify [
              ts: (new Date).getTime()
              msg:
                from_email: 'person@a.com',
                to: ['Person B <person@b.com>', 'Good Shibe <good@shibe.io>']
                subject: '200 doge'
            ]
      , (error, response, body) ->
        bodyText = body

        expect response.statusCode
          .toBe 200

        expect bodyText.length
          .toBeGreaterThan 0

        done()
