module.exports = (req, res, next) ->
  originValid = false
  for host in [/localhost:.*/, /.*\.shibe\.io/]
    if host.test req.headers.origin
      originValid = true
      break
  if originValid
    res.header 'Access-Control-Allow-Origin', req.headers.origin
    res.header 'Access-Control-Allow-Credentials', true
    res.header 'Access-Control-Allow-Methods', 'POST, GET, PUT, DELETE, OPTIONS'
    res.header 'Access-Control-Allow-Headers', 'Content-Type'
  next()
