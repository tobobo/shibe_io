module.exports = (app) ->

  app.get '/', (req, res) ->
    res.write 'hello world'
    res.end()

  app.post '/incoming', (req, res, data) ->
    data = req.body
    res.write JSON.stringify
      email: data
    res.end()
