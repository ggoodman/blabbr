express = require('express')
app = module.exports = express.createServer()

redis = require('redis')
rc = redis.createClient()

browserify = require('browserify')
dnode = require('dnode')
uuid = require('node-uuid')
EventEmitter = require('events').EventEmitter

require.paths.unshift('./shared')

fb = require("./fb_creds.js")

_ = require('underscore')._


app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.vhost "clockout.codenimbus.org", require('./clockout/app')
  app.use express.vhost "test.codenimbus.org", require('./clockout/app')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session
    secret: 'password'
  app.use express.logger({ format: ':date :remote-addr :method :status :url' })
  app.use browserify({
    require: ['underscore', 'backbone', 'dnode']
    mount: '/browserify.js'
    base: [__dirname + '/shared']
  })
  app.use express.compiler
    src: __dirname + '/public'
    enable: ['less', 'coffeescript']
  app.use express.static(__dirname + '/public')
  app.use express.errorHandler()
  
loadUser = require('./middleware/user')


app.get '/', loadUser, (req, res) ->
  page = req.params.page or 'index'
 
  res.render 'index', locals:
    page: page
    currentUser: req.session.currentUser

if not module.parent
  app.listen 80

emitter = new EventEmitter

#rc.flushall()

iface = (client, conn) ->
  
  listeners = {}
  listen = (event, cb) ->
    listeners[event] = cb
    emitter.on(event, cb)
  
  conn.on 'end', ->
    emitter.removeListener(event, cb) for event, cb of listeners
    
  @create = (collection, data, options) ->
    console.log "iface.create", arguments...
    data.id = uuid()
    json = JSON.stringify(data)
    
    rc.multi()
      .set(data.id, json)
      .set("lumbar:#{data.id}:created", Date.now())
      .lpush("lumbar:#{collection}:models", data.id)
      .exec (err, ret) ->
        options.success(data) unless err
        options.error() if err
        return emitter.emit("lumbar:#{collection}:add", data)

  @watch = (key, options) ->
    listen("lumbar:#{key}:#{event}", cb) for event, cb of options
     
  @read = (id, options) ->
    console.log "iface.read", arguments...

  @update = (key, data, options) ->
    rc.set key, JSON.stringify(data), (err, ret) ->
      options.success(data) unless err
      options.error() if err
      return emitter.emit("lumbar:#{key}:change", data)
      
  
  @delete = (key, data, options) ->
    console.log "iface.delete", arguments...
    rc.del key, (err, ret) ->
      if err
        return options.error()
      else
        options.success(data)
        return emitter.emit("lumbar:#{key}:remove", data)
    
  @refresh = (type, options) -> 
    console.log "iface.refresh", arguments...
    rc.sort "lumbar:#{type}:models", "by", "lumbar:*:created", "get", "*", "limit", 0, 40, "DESC", (err, data) ->
      
      out = []
      
      for i in [data.length-1..0]
        out.push JSON.parse(data[i]) if data[i]

      console.log "rc.sort", arguments...
      return options.success(out) unless err
      return options.error()
    return
  
  return this  

dnode = require('dnode')
dnode(iface).listen(app)  
