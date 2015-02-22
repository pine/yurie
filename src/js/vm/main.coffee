Vue = require 'vue'

module.exports =
  el: 'body'
  data:
    progress: false
  
  computed:
    bodyClassName: ->
      'y-progress' if @progress
  
  created: ->
    console.log 'MainVM: created'
  
  ready: ->
    console.log 'MainVM: ready'
  
  components:
    player: require './player'
  filters:
    providerToName: require '../filters/providerToName'
    join: require '../filters/join'

