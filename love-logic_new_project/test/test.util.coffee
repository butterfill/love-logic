_ = require 'lodash'

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
      
  describe 'cloneExpression', ->
    it "should clone an expression of yAFOL", ->
      expression = fol.parse("A and B")
      clone = util.cloneExpression expression
      expect(expression).to.not.equal(clone)
      # Note that we can't meaningfully use `util.areIdenticalExpressions` here 
      # because that depends on cloneExpression
      expect( expression.type ).to.equal(clone.type)
      expect( expression.left.type ).to.equal(clone.left.type)
      expect( expression.right.letter ).to.equal(clone.right.letter)
      
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
    it "should work when either parameter is null", ->
      expect( util.areIdenticalExpressions(null, fol.parse("A and B")) ).to.be.false
      expect( util.areIdenticalExpressions(fol.parse("A and B"), null) ).to.be.false
    it "should work when the parameters are strings", ->
      expect( util.areIdenticalExpressions("yes", "yno") ).to.be.false
      expect( util.areIdenticalExpressions("yes", "yes") ).to.be.true
    it "should work when the parameters are numbers", ->
      expect( util.areIdenticalExpressions(1, 2) ).to.be.false
      expect( util.areIdenticalExpressions(1, 1) ).to.be.true
    it "should work when the parameters are lists", ->
      expect( util.areIdenticalExpressions([1], [2]) ).to.be.false
      expect( util.areIdenticalExpressions([1], [1]) ).to.be.true

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

  describe 'sameElementsDeep', ->
    it "should ignore order", ->
      list1 = [{a:1}, {b:2}, {c:3}]
      list2 = [ {b:2}, {c:3}, {a:1}]
      result = util.sameElementsDeep list1, list2
      expect(result).to.be.true

    it "should fail to match different lists", ->
      list1 = [{a:1}, {b:2}, {c:3}, {d:4}]
      list2 = [{a:2}, {b:2}, {c:3}, {d:4}]
      result = util.sameElementsDeep list1, list2
      expect(result).to.be.false
      # check reverse parameters
      result2 = util.sameElementsDeep list2, list1
      expect(result2).to.be.false

    it "should fail to match lists of different lengths", ->
      list1 = [{a:1}, {b:2}, {c:3}, {d:4}]
      list2 = [ list1[1], list1[2]]
      result = util.sameElementsDeep list1, list2
      expect(result).to.be.false
      # check reverse parameters
      result2 = util.sameElementsDeep list2, list1
      expect(result2).to.be.false

    it "should work with lists containing duplicates", ->
      list1 = [{a:1}, {b:2}, {c:3}]
      list2 = [{b:2}, {c:3}, {a:1}]
      list1.push list1[0]
      list2.push list1[0]
      result = util.sameElementsDeep list1, list2
      expect(result).to.be.true
      
    it "should work with FOL expressions", ->
      list1 = [fol.parse("P"), fol.parse("all x F(x)"), (fol.parse("F(x)")).termlist[0]]
      list2 = [ list1[1], list1[2], list1[0]]
      result = util.sameElementsDeep list1, list2
      expect(result).to.be.true

  describe "exhaust", ->
    it "should remove all elements from a simple list", ->
      fn = (list) -> 
        list.pop()
        return list
      theList = [1,2,3,4]
      result = util.exhaust(theList, fn, _.isEqual)
      expect(result).to.deep.equal([])
    
    it "should remove not modify `expression` in place", ->
      fn = (list) -> 
        list.pop()
        return list
      theList = [1,2,3,4]
      result = util.exhaust(theList, fn, _.isEqual)
      expect(theList).to.deep.equal([1,2,3,4])
    
    it "should work with a function that does nothing", ->
      fn = (list) -> return list
      theList = [1,2,3,4]
      result = util.exhaust(theList, fn, _.isEqual)
      expect(result).to.deep.equal(theList)
      

describe "atomicExpressionComparator", ->
  it "should put sentence letters before predicates",->
    result = util.atomicExpressionComparator fol.parse('A'), fol.parse('A(x)')
    expect(result).to.equal(-1)
    
  it "should sort identity statements",->
    result = util.atomicExpressionComparator fol.parse('d=c'), fol.parse('d=b')
    expect(result).to.equal(1)

  it "should sort identity statements (irrespective of order)",->
    result = util.atomicExpressionComparator fol.parse('d=a'), fol.parse('c=b')
    expect(result).to.equal(-1)
    
  it "should sort a mixed list of atomic expressions correctly", ->
    list = ['F(x)','A','b=b','B2','B1','not A','a=b']
    list = (fol.parse(e) for e in list)
    list = list.sort(util.atomicExpressionComparator)
    # console.log "list #{(util.expressionToString(e) for e in list)}"
    expectedResult = ['A','B1','B2','F(x)','a=b','b=b','not A']
    expectedResult = (fol.parse(e) for e in expectedResult)
    for expected, i in expectedResult
      expect( util.areIdenticalExpressions(expected, list[i]) ).to.be.true
    
    
    
    
    
