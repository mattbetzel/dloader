fs = require("fs")
path = require("path")
Q = require("q")

s3 = JSON.parse(fs.readFileSync(path.join(process.env["HOME"], ".s3.json")))
knox = require("knox").createClient(s3)

s3Headers = (type) ->
  "Content-Type": type
  "x-amz-acl": "private"

moveFile = (base, nameFunc, [src, md5, type]) ->
  Q.ncall(knox.putFile, knox, src, nameFunc(base, md5, type), s3Headers(type))
    .then(-> Q.ncall(fs.unlink, fs, src))

module.exports = (base, nameFunc) -> (files) ->
  Q.all(moveFile(base, nameFunc, file) for file in files)
