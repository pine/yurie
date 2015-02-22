_ = require 'lodash'

module.exports = (value, sep = ', ') ->
  if value
    if _.isFunction(value.join)
      value.join(sep)
    
    else
      value
  else
    ''