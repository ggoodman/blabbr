(function() {
  var Chat;
  Chat = require('./chat');
  $(function() {
    var chat;
    FB.getLoginStatus(function(response) {
      if (!response.session) {
        return $('#login').dialog({
          title: "Please login",
          modal: true
        });
      }
    });
    return chat = new Chat();
    /*
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
    */
  });
}).call(this);
