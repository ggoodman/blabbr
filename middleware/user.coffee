module.exports = (req, res, next) ->
  res.local 'piqAuth', req.getAuthDetails().user || null
  next()