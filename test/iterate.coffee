Q = require("q")

iterate = require("../lib/iterate")

describe "iterate", ->
  failAt = (at, func) -> (i) ->
    if i == at then throw new Error("fail at #{i}") else func(i)
  
  loader = (i) -> Q.resolve(i * 10)
  nexter = (i) -> i + 1
  mapper = (acc) -> (i) -> Q.resolve(acc.push i)

  it "iterate through numbers", (done) ->
    total = []
    assert = ->
      [10, 110, 1110, 11110, 111110].should.eql total
      done()
    iterate(loader, nexter)(mapper(total))(1, 5)
      .then(assert, done).end()

  it "fails in loader on exception", (done) ->
    loaderWithFail = failAt(111, loader)
    shouldHaveFailed = -> done(new Error("should have failed"))
    assert = (err) ->
      err.message.should.eql "fail at 111"
      done()
    iterate(loaderWithFail, nexter)(mapper([]))(1, 5)
     .then(shouldHaveFailed, assert).end()
