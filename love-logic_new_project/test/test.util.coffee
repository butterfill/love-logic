chai = require('chai')
assert = chai.assert
expect = chai.expect
substitute = require('../substitute')
fol = require('../fol')
util = require('../util')


describe 'util', ->
  describe 'delExtraneousProperties', ->
    it "should not thrown an error with 'A and B'", ->
      util.delExtraneousProperties fol.parse("A and B")
    it "should not thrown an error with 'Fish(a) and LeftOf(a,b)'", ->
      util.delExtraneousProperties fol.parse("Fish(a) and LeftOf(a,b)")      
      
  describe 'areIdenticalExpressions', ->
    it "should say that 'A & B' and 'A and B' are identical phrases", ->
      expect( util.areIdenticalExpressions(fol.parse("A & B"), fol.parse("A and B"))).to.be.true
    it "should say that 'A & B' and 'B & A' are not identical phrases", ->
      expect( util.areIdenticalExpressions(fol.parse("A & B"), fol.parse("B & A"))).to.be.false
    it "should say that 'all x (F(x) arrow G(x))' and '(all x)(F(x) arrow G(x))' are identical phrases", ->
      expect( util.areIdenticalExpressions(fol.parse("all x (F(x) arrow G(x))"), fol.parse("(all x)(F(x) arrow G(x))"))).to.be.true
    it "should say that 'all x (F(x) arrow G(x))' and 'all y (F(y) arrow G(y))' are not identical phrases", ->
      expect( util.areIdenticalExpressions(fol.parse("all x (F(x) arrow G(x))"), fol.parse("all y (F(y) arrow G(y))"))).to.be.false
    it "should say that 'all x (F(x) arrow G(x))' and 'all x (G(x) arrow F(x))' are not identical phrases", ->
      expect( util.areIdenticalExpressions(fol.parse("all x (F(x) arrow G(x))"), fol.parse("all x (G(x) arrow F(x))"))).to.be.false

  describe 'expressionToString', ->
    it "should not throw", ->
      expression = fol.parse 'not (not not A & B)'
      console.log "sentence =  #{util.expressionToString expression}"
    it "should parse into what it was (i.e. parse1 is parse2 where string1 -> parse1 -> string2 -> parse2)", ->
      expression1 = fol.parse 'not (not not A & B)'
      string = util.expressionToString expression1
      expression2 = fol.parse string
      expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
    it "should parse into what it was: sentences with predicates"
    it "should parse into what it was: sentences with identity"
    it "should parse into what it was: sentences with quantifiers"
    it "should parse into what it was: sentences with `expression_variable`s"
    it "should parse into what it was: sentences with `term_metavariable`s"
