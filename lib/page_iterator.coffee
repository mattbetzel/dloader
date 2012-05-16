pageIterator = (loader, pageNexter) -> (mapper) -> (start, max) ->
  pageIterator_ = (next, idx) ->
    recurse = (next) -> pageIterator_(next, idx+1) if next?
    mapAndNext =
      (window) -> mapper(window).then(-> pageNexter(window)) if idx <= max
    loader(next)
      .then(mapAndNext)
      .then(recurse)
  pageIterator_(start, 1)

module.exports = pageIterator
