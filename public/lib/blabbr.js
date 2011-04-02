(function() {
  var $, live;
  $ = require('jquery');
  $(function() {
    return $('#input').change(function() {
      return live.send('relay', $('#input').val());
    });
  });
  live = require('./live').client().expose({
    serverMessage: function(name, message) {
      return console.log("*** " + name + " " + message);
    },
    talk: function(name, message) {
      $('<dt>', {
        text: name
      }).appendTo('#chat');
      return $('<dd>', {
        text: message
      }).appendTo('#chat');
    },
    getName: function(cb) {
      var name;
      name = prompt("What is your name");
      if (name) {
        return cb(false, name);
      } else {
        return cb(true);
      }
    }
  });
}).call(this);
