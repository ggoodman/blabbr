var socket = new io.Socket();
socket.connect();

function htmlEncode(value){
  return $('<div/>').text(value).html();
}

function htmlDecode(value){
  return $('<div/>').html(value).text();
}

function systemMessage(client, message) {
  $("<li>", {
    class: 'bab-system'
  })
    .append('*&nbsp;')
    .append(userLink(client))
    .append("&nbsp;" + message)
    .appendTo('#messages');
}

function userLink(client) {
  return $('<a>',{
    class: 'bab-user-hint',
    href: '#bab-user-' + client.sid,
    text: client.name
  });
}

function chatMessage(msg) {
  $("<li>", {
    class: 'bab-message'
  })
    .append(userLink(msg.client))
    .append("&nbsp;")
    .append(msg.data.message)
    .appendTo('#messages');
}

socket.on('message', function(msg){
  console.log(msg);
  switch (msg.type) {
    case 'connect':
      systemMessage(msg.client, "connected");
      break;
    case 'disconnect':
      systemMessage(msg.client, "disconnected");
      break;
    case 'message':
      chatMessage(msg);
      break;
   }
});
$(function(){
  $('#input').keypress(function(e){
    var code = e.keyCode || e.charCode || 0;
    if (code == 10 || code == 13) {
      socket.send({
        type: 'message',
        data: {
          message: $(this).val()
        }
      });
      $(this).val('');
    }
  });
})
$('.bab-user-hint').live('click', function(e){
  var $input = $('#input');
  if (!$input.val()) {
    $input.val('@' + $(this).text() + ': ').focus();
  }
  e.preventDefault();
});