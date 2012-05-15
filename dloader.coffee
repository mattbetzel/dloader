fs = require("fs")
path = require("path")
http = require("http")
crypto = require("crypto")
jsdom = require("jsdom")
Q = require("q")
request = require("request")
temp = require("temp")
mime = require("mime")

ensuredir = require("./lib/ensuredir")
util = require("./lib/util")

createHash = -> crypto.createHash("md5")
computeDigest = (hash) -> hash.digest("hex")

mimeType = (url) -> mime.lookup(url)
toFilename = (base, name, type) ->
  path.join(base, name[...2], name + "." + mime.extension(type))

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
  ensuredir(path.dirname(dest)).then(-> renameFile(src, dest))

renameFile = (src, dest) -> Q.ncall(fs.rename, fs, src, dest)

moveFiles = (base) -> (files) -> util.reduceToPromise(files, moveFile(base))

retrievePosts = (url, destDir) ->
  retrieveDOM(url)
    .then(findPosts)
    .then(util.log((posts) -> "Found #{posts.size()} posts"))
    .then(findImagePageLinks)
    .then(util.log((posts) -> "Found #{posts.length} links"))
    .then(retrieveImgLinks)
    .then(writeToFiles(uniqueFile))
    .then(moveFiles(destDir))
    .end()

retrievePosts(process.argv[2], process.argv[3])
