express = require 'express'
app = express.createServer()
io = require 'socket.io'

app.configure ->
  app.use express.static(__dirname + '/public')

app.get '/', (req, res) ->
  res.send 'hello world'

app.listen process.env.C9_PORT

socket = io.listen(app)

chatters = {}

randomString = (bits) ->
  chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  ret = ''
  while bits > 0
    rand = Math.floor(Math.random() * 0x100000000)
    `for (i = 24; i > 0 && bits > 0; i -= 6, bits -= 6) ret += chars[0x3F & rand >>> i]`
  return ret

class Chatter
  constructor: (@client) ->
    @name = ('Blabberer' + randomString(32)) while @name not in chatters
    
    @client.on 'message', @handleMessage
    
    msg = 
      u: @name
      t: 'connection'
      body: ''

    @client.broadcast msg
    @client.send msg
    
  handleMessage: (msg) =>
    console.log msg
    @client.broadcast msg

socket.on 'connection', (client) ->
  chatter = new Chatter(client)
  chatters[chatter.name] = chatter
  
  client.on 'disconnection', ->
    delete chatters[chatter.name]
  