RSVP = require 'rsvp'

RSVP.resolve = (result) ->
  new RSVP.Promise (resolve) ->
    resolve result

RSVP.reject = (error) ->
  new RSVP.Promise (resolve, reject) ->
    reject error

module.exports = RSVP
