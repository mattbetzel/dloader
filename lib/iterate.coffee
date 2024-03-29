Q = require("q")

iterate = (loader, nexter) -> (mapper) -> (first, max) ->
  iterate_ = (next, idx) ->
    recurse = (next) -> iterate_(next, idx + 1) if next?
    mapAndNext = (item) ->
      Q.resolve(mapper(item)).then(-> nexter(item)) if idx <= max
    Q.resolve(loader(next))
      .then(mapAndNext)
      .then(recurse)
  iterate_(first, 1)

module.exports = iterate
