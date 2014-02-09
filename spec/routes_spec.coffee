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

        done()


  describe 'inbox', ->

    it 'should respond to email content', (done) ->

      request.post host + '/incoming',
        form: 
          from: 'person@a.com'
          to: ['person@b.com', 'good@shibe.io']
          subject: '200 doge'
      , (error, response, body) ->
        bodyText = body
        body = JSON.parse body
        expect response.statusCode
          .toBe 200

        expect bodyText.length
          .toBeGreaterThan 0


        done()
