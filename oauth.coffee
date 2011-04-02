express = require('express')
oauth = require('oauth')
fb = require('./fb_creds')

app = express.createServer()

app.configure ->
 app.use express.logger({ format: ':date :remote-addr :method :status :url' })

app.get '/', (req, res) ->
  res.redirect '/auth/facebook'

app.get '/auth/facebook', (req, res) ->
  options =
    redirect_uri: 'http://codenimbus.org/auth/facebook_callback'
  
  oauth = new oauth.OAuth2(fb.id, fb.secret, "https://graph.facebook.com")
  oauth.getOAuthAccessToken 'http://codenimbus.org', options, (err, access_token, refresh_token) ->
    console.log "getOAuthAccessToken", arguments...
  
app.get '/auth/facebook_callback', (req, res) ->


app.listen 80