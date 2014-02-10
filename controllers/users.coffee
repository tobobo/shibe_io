User = require '../models/user'

module.exports =
  new: (req, res, data) ->

    User.register 
      email: req.body.email
    , req.body.password, (err, user) ->
      if err
        meta = 
          error: err
      else
        meta =
          success: 'user created'
      
      res.write user.serialize
        meta: meta
    
      res.end()

  login: (req, res) ->
    User.authenticate() req.body.email, req.body.password, (err, user) ->
      if err?
        meta =
          error: 'Invalid login'
      else
        meta = 
          success: 'Authenticated'

      res.write user.serialize(meta)
      res.end()
