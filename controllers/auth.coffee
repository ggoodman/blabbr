app.get '/logout', (req, res) ->
  req.logout()
  req.flash('info', "Logged out")
  res.redirect 'back'


app.get '/auth/facebook', (req, res) ->
  req.authenticate ['facebook'], (err, auth) ->
    req.flash('info', "Login succeeded") if auth
    req.flash('error', "Login failed") if err
    
    res.redirect 'home' if auth or err
