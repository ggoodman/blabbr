redis = require('redis')
client = redis.createClient()
querystring = require('querystring')
crypto = require('crypto')
https = require('https')
uuid = require('node-uuid')

fb = require('../fb_creds')

fb.parseCookie = (fb_cookie) ->
  return null if not fb_cookie?
  
  hash = querystring.parse(fb_cookie)
  payload = ''
  
  for key, value of hash
    payload += "#{key}=#{value}" if key is not 'sig'
    
  return null if hash.sig is not crypto.createHash('MD5').update(payload + fb.secret).digest('hex')  
  return hash

fb.fetchUserData = (fb_cookie, success, failure) ->
  options =
    host: "graph.facebook.com"
    path: "/me?access_token=#{fb_cookie.access_token}"
  
  subreq = https.get options, (subres) ->
    subres.on 'data', (data) ->
      user = JSON.parse(data.toString())
      success(user)
    subres.on 'error', (error) ->
      failure()
 

module.exports = (req, res, next) ->
  fb_cookie = fb.parseCookie(req.cookies['fbs_' + fb.id])
  
  handleFirstLogin = (user) ->
    console.log "handleFirstLogin", arguments...
    uid = uuid()
    
    client.multi()
      .set(uid, user)
      .set("oauth:v1:facebook:#{user.id}", uid)
      .exec (err, replies) ->
        console.log "[E] REDIS", arguments... if err
        req.session.currentUser = user
        res.redirect 'first_login'
  
  handleLogin = (user) ->
    client.get "oauth:v1:facebook:#{user.id}", (err, uuid) ->
      if err then throw "[E] REDIS ERROR"
      else if uuid then next()
      else handleFirstLogin(user)
   
  handleLoginFailure = ->
    console.log "handleLoginFailure", arguments...
    next()
  
  if fb_cookie
    if req.session.currentUser then next()
    else fb.fetchUserData(fb_cookie, handleLogin, handleLoginFailure)
  else
    next()