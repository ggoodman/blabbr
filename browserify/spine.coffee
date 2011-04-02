###
class Spine
  queue: new Queue
  client: null
  constructor: (server) ->
    @dnode = dnode(@_server)
    
    @dnode.use(server) if server
    
    console.log "Dnode server started"
    @send "Sending message from the past"
  
  _server: (@client, @conn) =>
    @queue.flush(@client)
    return
  
  listen: (app) ->
    @dnode.listen(app)
    return this
  
  send: ->
    args = arguments
    @queue.add (client) =>
      client.notify(args...)
    return this

module.exports.spine = (app) ->
  spine = new Spine(app)
###