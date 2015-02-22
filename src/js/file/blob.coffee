getArrayBufferLength = (buf) ->
  bytes = new Uint8Array(buf)
  bytes.length


arrayBufferToBlob = (buff, type) ->
  new Blob([buff], type: type)


module.exports =
  getArrayBufferLength: getArrayBufferLength
  arrayBufferToBlob: arrayBufferToBlob
