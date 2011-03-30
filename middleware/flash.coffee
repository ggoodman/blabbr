module.exports = (req, res, next) ->
  res.local 'piqFlash', req.flash()
  next()