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
    it "should remove extraneous properties of all constituents of an expression (this is a test of `util.walk`)'", ->
      e = fol.parse 'A and (B and C)'
      util.delExtraneousProperties e
      expect(e.location?).to.be.false
      expect(e.right.location?).to.be.false
      expect(e.right.left.location?).to.be.false
      expect(e.right.right.location?).to.be.false
    it "should remove extraneous properties of terms and boundVariables'", ->
      e = fol.parse 'all x (F(x,a))'
      util.delExtraneousProperties e
      expect(e.location?).to.be.false
      expect(e.boundVariable.location?).to.be.false
      expect(e.left.location?).to.be.false
      expect(e.left.termlist[0].location?).to.be.false
      expect(e.left.termlist[1].location?).to.be.false
    it "should modify expressions in place", ->
      e = fol.parse("A and B")
      expect(e.location?).to.be.true
      util.delExtraneousProperties e
      expect(e.location?).to.be.false
      
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
    it "should parse into what it was: sentences with predicates", ->
      expression1 = fol.parse 'F(x) and R(a,y)'
      string = util.expressionToString expression1
      expression2 = fol.parse string
      expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
    it "should parse into what it was: sentences with identity", ->
      expression1 = fol.parse 'not x=y or (a=b and x=a)'
      string = util.expressionToString expression1
      expression2 = fol.parse string
      expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
    it "should parse into what it was: sentences with quantifiers", ->
      expression1 = fol.parse 'all x some y (F(x) and R(a,y))'
      string = util.expressionToString expression1
      expression2 = fol.parse string
      expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
    it "should parse into what it was: sentences with `expression_variable`s", ->
      expression1 = fol.parse 'A or not (φ ↔ ψ)'
      string = util.expressionToString expression1
      expression2 = fol.parse string
      expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
    it "should parse into what it was: sentences with `term_metavariable`s", ->
      expression1 = fol.parse 'all τ some y (F(τ) and R(a,y))'
      string = util.expressionToString expression1
      expression2 = fol.parse string
      expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
    it "should parse into what it was: sentences with everything", ->
      expression1 = fol.parse 'all τ some y (F(τ) and R(a,y) and P and φ and a=x and not τ=y)'
      string = util.expressionToString expression1
      expression2 = fol.parse string
      expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
    it "should parse into what it was: sentences with everything and no extraneous properties", ->
      expression1 = fol.parse 'all τ some y (F(τ) and R(a,y) and P and φ and a=x and not τ=y)'
      
      # `util.delExtraneousProperties` will remove information about the symbols used 
      # in the original string (the input to `fol.parse`).
      # So this test ensures that `util.expressionToString` is providing  ok replacements.
      util.delExtraneousProperties expression1
      
      string = util.expressionToString expression1
      expression2 = fol.parse string
      expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true

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
    
    it "should not modify `expression` in place", ->
      fn = (list) -> 
        list.pop()
        return list
      theList = ['1','2','3','4']
      result = util.exhaust(theList, fn, _.isEqual)
      expect(theList).to.deep.equal(['1','2','3','4'])
    
    it "should work with a function that does nothing", ->
      fn = (list) -> return list
      theList = [1,2,3,4]
      result = util.exhaust(theList, fn, _.isEqual)
      expect(result).to.deep.equal(theList)
      

  describe "atomicExpressionComparator", ->
    it "should put sentence letters before predicates",->
      result = util.atomicExpressionComparator fol.parse('A'), fol.parse('A(x)')
      expect(result).to.equal(-1)

    it "should put truth values (true, false) first",->
      result = util.atomicExpressionComparator fol.parse('true'), fol.parse('A')
      expect(result).to.equal(-1)
    
    it "should sort identity statements",->
      result = util.atomicExpressionComparator fol.parse('d=c'), fol.parse('d=b')
      expect(result).to.equal(1)
    
    it "should sort identity statements (irrespective of order)",->
      result = util.atomicExpressionComparator fol.parse('d=a'), fol.parse('c=b')
      expect(result).to.equal(-1)

    it "should put negations just after the thing negated", ->
      list = [
        'F(x)','A'
        'not F(x)','not A'
        'not b=b','not true'
        'b=b','true'
      ]
      list = (fol.parse(e) for e in list)
      list = list.sort(util.atomicExpressionComparator)
      expectedResult = [
        'true', 'not true'
        'A','not A'
        'F(x)','not F(x)'
        'b=b','not b=b'
      ]
      expectedResult = (fol.parse(e) for e in expectedResult)
      for expected, i in expectedResult
        expect( util.areIdenticalExpressions(expected, list[i]) ).to.be.true
        
    it "should sort a mixed list of atomic expressions correctly", ->
      list = ['F(x)','A','b=b','B2','B1','not A','true','a=b']
      list = (fol.parse(e) for e in list)
      list = list.sort(util.atomicExpressionComparator)
      # console.log "list #{(util.expressionToString(e) for e in list)}"
      expectedResult = ['true','A','not A','B1','B2','F(x)','a=b','b=b']
      expectedResult = (fol.parse(e) for e in expectedResult)
      for expected, i in expectedResult
        expect( util.areIdenticalExpressions(expected, list[i]) ).to.be.true


  describe "addParents", ->
    it "should add parents to children", ->
      e = fol.parse "A and B"
      util.delExtraneousProperties e
      util.addParents e
      expect(e.left.parent).to.equal(e)
      expect(e.right.parent).to.equal(e)
    it "should add parents to children (more complex example)", ->
      e = fol.parse "all y some x (R(x,y) and F(x))"
      util.delExtraneousProperties e
      util.addParents e
      expect(e.left.left.parent).to.equal(e.left)
      expect(e.left.left.left.parent).to.equal(e.left.left)
    
    
    
