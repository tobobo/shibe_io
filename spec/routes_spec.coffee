request = require 'request'

host = 'http://127.0.0.1:8888'

describe 'router', ->


  describe 'index', ->

    it 'should have content', (done) ->

      request.get host, (error, response, body) ->

        expect response.statusCode
          .toBe 200

        expect body.length 
          .toBeGreaterThan 0

        expect response.headers['access-control-allow-origin']
          .toBe '*.shibe.io'

        done()


  describe 'inbox', ->

    it 'should respond to email content', (done) ->

      request.post host + '/incoming',
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

        expect response.headers['access-control-allow-origin']
          .toBe '*.shibe.io'

        done()
