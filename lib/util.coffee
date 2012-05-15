Q = require("q")

exports.reduceToPromise = (arr, func) ->
  reduce_ = (memo, obj) -> memo.then(-> func(obj))
  arr.reduce(reduce_, Q.resolve())

exports.log = (func) -> (obj) -> console.log(func(obj)); obj

exports.take = (n) -> (arr) -> arr[...n]
