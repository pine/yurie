_ = require 'lodash'
Vue = require 'vue'

metadata = require '../file/metadata'
Player = require '../file/player'

GoogleDrive = require '../storage/googledrive'
Dropbox = require '../storage/dropbox'
OneDrive = require '../storage/onedrive'

module.exports =
  template: JST['player.html']()
  data: ->
    storage:
      googledrive: new GoogleDrive
        apiKey: 'AIzaSyB_askxokrxEowghrSGXUiIHWS8qOzr-Dk'
        clientId: '417927041867-9gb2p3rhq2vjvmkeq2tobjki092jeori.apps.googleusercontent.com'
      dropbox: new Dropbox( key: 'gfgm1rnutr5cu9i' )
      onedrive: new OneDrive
        clientId: '000000004013FC5C'
    
    files: []
    meta: null
    cover: ""
    player: null
  
  methods:
    play: (file) ->
      return if @$parent.progress
      @$parent.progress = true
      
      @storage[file.provider].getFileContent file, (err, data) =>
        @$parent.progress = false
        
        metadata.loadMetadataByBlob data, (err, meta) =>
          console.error(err) if err
          console.log meta
          
          if _.size(meta.picture) > 0
            @cover = meta.picture[0].url
            @meta = meta

        @player.play(data)
    
    loadStorage: (id) ->
      @storage[id].auth false, (err) =>
        return console.error(err) if err
        console.log 'Auth succeeded: id = ' + id
        
        @storage[id].getRootDirs (err, dirs) =>
          return console.error(id, err) if err
          console.log id, dirs
        
        root = switch id
          when 'dropbox'
            path: '/Music'
          when 'googledrive'
            path: '/Music', id: '0B1oNQoX_Xn79dWsxWnE2amdyZkU'
          when 'onedrive'
            path: '/Music', id: 'folder.7d8e02c31f938e2f.7D8E02C31F938E2F!64966'
        
#        @storage[id].getFiles root, (err, files) ->
#          console.log err, files
        
        @storage[id].getRecursiveFiles root,
          found: (files) =>
            _.each files, (file) =>
              console.log file
              @files.push(file)
            
  created: ->
    console.log 'PlayerVM: created'
    
    @loadStorage('dropbox')
#    @loadStorage('onedrive')
    
    window.handleClientLoad = =>
      gapi.client.load 'drive', 'v2', =>
        console.log 'Loaded Google Drive API'
        @loadStorage('googledrive')
  
  ready: ->
    console.log 'PlayerVM: ready'
    
    @player = new Player $(@$el).find('audio')

