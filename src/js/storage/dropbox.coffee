path = require 'path'

_ = require 'lodash'
Lazy = require 'lazy.js'
async = require 'async'

localBlobUtil = '../file/blob'
CloudFile = require '../file/cloudfile'


unless window.Dropbox?.Client?
  console.error 'Can\'t find a lib `dropbox-js`'


class Dropbox
  @ID = 'dropbox'
  
  constructor: (options) ->
    @client = new window.Dropbox.Client( options )
  
  # 認証
  auth: (immediate, cb) ->
    @client.authenticate interactive: !immediate, (err, client) ->
      cb(err)
  
  # アカウント情報の取得
  getAccountInfo: (cb) ->
    @client.getAccountInfo (err, accountInfo) ->
      cb(err, accountInfo)
  
  # ルートディレクトリの一覧を取得
  getRootDirs: (cb) ->
    @getDirs '/', (err, dirs) ->
      cb(err, dirs)
  
  # ディレクトリ一覧を取得
  getDirs: (path, cb) ->
    @client.readdir path, (err, entries, stat, fileStats) ->
      return cb(err) if err
      
      dirs = filterDirs(fileStats)
      cb(null, toCloudFiles(dirs))
  
  # ファイルの一覧を取得
  getFiles: (path, cb) ->
    @client.readdir path, (err, entries, stat, fileStats) ->
      return cb(err) if err
      
      files = filterFiles(fileStats)
      cb(err, toCloudFiles(files))
  
  # ファイルの一覧を再帰的に取得
  getRecursiveFiles: (file, options) ->
    if options?.isSkip?(file.path)
      return options?.done?()
    
    @client.readdir file.path, (err, entries, stat, fileStats) =>
      dirs = filterDirs(fileStats)
      files = filterFiles(fileStats)
      
      # エラー時の処理
      options?.done?(err) if err
      
      # ファイルの一覧
      options?.found?(toCloudFiles(files))
      
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
  
  # ファイルの内容を取得
  getFileContent: (file, cb) ->
    @client.readFile file.path, blob: true, (err, data, stat) ->
      cb(err, data)
  
  toCloudFile = (stat) ->
    new CloudFile
      provider: Dropbox.ID
      path: stat.path
      isDir: stat.isFolder
      mimeType: stat.mimeType
      origin: stat
  
  toCloudFiles = (stats) ->
    _.map stats, toCloudFile
  
  filterDirs = (stats) ->
    _.filter(stats, (x) -> x.isFolder)
  
  filterFiles = (stats) ->
    _.filter(stats, (x) -> !x.isFolder)
  

module.exports = Dropbox