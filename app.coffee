express = require('express')
app = module.exports = express.createServer()

connect = require('connect')
auth = require('connect-auth')
stylus = require('stylus')

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
  app.use express.logger({ format: ':date :remote-addr :method :status :url' })
  app.use auth([
    auth.Facebook({appId: fb.fbAppId, appSecret: fb.fbAppSecret, scope : "email", callback: fb.fbCallback})
  ])
  app.use require('./middleware/user')
  app.use require('./middleware/flash')
  app.use stylus.middleware({ src: __dirname + '/public' })
  app.use express.static(__dirname + '/public')
  app.use(express.errorHandler())
  
app.get '/', (req, res) ->
  res.local 'flash', req.flash()
  res.render 'index'


app.get '/user/first_login', (req, res) ->
  req.session.user = req.getAuthDetails().user
  res.local 'name', req.session.user.name
  res.render 'first_login'

app.post '/user/first_login', (req, res) ->
  req.session.user.name = req.param('username')
  res.redirect '/chat'
  
app.get '/chat', (req, res) ->
  res.render 'chat'
  socket.on 'connection', (client) ->
    
    session = req.session.user
    
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

socket = io.listen(app)