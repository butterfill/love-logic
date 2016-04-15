chai = require('chai')
assert = chai.assert
expect = chai.expect

fol = require '../forallxFOL'
util = require '../../util'
dialectManager = require('../../dialect_manager/dialectManager')

symbols = dialectManager.getSymbols('forallx')

describe 'forallxFOL', ->
  describe 'parse', ->

  describe 'parse (predicates)', ->
    it 'should parse  "Fa"', ->
      res = fol.parse("Fa")
      assert.equal res.type, "predicate"
      assert.equal res.name, "F"
      assert.equal res.termlist.length, 1
      assert.equal res.termlist[0].type, 'name' 
      assert.equal res.termlist[0].name, 'a' 
      
    it 'should parse  "F1a"', ->
      res = fol.parse("F1a")
      assert.equal res.type, "predicate"
      assert.equal res.name, "F1"
      assert.equal res.termlist.length, 1
      assert.equal res.termlist[0].type, 'name' 
      assert.equal res.termlist[0].name, 'a' 
      
    it 'should parse "F1a", string it and parse it back', ->
      parsed = fol.parse("F1a")
      strung = util.expressionToString(parsed, {symbols:symbols})
      reparsed = fol.parse(strung)
      util.delExtraneousProperties parsed
      util.delExtraneousProperties reparsed
      expect(parsed).to.deep.equal(reparsed)
      
    it 'should parse  "all x Fx"', ->
      res = fol.parse("all x Fx")
      expect( res.boundVariable? ).to.be.true
