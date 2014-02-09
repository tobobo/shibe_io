mandrill_events = require('../mandrill_events')

describe 'mandrill events module', ->


  describe 'getRecipients', ->

    it 'should filter out an email from shibe.io', ->

      input = ['Someone <someone@person.com>', 'Good shibe <good@shibe.io>', 'Another person <someone@else.com>']

      recipients = mandrill_events.getRecipients input

      expect recipients
        .toEqual ['someone@person.com', 'someone@else.com']


  describe 'getValue', ->

    it 'should get the value from a subject line', ->

      value = mandrill_events.getValue '500.23333 doge for being a good friend'

      expect value
        .toBe 500.23333


  describe 'process', ->

    it 'should transform mandrill event data into transaction data', ->

      # write it tomorrow!
      
