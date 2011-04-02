express = require('express')
app = module.exports = express.createServer()

connect = require('connect')
auth = require('connect-auth')
stylus = require('stylus')

browserify = require('browserify')
dnode = require('dnode')

fb = require("./fb_creds.js")

require.paths.unshift(__dirname + '/browserify')

app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session
    secret: 'password'
  app.use express.logger({ format: ':date :remote-addr :method :status :url' })
  #app.use auth([
  #  auth.Facebook({appId: fb.id, appSecret: fb.secret, scope : "email", callback: fb.callback})
  #])
  app.use browserify({
    require: ['node-uuid', 'jquery', 'backbone']
    mount: '/browserify.js'
    base: [__dirname + '/browserify', __dirname + '/models']
  })
  app.use express.compiler
    src: __dirname + '/public'
    enable: ['less', 'coffeescript']
  app.use express.static(__dirname + '/public')
  app.use express.errorHandler()
  
loadUser = require('./middleware/user')

pageUsers = {}

everyone = require('live').server(app)


app.get '/:page?', loadUser, (req, res) ->
  page = req.params.page or 'index'
  
  req.bidi
    .send 'getName', (err, name) ->
      req.bidi.name = name
      req.bidi.broadcast 'serverMessage', name, "connected"
    .expose
      relay: (msg) ->
        console.log "Relay called"
        req.bidi.broadcast 'talk', @name, msg

  res.render 'index', locals:
    page: page
    currentUser: req.session.currentUser
    


