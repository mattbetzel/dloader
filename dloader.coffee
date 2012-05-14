fs = require("fs")
path = require("path")
http = require("http")
crypto = require("crypto")
jsdom = require("jsdom")
Q = require("q")
request = require("request")
temp = require("temp")
mime = require("mime")

log = (func) -> (obj) -> console.log(func(obj)); obj

take = (n) -> (arr) -> arr[...n]

createHash = -> crypto.createHash("md5")
computeDigest = (hash) -> hash.digest("hex")

mimeType = (url) -> mime.lookup(url)
toFilename = (base, name, type) ->
  path.join(base, name[...2], name + "." + mime.extension(type))

reduceToPromise = (arr, func) ->
  reduce_ = (memo, obj) -> memo.then(-> func(obj))
  arr.reduce(reduce_, Q.resolve())

jQuerySrc = ["http://code.jquery.com/jquery-1.7.2.min.js"]
retrieveDOM = (url) -> Q.ncall(jsdom.env, jsdom, url, jQuerySrc)

findPosts = (window) -> window.$(".gallery")
findImagePageLinks = (galleries) -> link.href for link in galleries.find("a")

retrieveImgLinks = (pageLinks) ->
  Q.all(pageLinks.map(retrieveDOM))
    .then((windows) -> windows.map(retrieveImgFromPage))

retrieveImgFromPage = (window) -> window.$(".p-con").find("a").attr("href")

writeToFile = (filePath, url) ->
  defer = Q.defer()
  hash = createHash()
  request(url)
    .on("data", (data) -> hash.update(data))
    .on("end", -> defer.resolve([filePath, computeDigest(hash), mimeType(url)]))
    .on("error", (err) -> defer.reject(err))
    .pipe(fs.createWriteStream(filePath))
  defer.promise

writeToFiles = (pathFunc) -> (urls) ->
  Q.all(writeToFile(pathFunc(), url) for url in urls)

uniqueFile = -> temp.path({suffix: ".tmp"})

moveFile = (base) -> ([src, md5, type]) ->
  dest = toFilename(base, md5, type)
  ensureDir(path.dirname(dest)).then(-> renameFile(src, dest))

renameFile = (src, dest) -> Q.ncall(fs.rename, fs, src, dest)

moveFiles = (base) -> (files) -> reduceToPromise(files, moveFile(base))

createPathUnlessExists = (dirPath) ->
  pathExists(dirPath)
    .then((exists) -> Q.ncall(fs.mkdir, fs, dirPath) unless exists)

ensureDir = (dirPath) ->
  reduceToPromise(pathSegments(dirPath), createPathUnlessExists)

pathExists = (filePath) ->
  defer = Q.defer()
  path.exists(filePath, (exists) -> defer.resolve(exists))
  defer.promise

pathSegments = (path) ->
  segment = if (index = path.lastIndexOf("/")) == -1 then "" else path[...index]
  if segment.length == 0 then [path] else pathSegments(segment).concat(path)

retrieveDOM(process.argv[2])
  .then(findPosts)
  .then(log((posts) -> "Found #{posts.size()} posts"))
  .then(findImagePageLinks)
  .then(log((posts) -> "Found #{posts.length} links"))
  .then(retrieveImgLinks)
  .then(writeToFiles(uniqueFile))
  .then(moveFiles(process.argv[3]))
  .end()
