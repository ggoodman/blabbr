Chat = require('./chat')


$ ->
  chat = new Chat()
  ###
  if false#first_login
    handleSubmit = ->
      alert $('#first-login-username').val()
      $(this).dialog('close')
    handleCancel = ->
      $(this).dialog('close')
      
    $('#first-login').dialog
      modal: true
      title: "Set username"
      buttons:
        "OK": -> handleSubmit.call(this)
        "Cancel": -> handleCancel.call(this)
      keypress: (e) ->
        handleSubmit.call(this) if e.keyCode in [10, 13]
  ###