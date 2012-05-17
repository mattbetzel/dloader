Q = require("q")

iterate = require("../lib/iterate")

describe "iterate", ->
  failAt = (at, func) -> (i) ->
    if i == at then throw new Error("fail at #{i}") else func(i)
  
  shouldHaveFailed = (done) -> -> done(new Error("should have failed"))

  assertFailed = (done, expected) -> (err) ->
    err.message.should.eql expected
    done()

  assert = (done, func) -> -> func(); done()

  loader = (i) -> i * 10
  nexter = (i) -> i + 1
  mapper = (acc) -> (i) -> acc.push i

  it "iterate through numbers", (done) ->
    actual = []
    iterate(loader, nexter)(mapper(actual))(1, 4)
      .then(assert(done, -> actual.should.eql [10, 110, 1110, 11110]), done)
      .end()

  it "fails in loader on exception", (done) ->
    loaderWithFail = failAt(111, loader)
    iterate(loaderWithFail, nexter)(mapper([]))(1, 3)
     .then(shouldHaveFailed(done), assertFailed(done, "fail at 111"))
     .end()

  it "fails in nexter on exception", (done) ->
    nexterWithFail = failAt(1110, nexter)
    iterate(loader, nexterWithFail)(mapper([]))(1, 3)
     .then(shouldHaveFailed(done), assertFailed(done, "fail at 1110"))
     .end()

  it "fails in mapper on exception", (done) ->
    mapperWithFail = failAt(10, mapper([]))
    iterate(loader, nexter)(mapperWithFail)(1, 3)
     .then(shouldHaveFailed(done), assertFailed(done, "fail at 10"))
     .end()
