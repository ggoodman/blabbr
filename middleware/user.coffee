redis = require('redis')
client = redis.createClient()
querystring = require('querystring')
crypto = require('crypto')
https = require('https')

fb = require('../fb_creds')

fb.parseCookie = (fb_cookie) ->
  return null if not fb_cookie?
  
  hash = querystring.parse(fb_cookie)
  payload = ''
  
  for key, value of hash
    payload += "#{key}=#{value}" if key is not 'sig'
    
  return null if hash.sig is not crypto.createHash('MD5').update(payload + fb.secret).digest('hex')  
  return hash
  

module.exports = (req, res, next) ->
  fb_cookie = fb.parseCookie(req.cookies['fbs_' + fb.id])
  
  req.live = require('live')
  
  if fb_cookie
    if not req.session.currentUser
      options =
        host: "graph.facebook.com"
        path: "/me?access_token=#{fb_cookie.access_token}"
      
      subreq = https.get options, (subres) ->
        subres.on 'data', (data) ->
          user = JSON.parse(data.toString())
          req.session.currentUserId = user.id
          req.session.currentUser = user

          return next()
        subres.on 'error', (error) ->
          return next()
    else return next()
  else
    return next()