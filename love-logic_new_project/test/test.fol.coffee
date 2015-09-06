_ = require 'lodash'

chai = require('chai')
assert = chai.assert
expect = chai.expect

fol = require '../fol'

describe "`fol`", ->
  describe "`_decorate`", ->
    it "adds a `.toString` method that works", ->
      text = 'A and B'
      e = fol.parse text
      result = e.toString()
      expect(result).to.equal(text)
    it "adds a `.toString` method to components of an expression", ->
      e = fol.parse 'A and B'
      result = e.right.toString()
      expect(result).to.equal("B")
    it "adds a `.isIdenticalTo` method that works", ->
      e = fol.parse 'A and (B or C)'
      result = e.right.isIdenticalTo fol.parse("B or C")
      expect(result).to.be.true
