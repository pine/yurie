_ = require 'lodash'

mm = require 'musicmetadata'
mime = require 'mime-types'
blobUtil = require 'blob-util'

localBlobUtil = require './blob'


getPictureUrls = (metadata) ->
  _.each metadata.picture, (picture) ->
    buff = picture.data
    type = mime.lookup(picture.format)

    imgBlob = localBlobUtil.arrayBufferToBlob(buff, type)
    picture.url = blobUtil.createObjectURL(imgBlob, type)


loadArrayBufferByAjax = (path, cb) ->
  xhr = new XMLHttpRequest()
  
  xhr.open('GET', path)
  xhr.responseType = 'arraybuffer'
  xhr.onload = (e) ->
    if xhr.status != 200
      return cb(xhr.status + ' ' + xhr.statusText, xhr.response)
    
    cb(null, xhr.response)

  xhr.send()


loadMetadataByBlob = (blob, cb) ->
  try
    parser = mm(blob)
  catch e
    return cb(e)
  
  parser.on 'metadata', (result) ->
    getPictureUrls(result)
    cb(null, result)

  parser.on 'done', (err) ->
    blob = undefined
    cb(err) if err


loadMetadataByAjax = (path, cb) ->
  type = mime.lookup(FILE)
  
  loadArrayBufferByAjax path, (err, data) ->
    return cb(err) if err
    
    blob = localBlobUtil.arrayBufferToBlob(data, data)
    
    loadMetadataByBlob blob, (err, metadata) ->
      cb(err, metadata)


module.exports =
  loadMetadataByBlob: loadMetadataByBlob
  loadMetadataByAjax: loadMetadataByAjax
