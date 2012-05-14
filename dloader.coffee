jsdom = require("jsdom")
Q = require("q")
fs = require("fs")
http = require("http")
crypto = require("crypto")
request = require("request")
temp = require("temp")
mime = require("mime")
path = require("path")

log = (func) -> (obj) -> console.log(func(obj)); obj

take = (n) -> (arr) -> arr[...n]

createHasher = -> crypto.createHash("md5")

identifyType = (href) -> mime.lookup(href)
toFilename = (base, type) -> base[...2] + "/" + base + "." + mime.extension(type)

retrieveDOM = (href) ->
  Q.ncall(jsdom.env, jsdom, href, ["http://code.jquery.com/jquery-1.7.2.min.js"])

findPosts = (window) -> window.$(".gallery")
findImagePageLinks = (galleries) -> link.href for link in galleries.find("a")

retrieveImgLinks = (pageLinks) ->
  Q.all(pageLinks.map(retrieveDOM))
    .then((windows) -> windows.map(retrieveImgFromPage))

retrieveImgFromPage = (window) -> window.$(".p-con").find("a").attr("href")

writeToFile = (filePath, href) ->
  defer = Q.defer()
  hasher = createHasher()
  request(href)
    .on("data", (data) -> hasher.update(data))
    .on("end", -> defer.resolve([filePath, hasher.digest("hex"), identifyType(href)]))
    .on("error", (err) -> defer.reject(err))
    .pipe(fs.createWriteStream(filePath))
  defer.promise

writeToFiles = (pathFunc) -> (hrefs) ->
  Q.all(writeToFile(pathFunc(), href) for href in hrefs)

uniqueFile = -> temp.path({suffix: ".tmp"})

moveFile = ([src, md5, type]) -> 
  dest = toFilename(md5, type)
  ensureDir(path.dirname(dest)).then(-> renameFile(src, dest))

renameFile = (src, dest) -> Q.ncall(fs.rename, fs, src, dest)

moveFiles = (files) -> Q.all(files.map(moveFile))

ensureDir = (dirPath) ->
  ensure_ = (memo, dirSeg) -> memo.then(-> pathExists(dirSeg))
    .then((exists) -> Q.ncall(fs.mkdir, fs, dirSeg) unless exists)
  pathSegments(dirPath).reduce(ensure_, Q.resolve())

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
  .then(moveFiles)
  .end()
