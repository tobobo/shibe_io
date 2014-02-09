module.exports = (app) ->

  app.get '/', (req, res) ->
    res.write 'hello world'
    res.end()

  app.post '/incoming', (req, res, data) ->
    data = req.body
    stringData = JSON.stringify
      email: data

    events = JSON.parse data.mandrill_events
    for e in events
      console.log 'EVENT!!! -----'
      for k, v of e
        console.log "#{k} ---- v"
    res.write stringData
    res.end()
