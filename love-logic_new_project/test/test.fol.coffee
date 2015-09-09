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
    it "adds `.delExtraneousProperties`", ->
      e = fol.parse 'all x (F(x) arrow G(x))'
      e2 = fol.parse 'all x (F(x) arrow G(x))'
      (x.delExtraneousProperties() for x in [e,e2])
      expect(e).to.deep.equal(e2)
    it "adds `.clone`", ->
      e = fol.parse 'exists x F(x)'
      e2 = e.clone()
      (x.delExtraneousProperties?() for x in [e,e2])
      expect(e).not.to.equal(e2)
      expect(e).to.deep.equal(e2)
      
    it "works when there are multiple expressions", ->
      text = 'A and B'
      text2 = 'C or D'
      e = fol.parse text
      e2 = fol.parse text2
      result = e.toString()
      result2 = e2.toString()
      expect(result).to.equal(text)
      expect(result2).to.equal(text2)

    it "adds `.findMatches`"
    it "adds `.applySubstitutions`"    