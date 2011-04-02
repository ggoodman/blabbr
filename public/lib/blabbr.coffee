$ = require('jquery')
$ ->
  $('#input').change ->
    live.send 'relay', $('#input').val()

live = require('./live').client()
  .expose
    serverMessage: (name, message) ->
      console.log "*** #{name} #{message}" 
    talk: (name, message) ->
      $('<dt>', {text: name}).appendTo('#chat')
      $('<dd>', {text: message}).appendTo('#chat')
    getName: (cb) ->
      name = prompt("What is your name")
      if name then cb(false, name)
      else cb(true)
    
