request = require 'request'
mongoose = require 'mongoose'
User = require '../models/user'

host = 'http://127.0.0.1:8888'

time = (new Date).getTime()

describe 'router', ->

  describe 'index', ->

    it 'should have content', (done) ->
      requestHost = 'http://www.shibe.io'
      request.get host,
        headers:
          origin: requestHost
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
          origin: requestHost
      , (error, response, body) ->

        expect response.statusCode
          .toBe 200

        expect response.headers['access-control-allow-origin']
          .toBe undefined

        done()




  describe 'inbox', ->

    it 'should respond to email content', (done) ->
      from = 'person@a.com'
      to = 'person@b.com'
      amount = 200
      subject = "#{amount} doge"
      events = [
        ts: (new Date).getTime()
        msg:
          from_email: from,
          to: [["Person B <#{to}>", null], ['Good Shibe <good@shibe.io>', null]]
          subject: subject
      ]

      request.post host + '/incoming',
        form: 
          mandrill_events: JSON.stringify events
      , (error, response, body) ->

        expect response.statusCode
          .toBe 200
        bodyObj = JSON.parse body
        expect bodyObj.transactions[0].from
          .toBe from
        expect bodyObj.transactions[0].to
          .toBe to
        expect bodyObj.transactions[0].amount
          .toBe amount
        expect bodyObj.transactions[0].subject
          .toBe subject
        expect body.length
          .toBeGreaterThan 0

        done()

  describe 'users', ->

    newUserId = null

    userData = 
      email: "#{time}fdsfd@something.com"
    password = 'somepass'

    describe 'new', ->

      it 'should create a new user', (done) ->

        request.post host + '/users/new',
          form: userData
        , (error, response, body) ->
          expect response.statusCode
            .toBe 200

          newUserid = JSON.parse(body).user._id

          expect body.length
            .toBeGreaterThan 0

          done()

    describe 'activate', ->

      it 'should not activate an inactive user without a token', (done) ->
        request.post host + '/users/activate',
          form:
            email: userData.email
            password: password
        , (error, response, body) ->
          expect response.statusCode
            .toBe 422
          done()

      it 'should not activate an inactive user without a password', (done) ->
        User.find
          email: userData.email
        , (err, user) ->
          request.post host + '/users/activate',
            form:
              email: userData.email
              activationToken: user[0].activationToken
          , (error, response, body) ->
            expect response.statusCode
              .toBe 422
            done()

      it 'should activate an inactive user', (done) ->
        User.find
          email: userData.email
        , (err, user) ->
          request.post host + '/users/activate',
            form:
              email: userData.email
              password: password
              activationToken: user[0].activationToken
          , (error, response, body) ->
            expect response.statusCode
              .toBe 200
            expect JSON.parse(body).user.active
              .toBe true
            done()

    describe 'login', ->

      it 'should log a registered user in', (done) ->
        request.post host + '/users/login',
          form:
            email: userData.email
            password: password
        , (error, response, body) ->
          expect response.statusCode
            .toBe 200

          expect body.length
            .toBeGreaterThan 0

          done()
