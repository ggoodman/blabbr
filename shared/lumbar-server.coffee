backbone = require('backbone')
_ = require('underscore')._
io = require('socket.io')
uuid = require('node-uuid')
connect = require('connect')
redis = require('redis')
rc = redis.createClient()

module.exports = lumbar = require('./lib/lumbar')


lumbar.sync = (method, model, resp) ->
  console.log "lumbar.sync", method
  switch method
    when 'update', 'create'
      key = 'lumbar:v1:' + model.id
      attrs = model.toJSON()
      
      multi = rc.multi()
      multi.hset key, field, value for field, value of attrs
      multi.expire key, 60 * 60 # one hour
      multi.exec (err) ->
        if err then resp()
        else resp(attrs)

lumbar.Model.prototype.sync = lumbar.sync
lumbar.Collection.prototype.sync = lumbar.sync


class lumbar.Session extends lumbar.Model
  initialize: ->

class lumbar.Clients extends backbone.Collection
  url: '/'
  model: lumbar.Session


lumbar.init = (app) ->
  lumbar.clients = new lumbar.Clients
    
  socket = io.listen(app)
  socket.on 'connection', (client) ->
    cookies = connect.utils.parseCookie(client.request.headers.cookie)
    cookieId = cookies['connect.sid']
    clientModel = lumbar.clients.get(cookieId)
    
    if not clientModel
      clientModel = lumbar.clients.create
        id: cookieId
    
    clientModel.client = client
    
    client.send
      event: 'initial'
      data: clientModel.xport()

  return this
