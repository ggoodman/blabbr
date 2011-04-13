module.exports = lumbar = require('./lib/lumbar')
Queue = require('./queue')


socket = new io.Socket()
socket.connect()
socket.on 'connect', ->
  
socket.on 'message', (data) ->
  switch data.event
    when 'initial'
      window.lumbar = new lumbar.Session(data)

socket.on 'disconnect', ->

socket.connect()

lumbar.sync = (method, model, options) ->
  console.log "lumbar.sync", arguments...

lumbar.Model.prototype.sync = lumbar.sync
lumbar.Collection.prototype.sync = lumbar.sync

class lumbar.Session extends lumbar.Model
  initialize: ->
    console.log "Hello world"
    
eventQueues = {}
lumbar.on = (event, cb) ->
  eventQueues = new Queue if not eventQueues[event]
  eventQueues[event].add (context) ->
    cb.call(context)