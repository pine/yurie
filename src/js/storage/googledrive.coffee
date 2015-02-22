path = require 'path'

_ = require 'lodash'
Lazy = require 'lazy.js'
async = require 'async'

CloudFile = require '../file/cloudfile'


class GoogleDrive
  @ID = 'googledrive'
  @SCOPES: ['https://www.googleapis.com/auth/drive']
  @FOLDER_MIME = 'application/vnd.google-apps.folder'
  @ROOT_FILE_ID = 'root'
  
  constructor: (options) ->
    @options = options
    
  auth: (immediate, cb) ->
    gapi.client.setApiKey(@options.apiKey)
    gapi.auth.authorize
      client_id: @options?.clientId
      scope: GoogleDrive.SCOPES
      immediate: immediate
    
    , (result) =>
      err = !result or result.error
      cb(err)
  
  getRootDirs: (cb) ->
    getFiles GoogleDrive.ROOT_FILE_ID, '/', (err, files) ->
      return cb(err) if err
      cb(null, filterDirs(files))
  
  getFiles: (dir, cb) ->
    getFiles dir.id, dir.path, (err, files) ->
      return cb(err) if err
      cb(null, filterFiles(files))
  
  getRecursiveFiles: (dir, options) ->
    if options?.isSkip?(dir.path)
      return options?.done?()
    
    getFiles dir.id, dir.path, (err, entries) =>
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
      
  
  # ファイルの内容を取得する
  getFileContent: (file, cb) ->
    getDownloadUrl file.id, (err, url) ->
      accessToken = gapi.auth.getToken().access_token;
      
      xhr = new XMLHttpRequest()
      xhr.open('GET', url)
      xhr.setRequestHeader('Authorization', 'Bearer ' + accessToken)
      xhr.responseType = 'blob'
        
      xhr.onload = ->
        if xhr.status != 200
          return cb(xhr.status + ' ' + xhr.statusText, xhr.response)
        
        cb(null, xhr.response)
      
      xhr.onerror = ->
        cb(xhr.status + ' ' + xhr.statusText)
      
      xhr.send()
  
  # Google Drive のファイル情報を CloudFile に変換する
  toCloudFile = (folderPath, entry, cb) ->
    req = gapi.client.drive.files.get
      fileId: entry.id

    req.execute (res) ->
      return cb(res.error) if res.error

      file = new CloudFile
        provider: GoogleDrive.ID
        id: res.id
        path: path.join('/', folderPath, res.title)
        isDir: res.mimeType == GoogleDrive.FOLDER_MIME
        mimeType: res.mimeType
        origin: res

      cb(null, file)
  
  # Google Drive のファイル情報の配列を CloudFile に変換する
  toCloudFiles = (folderPath, entries, cb) ->
    async.map entries, (entry, done) ->
      toCloudFile(folderPath, entry, done)
    
    , (err, results) ->
      cb(err, results)
  
  # ディレクトリのみ抽出する
  filterDirs = (entries) ->
    _.filter(entries, (x) -> x.isDir)
  
  # ファイルのみ抽出する
  filterFiles = (entries) ->
    _.filter(entries, (x) -> !x.isDir)
  
  # フォルダ内のファイルを全て取得する
  getFiles = (folderId, folderPath, cb) ->
    req = gapi.client.drive.children.list
      folderId: folderId
      maxResults: 1000
      q: "trashed = false"
    
    req.execute (res) ->
      return cb(res.error) if res.error
      
      toCloudFiles folderPath, res.items, (err, files) ->
        cb(err, files)
  
  # ダウンロード URL を取得
  getDownloadUrl = (id, cb) ->
    req = gapi.client.drive.files.get
      fileId: id
    
    req.execute (res) ->
      cb(res.error, res.downloadUrl)

module.exports = GoogleDrive