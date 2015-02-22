path = require 'path'

class CloudFile
  constructor: (options) ->
    @_origin = options.origin
    @provider = options.provider
    @id = options.id or options.path
    @path = options.path
    @isDir = options.isDir or false
    @mimeType = options.mimeType unless @isDir
    
    Object.defineProperty @, 'title',
      get: => path.basename(@path, path.extname(@path))
    
module.exports = CloudFile