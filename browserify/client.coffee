dnode = require('dnode')
Backbone = require('backbone')
User = require('./user')

console.log new User
  name: "Geoffrey Goodman"
  
dnode.connect (server) ->
  server.notify "Message from the future"