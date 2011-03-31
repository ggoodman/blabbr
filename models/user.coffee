Backbone = require('backbone')

class User extends Backbone.Model
  initialize: ->      
    console.log "User created"

module.exports = User