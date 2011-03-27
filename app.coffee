express = require 'express'
app = express.createServer()
io = require 'socket.io'

app.configure ->
  app.use express.static(__dirname + '/public')

app.get '/', (req, res) ->
  res.send 'hello world'

app.listen(process.env.C9_PORT or 80)

socket = io.listen(app)

sessions = {}

randomString = (len, alphabet) ->
  alphabet = alphabet or 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  entropy = alphabet.length
  ret = ''
  while len > 0
    ret += alphabet[Math.floor(Math.random() * entropy)]
    len--
  ret

socket.on 'connection', (client) ->
  sid = randomString(4, '0123456789')
  sid = randomString(4, '0123456789') while sid in sessions
    
  sessions[sid] = session =
    sid: sid
    name: 'Blabber' + sid
  
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

