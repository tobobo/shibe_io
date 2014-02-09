module.exports = (app) ->

  app.get '/', (req, res) ->
    res.write 'hello world'
    res.end()
