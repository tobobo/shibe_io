User = require '../models/user'

module.exports =
  new: (req, res, data) ->
    user = new User
      email: req.body.email
    user.save (err, user) ->
      if err?
        res.statusCode = 422
        if req.body.email?
          email = req.body.email.trim().toLowerCase()
        else
          email = null
        User.find
          email: email
        , (err, users) ->
          if users.length > 0
            res.write users[0].serialize
              error: 'Registration error'
          else
            res.write JSON.stringify
              meta:
                error: 'Registration error'
          res.end()
      else
        res.write user.serialize
          meta:
            success: 'User created with activation token.'

        res.end()


  activate: (req, res, data) ->
    User.find
      email: req.body.email
      activationToken: req.body.activationToken
      active: false
    , (error, users) ->
      if users.length > 0
        users[0].setPassword req.body.password, (err, user) ->
          if err?
            res.statusCode = 422
            res.write JSON.stringify
              meta:
                error: err
            res.end()
          else
            req.logIn user, res, (err) ->
              user.active = true
              user.activationEmailSent = true
              user.lastSignIn = new Date
              user.save()
              user.save (err, user) ->
                res.write user.serialize
                  meta:
                    success: 'Account activated'
                res.end()

      else
        res.statusCode = 422
        res.write JSON.stringify
          meta:
            error: 'Account error'
        res.end()


  login: (req, res) ->
    User.authenticate() req.body.email, req.body.password, (err, user) ->
      if err?
        meta =
          error: 'Invalid login'
      else
        meta = 
          success: 'Authenticated'

      req.logIn user, res, (err) ->
        res.write user.serialize(meta)
        res.end()
        user.lastSignIn = new Date
        user.save()

  logout: (req, res) ->
    req.logOut res
    res.end()

