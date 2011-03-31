express = require('express')
app = module.exports = express.createServer()

connect = require('connect')
auth = require('connect-auth')
stylus = require('stylus')

browserify = require('browserify')
dnode = require('dnode')

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
    auth.Facebook({appId: fb.id, appSecret: fb.secret, scope : "email", callback: fb.callback})
  ])
  app.use require('./middleware/user')
  app.use require('./middleware/flash')
  app.use stylus.middleware({ src: __dirname + '/public' })
  app.use express.static(__dirname + '/public')
  app.use browserify({
    require: ['dnode', 'backbone']
    mount: '/browserify.js'
    base: [__dirname + '/browserify', __dirname + '/models']
    entry: __dirname + '/entry.js'
  })
  app.use express.errorHandler()
  
app.get '/', (req, res) ->
  res.local 'flash', req.flash()
  res.render 'index'
  
class Spine
  constructor: ->
    @dnode = require('dnode')(arguments...)
    @dnode.use @server
    @dnode.listen(app)
    
    console.log "Dnode server started"
  
  server: (client, conn) ->
    @notify = (data, cb) ->
      console.log "Msg recieved", data
    return
    
spine = new Spine()