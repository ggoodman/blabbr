express = require 'express'
auth = require 'connect-auth'
app = express.createServer()
io = require 'socket.io'

fb = require("./fb_creds.js")

app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session
    secret: 'password'
  app.use auth([
    auth.Facebook({appId: fb.fbAppId, appSecret: fb.fbAppSecret, scope : "email", callback: fb.fbCallback})
  ])
  app.use express.static(__dirname + '/public')
  
app.get '/', (req, res) ->
  res.render 'index'

app.get '/auth/facebook', (req, res) ->
  req.authenticate ['facebook'], (err, auth) ->
    res.render 'login_success'

app.get '/chat', (req, res) ->
  socket.on 'connection', (client) ->
    sid = randomString(4, '0123456789')
    sid = randomString(4, '0123456789') while sid in sessions
      
    sessions[sid] = session =
      sid: sid
      name: req.getAuthDetails().name
    
    client.broadcast
      type: 'connect'
      client: session
    
    client.on 'disconnect', ->
      console.log "DISC"
      client.broadcast
        type: 'disconnect'
        client: session
      
    client.on 'message', (msg) ->
      console.log "MESG", msg
      switch msg.type
        when 'message'
          msg.client = session
          client.broadcast(msg)
          client.send(msg)
        when 'rename'
          if msg.to not in sessions
            session.name = msg.to
            sessions[session.name] = session
            msg.client = session
            
            unset sessions[msg.from]
            
            client.broadcast msg
            client.send msg


app.listen(process.env.C9_PORT or 80)
socket = io.listen(app)

randomString = (len, alphabet) ->
  alphabet = alphabet or 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  entropy = alphabet.length
  ret = ''
  while len > 0
    ret += alphabet[Math.floor(Math.random() * entropy)]
    len--
  ret


