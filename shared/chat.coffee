Queue = require('./queue')
dnode = require('dnode')
backbone = require('backbone')
    

class CollectionSyncer
  constructor: (@model, @options) ->
    self = this
    
    @queue = new Queue
    @model.class = @options.class
    @model.sync = (method, model, success, error) ->
      self.queue.add -> self['_' + method](model, success, error)
  
  _create: (model, success, error) =>
    console.log "CollectionSyncer.create", arguments...
  
  _read: (model, success, error) =>
    console.log "CollectionSyncer.read", arguments...
    @client.refresh model.class,
      add: => @model.add(arguments...)
      remove: => @model.remove(arguments...)
      change: (data) => @model.get(data.id).set(data)
      success: (data) =>
        console.log "CollectionSyncer.read.success", arguments...
        success(data)
      error: =>
        console.log "CollectionSyncer.read.error", arguments...
        error(data)
 
  _update: (model, success, error) =>
    console.log "CollectionSyncer.update", arguments...
  
  _delete: (model, success, error) =>
    console.log "CollectionSyncer.delete", arguments...
  
  flush: (@client) =>
    console.log "CollectionSyncer.flush", arguments...
    @queue.flush()
    @client.watch @options.class,
      add: (data) =>
        console.log "CollectionSyncer.flush.add", arguments...
        @model.add(data) unless @model.get(data.id)
      remove: (data) =>
        console.log "CollectionSyncer.flush.add", arguments...
        @model.remove(data)

class ModelSyncer
  constructor: (@model, @options) ->
    self = this
    
    @queue = new Queue
    @model.class = @options.class
    @model.sync = (method, model, success, error) ->
      self.queue.add -> self['_' + method](model, success, error)
  
  _create: (model, success, error) =>
    console.log "ModelSyncer.create", arguments...
    @client.create model.class, model.toJSON(),
      success: (data) =>
        console.log "ModelSyncer.create.success", arguments...
        success(data)
      error: =>
        console.log "ModelSyncer.create.error", arguments...
        error(data)
  
  _read: (model, success, error) =>
    console.log "ModelSyncer.read", arguments...
    @client.read model.class, model.toJSON(),
      success: (data) =>
        console.log "ModelSyncer.read.success", arguments...
        success(data)
      error: =>
        console.log "ModelSyncer.read.error", arguments...
        error(data)
 
  _update: (model, success, error) =>
    console.log "ModelSyncer.update", arguments...
    @client.update model.id, model.toJSON(), 
      success: (data) =>
        console.log "ModelSyncer.update.success", arguments...
        success(data)
      error: =>
        console.log "ModelSyncer.update.error", arguments...
        error(data)
        
  _delete: (model, success, error) =>
    console.log "ModelSyncer.delete", arguments...
    @client.delete model.id, model.toJSON(),
      success: (data) ->
        console.log "ModelSyncer.delete.success", arguments...
        success(arguments...)
      error: ->
        console.log "ModelSyncer.delete.error", arguments...
        error(arguments...)  
  
  flush: (@client) =>
    console.log "ModelSyncer.flush", @model.toJSON(), arguments...
    @queue.flush()
    @client.watch @model.id,
      change: =>
        console.log "ModelSyncer.flush.change", arguments...
        @model.set(arguments...)

class Lumbar
  constructor: ->
    @connectQueue = new Queue
    self = this
    
    @server = dnode(@handlers).connect (client) ->
      self.connectQueue.flush(client)
      return
  
  handlers: ->
    add: =>
      console.log "server.add", this, arguments...
    remove: =>
      console.log "server.remove", this, arguments...
    change: =>
      console.log "server.change", this, arguments...
    refresh: =>
      console.log "server.refresh", this, arguments...
    
  sync: (model, options) =>
    if model instanceof backbone.Collection
      syncer = new CollectionSyncer(model, options)
      @connectQueue.add (client) ->
        syncer.flush(client)
    else if model instanceof backbone.Model
      syncer = new ModelSyncer(model, options)
      @connectQueue.add (client) ->
        syncer.flush(client)
      
    
    ###
    self = this
    model.class = options.class
    model.bind 'add', (model) ->
      self.connectQueue.add (client) ->
        model.bind 'change', (model) ->
          console.log "Model change detected!", arguments...
          client.update(model)
    
    model.sync = (method, model, success, error) ->
      console.log "[Model.sync]", arguments...
           
      if model instanceof backbone.Collection and method == 'read'
        self.connectQueue.add (client) ->
          console.log "[REFRESH]", method, model
          client.refresh model.class,
            success: (data) ->
              model.refresh(data)
            error: error
            add: ->
              model.add(arguments...)
            remove: ->
              model.remove(arguments...)
            change: (data) ->
              model.get(data.id).set(data, {silent: true})
              
            
      else
        self.connectQueue.add (client) ->
          console.log "[{#method}]", method, model
          client[method](model.class, model.toJSON())
      return
    ###
        
      
lumbar = module.exports = new Lumbar

class Message extends backbone.Model
  initialize: ->
    lumbar.sync this,
      class: 'messages'

class Messages extends backbone.Collection
  model: Message
  initialize: ->
    lumbar.sync this,
      class: 'messages'

class Chatter extends backbone.Model
  initialize: ->
    @name = prompt("What is your name?") until @name

class ChatMessage extends backbone.View
  tagName: 'li'
  
  initialize: ->
    @model.bind 'change', @render
    @model.bind 'remove', =>
      $(@el).detach()
      delete this
    
    $(@el).click =>
      console.log "Clicked", @model.attributes
      @model.destroy()
      console.log "New mode", @model.attributes
    
  render: =>
    $(@el).text(@model.get('name') + ": " + @model.get('message'))
    return this
    
class ChatApp extends backbone.View
  el: $('#chat')
    
  initialize: ->
    @messages = new Messages
    @chatter = new Chatter
    
    $('#input').keypress(@handlePostMessage)
    
    @messages.bind 'refresh', @refreshMessages
    @messages.bind 'add', @displayMessage
    
    @input = $('#input')
    @history = $('#messages')
    
    @input.focus()
    
    @messages.fetch()
  
  refreshMessages: (messages) =>
    console.log "ChatApp.refreshMessages", messages
    messages.each @displayMessage
    return
  
  displayMessage: (message) =>
    console.log "ChatApp.displayMessage", message
    msgView = new ChatMessage(model: message)
    @history
      .append(msgView.render().el)
      .parent().scrollTop(@history.height() - @history.parent().height())
    return this
  
  handlePostMessage: (e) =>
    self = this
    if e.keyCode == 10 or e.keyCode == 13
      console.log "ChatApp.handlePostMessage", arguments...
      @messages.create
        name: @chatter.name
        message: $('#input').val()
      
      $('#input').val('').focus()
      
    return

module.exports = ChatApp