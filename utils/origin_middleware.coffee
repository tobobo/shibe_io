module.exports = (req, res, next) ->
  originValid = false
  for host in [/localhost:.*/, /.*\.shibe\.io/]
    if host.test req.headers.host
      originValid = true
      break
  if originValid
    res.header 'Access-Control-Allow-Origin', req.headers.host
    
  next()
