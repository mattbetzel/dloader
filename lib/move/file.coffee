util = require("../util")
Q = require("q")
path = require("path")
fs = require("fs")

createPathUnlessExists = (dirPath) ->
  pathExists(dirPath)
    .then((exists) -> Q.ncall(fs.mkdir, fs, dirPath) unless exists)

pathSegments = (path) ->
  segment = if (index = path.lastIndexOf("/")) == -1 then "" else path[...index]
  if segment.length == 0 then [path] else pathSegments(segment).concat(path)

pathExists = (filePath) ->
  defer = Q.defer()
  path.exists(filePath, (exists) -> defer.resolve(exists))
  defer.promise

ensureDir = (dirPath) ->
  util.reduceToPromise(pathSegments(dirPath), createPathUnlessExists)
  
moveFile = (base, nameFunc) -> ([src, md5, type]) ->
  dest = nameFunc(base, md5, type)
  ensureDir(path.dirname(dest)).then(-> renameFile(src, dest))

renameFile = (src, dest) -> Q.ncall(fs.rename, fs, src, dest)

module.exports = (base, nameFunc) -> (files) ->
  util.reduceToPromise(files, moveFile(base, nameFunc))


