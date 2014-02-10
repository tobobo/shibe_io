User = require '../models/user'
mongoose = require 'mongoose'
mongoose.connect process.env.SHIBE_DB_URL

mongoose.connection.on 'open', ->

  describe 'user', ->

    it 'can be created', (done) ->
      userData =
        email: "#{(new Date).getTime()}ffdsss@something.com"
      password = 'something'

      User.register userData, password, (err, user) ->

        expect user.email
          .toBe userData.email
        expect user._id
          .not.toBe null

        done()


    it 'cannot be created in duplicate', (done) ->
      userData =
        email: "#{(new Date).getTime()}ffdsss@something.com"
      password = 'something'

      User.register userData, password, (err, user) ->
        expect user.email
          .toBe userData.email
        expect user._id
          .not.toBe null

        User.register userData, password, (err, user) ->
          expect err
            .not.toBe null

          expect user
            .toBe undefined

          done()

          mongoose.connection.close()

