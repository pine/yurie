path = require 'path'

_ = require 'lodash'
async = require 'async'
mime = require 'mime-types'

CloudFile = require '../file/cloudfile'


unless window.WL?
  console.error 'Can\'t find lib `Live SDK`'
  return

#onLoginComplete = ->
#  console.log 'login completed'

#WL.Event.subscribe('auth.login', onLoginComplete)

#WL.init
#  client_id: '000000004013FC5C'
#  scope: ['wl.signin', 'wl.skydrive']

#console.log WL.getSession()

#WL.login
#  scope: ['wl.signin', 'wl.skydrive']


class OneDrive
  @ID = 'onedrive'
  @SCOPES = ['wl.signin', 'wl.skydrive']
  @DIR_TYPES = ['folder']
  
  constructor: (@options) ->
  auth: (immediate, cb) ->
    WL.init
      client_id: @options.clientId
      scope: OneDrive.SCOPES
    
    WL.getLoginStatus().then (res) ->
      if immediate or res.status == 'connected'
        return cb()
      
      WL.login( scope: OneDrive.SCOPES ).then (res) ->
        cb()
      , (err) -> cb(err)
        
    , (err) -> cb(err)
  
  getRootDirs: (cb) ->
    WL.api( path: 'me/skydrive/files' ).then (res) ->
      cb(null, filterDirs(toCloudFiles('/', res?.data)))
    , (err) -> cb(err)
  
  # -----------------------------------------------------------------
  
  getFiles: (dir, cb) ->
    getFiles dir, (err, files) ->
      return cb(err) if err
      cb(null, filterFiles(files))
  
  # -----------------------------------------------------------------
  
  getRecursiveFiles: (dir, options) ->
    if options?.isSkip?(dir.path)
      return options?.done?()
    
    getFiles dir, (err, entries) =>
      files = filterFiles(entries)
      dirs = filterDirs(entries)
      
      # エラー時の処理
      options?.done?(err) if err
      
      # ファイルの一覧
      options?.found?(files)
      
      # ディレクトリ一覧から再帰的に取得
      async.each dirs, (dir, done) =>
        # ディレクトリごとに再帰
        @getRecursiveFiles dir,
          found: (err, files) => options?.found?(err, files)
          done: (err) => done(err)
          isSkip: options?.isSkip
      
      # 再帰終了
      , (err) =>
        options?.done?(err)
      
    , (err) -> cb(err)
  
  # -----------------------------------------------------------------
  
  getFileContent: (file, cb) ->
    
    WL.api( path: "/#{file.id}/content" ).then (res) ->
      url = res.location
      console.log url
     
      xhr = new XMLHttpRequest()
      xhr.open('GET', url)
      xhr.responseType = 'blob'
      
      xhr.onload = ->
        if xhr.status != 200
          return cb(xhr.status + ' ' + xhr.statusText, xhr.response)
        
        cb(null, xhr.response)
      
      xhr.onerror = ->
        cb(xhr.status + ' ' + xhr.statusText)
      
      xhr.send()
      
    , (err) -> cb(err)
  
  # -----------------------------------------------------------------
  
  # OneDrive の形式を CloudFile に変換する
  toCloudFiles = (path, entries) ->
    _.map entries, (entry) -> toCloudFile(path, entry)
  
  toCloudFile = (folderPath, entry) ->
    new CloudFile
      provider: OneDrive.ID
      origin: entry
      id: entry.id
      path: path.join('/', folderPath, entry.name)
      isDir: _.contains(OneDrive.DIR_TYPES, entry.type)
      mimeType: mime.lookup(entry.name)
  
  getFiles = (dir, cb) ->
    WL.api( path: "/#{dir.id}/files" ).then (res) ->
      cb(null, toCloudFiles(dir.path, res?.data))
    , (err) -> cb(err)
    
  filterDirs = (entries) ->
    _.filter entries, (entry) -> entry.isDir

  filterFiles = (entries) ->
    _.filter entries, (entry) -> !entry.isDir
  
module.exports = OneDrive