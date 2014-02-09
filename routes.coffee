module.exports = (app) ->

  app.get '/', (req, res) ->
    res.write 'hello world'
    res.end()

  app.post '/incoming', (req, res, data) ->
    data = req.body
    stringData = JSON.stringify
      email: data

    for k, v of data
      console.log "#{k} ---", v
    res.write stringData
    res.end()
