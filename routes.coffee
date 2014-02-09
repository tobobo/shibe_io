module.exports = (app) ->

  app.get '/', (req, res) ->
    res.write 'hello world'
    res.end()

  app.post '/incoming', (req, res, data) ->
    data = req.body
    stringData = JSON.stringify
      email: data

    for e in data.mandrill_events
      console.log 'EVENT!!! ------'
      for k, v in e
        console.log "#{k} ---", v
    res.write stringData
    res.end()
