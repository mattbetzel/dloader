util = require("./util")
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

module.exports = (dirPath) ->
  util.reduceToPromise(pathSegments(dirPath), createPathUnlessExists)
