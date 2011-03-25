express = require 'express'
app = express.createServer()
io = require 'socket.io'

app.configure ->
  app.use express.static(__dirname + '/public')

app.get '/', (req, res) ->
  res.send 'hello world'

app.listen process.env.C9_PORT

socket = io.listen(app)

socket.on 'connect', ->
  console.log "Socket connected", arguments...