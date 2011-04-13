backbone = require('backbone')
_ = require('underscore')._

module.exports = lumbar = {}


class lumbar.Model extends backbone.Model
  xport: (options) ->
    result = {}
    settings = _({ recurse: true}).extend(options or {})
    
    process = (target, source) ->
      target.id = source.id or null
      target.cid = source.cid or null
      target.attrs = source.toJSON()
      
      for key, value of source
        if settings.recurse
          if key != 'collection' and source[key] instanceof backbone.Collection
            target.collections |= {}
            target.collections[key] =
              models: []
              id: source[key].id or null
            process(target.collections[key].models[i] = {}, value) for i, value of source[key].models
          else if source[key] instanceof backbone.Model
            target.models |= {}
            process(target.models[key] = {}, value)
    
    process(result, this)
    
    return result
  
  mport: (data, silent) ->
    process = (target, data) ->
      target.id = data.id or null
      target.set(data.attrs, {silent: silent})
      
      if data.collections
        for name, collection of data.collections
          target[name].id = collection.id
          process(target[name]._add({}, {silent: silent}), modelData) for i, modelData of collection.models
      
      if data.models
        process(target[name], modelData) for name, modelData of data.models
    
    process(this, data)
    
    return this

class lumbar.Collection extends backbone.Collection
