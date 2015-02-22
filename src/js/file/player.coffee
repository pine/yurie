_ = require 'lodash'
blobUtil = require 'blob-util'

class Player
  audio: null
  constructor: (elem) ->
    @audio = elem or $(new Audio())
  play: (blob) ->
    url = blobUtil.createObjectURL(blob)
    prevUrl = @audio.prop('url')

    @audio.prop('src', url)
    @audio.trigger('play')
  
    if prevUrl
      blobUtil.revokeObjectURL(prevUrl)
      
  pause: () ->
    @audio.trigger('pause')
  
  on:  ->
    @audio.on.apply(@audio, arguments)
  
  off:  ->
    @audio.off.apply(@audio, arguments)
  
  one: ->
    @audio.one.apply(@audio, arguments)
    
module.exports = Player