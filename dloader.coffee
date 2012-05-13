jsdom = require("jsdom")
Q = require("q")
_ = require("underscore")
fs = require("fs")
http = require("http")
crypto = require("crypto")
request = require("request")
util = require("util")
temp = require("temp")
mime = require("mime")

log = (func) -> (obj) -> console.log(func(obj)); obj
inspect = (obj) -> console.log(util.inspect(obj)); obj

take = (n) -> (arr) -> arr[...n]

createHasher = -> crypto.createHash("md5")

identifyType = (href) -> mime.lookup(href)
toFilename = (base, type) -> base + "." + mime.extension(type)

retrieveDOM = (href) ->
  Q.ncall(jsdom.env, jsdom, href, ["http://code.jquery.com/jquery-1.7.2.min.js"])

findPosts = (window) -> window.$(".gallery")
findImagePageLinks = (galleries) -> link.href for link in galleries.find("a")

retrieveImgLinks = (pageLinks) ->
  Q.all(_.map(pageLinks, retrieveDOM))
    .then((windows) -> _.map(windows, retrieveImgFromPage))

retrieveImgFromPage = (window) -> window.$(".p-con").find("a").attr("href")

writeToFile = (path, href) ->
  defer = Q.defer()
  hasher = createHasher()
  request(href)
    .on("data", (data) -> hasher.update(data))
    .on("end", -> defer.resolve([path, hasher.digest("hex"), identifyType(href)]))
    .on("error", (err) -> defer.reject(err))
    .pipe(fs.createWriteStream(path))
  defer.promise

writeToFiles = (pathFunc) -> (hrefs) ->
  Q.all(writeToFile(pathFunc(), href) for href in hrefs)

uniqueFile = -> temp.path({suffix: ".tmp"})

moveFile = ([src, md5, type]) -> Q.ncall(fs.rename, fs, src, toFilename(md5, type)) 

moveFiles = (files) -> Q.all(_.map(files, moveFile))

retrieveDOM(process.argv[2])
  .then(findPosts)
  .then(log((posts) -> "Found #{posts.size()} posts"))
  .then(findImagePageLinks)
  .then(log((posts) -> "Found #{posts.length} links"))
  .then(retrieveImgLinks)
  .then(writeToFiles(uniqueFile))
  .then(moveFiles)
  .end()