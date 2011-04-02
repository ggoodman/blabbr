Queue = require('./queue')
parseCookie = require('./parseCookie')
uuid = require('node-uuid')

class Session
  constructor: (@everyone, @sid) ->
    @connectQueue = new Queue
    @methods = {}
    @now = null
  
  flush: (@now, @everyone) ->
    console.log "Server.flush", arguments...
    @connectQueue.flush(@now, @everyone)
    return this
  
  expose: (options) ->
    @methods[name] = fn for name, fn of options
    console.log "Methods", @methods
    return this
  
  send: (name, args...) ->
    @connectQueue.add (now) =>
      console.log "Server.private", now, name, typeof method
      now.callClient name, args...
      #@methods[name].apply(now, args) if @method[name]?
      return
    return this
  
  broadcast: (name, args...) ->
    @connectQueue.add (now, everyone) =>
      console.log "Server.public", now, name, typeof method
      @everyone.now.callClient name, args...
      return
    return this
  
  handleCall: (method, args...) ->
    @methods[method].apply(this, args) if @methods[method]
    
    return this
    
class Server
  constructor: (@everyone) ->
    
  expose: (options) ->
    for name, fn of options
      @everyone[name] = -> fn.apply(this, arguments) 
    
    return this
    

module.exports.server = (app) ->
  sessions = {}  
  everyone = require('now').initialize(app)

  everyone.disconnected ->
    delete sessions[@now.sid]

  everyone.now.sync = (sid) ->
    sessions[sid].flush(@now, everyone)
    @now.sid = sid
    console.log @now
  
  everyone.now.callServer = (method, args...) ->
    console.log "everyone.now.callServer", arguments...
    sessions[@now.sid].handleCall(method, args...)
  
  middleware = (req, res, next) ->
    sid = req.cookies['live:sid']
    
    if not sid?
      sid = uuid()
      console.log "Setting session id", sid
      res.cookie('live:sid', uuid())
    
    sessions[sid] = req.bidi = new Session(everyone, sid)
    console.log "SESSIONS", sessions
    next()

  app.use(middleware)
  
  return new Server(everyone)

class Client
  constructor: ->
    @methods = {}
    @connectQueue = new Queue
    
    now.callClient = (method, args...) =>
      console.log "Client.now.callClient", arguments...
      @methods[method](args...) if @methods[method]
      
    now.ready =>
      cookies = parseCookie(document.cookie)
      console.log "Client cookies", cookies
      now.sync cookies['live:sid']
      @connectQueue.flush()
  
  expose: (options) ->
    @methods[name] = fn for name, fn of options
    return this
      
  send: (method, args...) ->
    @connectQueue.add =>
      now.callServer(method, args...)
      return
    return this

    
client = null

module.exports.Client = Client
module.exports.client = ->
  return client or (client = new Client)