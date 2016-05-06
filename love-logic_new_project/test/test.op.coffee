_ = require 'lodash'

chai = require('chai')
assert = chai.assert
expect = chai.expect
should = chai.should()

util = require '../util'
fol = require '../fol'
op = require '../op'

describe "`op`", ->
  it "`negate` works", ->
    e = fol.parse 'a=a'
    res = op.negate e
    fol._decorate(res)
    (res.toString({replaceSymbols:true})).should.equal( fol.parse('not a=a').toString({replaceSymbols:true}) )

  it "`conjoin` works", ->
    l = fol.parse 'F(a)'
    r = fol.parse 'G(b)'
    res = op.conjoin l,r
    fol._decorate(res)
    (res.toString({replaceSymbols:true})).should.equal( fol.parse('F(a) and G(b)').toString({replaceSymbols:true}) )