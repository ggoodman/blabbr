class Queue
  constructor: ->
    @reset()
  
  add: (fn) ->
    if @_flushed then fn(@_response)
    else @_methods.push(fn)
    return this
    
  flush: (resp) ->
    if not @_flushed
      @_response = resp
      @_flushed = true
      @_methods.shift()(resp) while @_methods[0]
    return this
  
  reset: ->
    @_methods = []
    @_response = null
    @_flushed = false    
    

module.exports = Queue