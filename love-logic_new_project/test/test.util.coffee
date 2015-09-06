_ = require 'lodash'

chai = require('chai')
assert = chai.assert
expect = chai.expect
substitute = require('../substitute')
fol = require '../parser/awFOL' 
util = require('../util')


describe 'util', ->
  describe 'delExtraneousProperties', ->
    it "does not thrown an error with 'A and B'", ->
      util.delExtraneousProperties fol.parse("A and B")
    it "does not thrown an error with 'Fish(a) and LeftOf(a,b)'", ->
      util.delExtraneousProperties fol.parse("Fish(a) and LeftOf(a,b)")      
    it "removes extraneous properties of all constituents of an expression (this is a test of `util.walk`)'", ->
      e = fol.parse 'A and (B and C)'
      util.delExtraneousProperties e
      expect(e.location?).to.be.false
      expect(e.right.location?).to.be.false
      expect(e.right.left.location?).to.be.false
      expect(e.right.right.location?).to.be.false
    it "removes extraneous properties of terms and boundVariables'", ->
      e = fol.parse 'all x (F(x,a))'
      util.delExtraneousProperties e
      expect(e.location?).to.be.false
      expect(e.boundVariable.location?).to.be.false
      expect(e.left.location?).to.be.false
      expect(e.left.termlist[0].location?).to.be.false
      expect(e.left.termlist[1].location?).to.be.false
    it "modifies expressions in place", ->
      e = fol.parse("A and B")
      expect(e.location?).to.be.true
      util.delExtraneousProperties e
      expect(e.location?).to.be.false
    it "deletes extraneous properties from within a box", ->
      e = fol.parse '[a] F(x)'
      util.delExtraneousProperties e
      expect(e.box.term.location?).to.be.false
    it "deletes extraneous properties from within substitutions (sentences)", ->
      e = fol.parse 'A[A->B]'
      expect(e.substitutions[0].to.location?).to.be.true
      expect(e.substitutions[0].from.location?).to.be.true
      util.delExtraneousProperties e
      expect(e.substitutions[0].to.location?).to.be.false
      expect(e.substitutions[0].from.location?).to.be.false
    it "deletes extraneous properties from within substitutions (terms)", ->
      e = fol.parse 'F(a)[a->b]'
      expect(e.substitutions[0].to.location?).to.be.true
      expect(e.substitutions[0].from.location?).to.be.true
      util.delExtraneousProperties e
      expect(e.substitutions[0].to.location?).to.be.false
      expect(e.substitutions[0].from.location?).to.be.false
      
  describe 'cloneExpression', ->
    it "clones an expression of awFOL", ->
      expression = fol.parse("A and B")
      clone = util.cloneExpression expression
      expect(expression).to.not.equal(clone)
      # Note that we can't meaningfully use `util.areIdenticalExpressions` here 
      # because that depends on cloneExpression
      expect( expression.type ).to.equal(clone.type)
      expect( expression.left.type ).to.equal(clone.left.type)
      expect( expression.right.letter ).to.equal(clone.right.letter)
      
  describe 'areIdenticalExpressions', ->
    it "says that 'A & B' and 'A and B' are identical phrases", ->
      expect( util.areIdenticalExpressions(fol.parse("A & B"), fol.parse("A and B"))).to.be.true
    it "says that 'A & B' and 'B & A' are not identical phrases", ->
      expect( util.areIdenticalExpressions(fol.parse("A & B"), fol.parse("B & A"))).to.be.false
    it "says that 'all x (F(x) arrow G(x))' and '(all x)(F(x) arrow G(x))' are identical phrases", ->
      expect( util.areIdenticalExpressions(fol.parse("all x (F(x) arrow G(x))"), fol.parse("(all x)(F(x) arrow G(x))"))).to.be.true
    it "says that 'all x (F(x) arrow G(x))' and 'all y (F(y) arrow G(y))' are not identical phrases", ->
      expect( util.areIdenticalExpressions(fol.parse("all x (F(x) arrow G(x))"), fol.parse("all y (F(y) arrow G(y))"))).to.be.false
    it "says that 'all x (F(x) arrow G(x))' and 'all x (G(x) arrow F(x))' are not identical phrases", ->
      expect( util.areIdenticalExpressions(fol.parse("all x (F(x) arrow G(x))"), fol.parse("all x (G(x) arrow F(x))"))).to.be.false
    it "works when either parameter is null", ->
      expect( util.areIdenticalExpressions(null, fol.parse("A and B")) ).to.be.false
      expect( util.areIdenticalExpressions(fol.parse("A and B"), null) ).to.be.false
    it "works when the parameters are strings", ->
      expect( util.areIdenticalExpressions("yes", "yno") ).to.be.false
      expect( util.areIdenticalExpressions("yes", "yes") ).to.be.true
    it "works when the parameters are numbers", ->
      expect( util.areIdenticalExpressions(1, 2) ).to.be.false
      expect( util.areIdenticalExpressions(1, 1) ).to.be.true
    it "works when the parameters are lists", ->
      expect( util.areIdenticalExpressions([1], [2]) ).to.be.false
      expect( util.areIdenticalExpressions([1], [1]) ).to.be.true
    it "works when the parameters are lists", ->

  describe 'expressionToString', ->
    it "does not throw", ->
      expression = fol.parse 'not (not not A & B)'
      console.log "sentence =  #{util.expressionToString expression}"
    describe "parses into what it was", ->
      it "works for the sentence 'contradiction'", ->
        expression1 = fol.parse 'contradiction'
        string = util.expressionToString expression1
        expression2 = fol.parse string
        expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
      it "works for the sentence 'contradiction' even after `util.delExtraneousProperties` (which gets rid of `.symbol`)", ->
        expression1 = fol.parse 'contradiction'
        util.delExtraneousProperties expression1
        string = util.expressionToString expression1
        expression2 = fol.parse string
        expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
      it "a simple case", ->
        expression1 = fol.parse 'not (not not A & B)'
        string = util.expressionToString expression1
        expression2 = fol.parse string
        expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
      it "sentences with predicates", ->
        expression1 = fol.parse 'F(x) and R(a,y)'
        string = util.expressionToString expression1
        expression2 = fol.parse string
        expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
      it "sentences with identity", ->
        expression1 = fol.parse 'not x=y or (a=b and x=a)'
        string = util.expressionToString expression1
        expression2 = fol.parse string
        expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
      it "sentences with quantifiers", ->
        expression1 = fol.parse 'all x some y (F(x) and R(a,y))'
        string = util.expressionToString expression1
        expression2 = fol.parse string
        expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
      it "sentences with `expression_variable`s", ->
        expression1 = fol.parse 'A or not (φ ↔ ψ)'
        string = util.expressionToString expression1
        expression2 = fol.parse string
        expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
      it "sentences with `term_metavariable`s", ->
        expression1 = fol.parse 'all τ some y (F(τ) and R(a,y))'
        string = util.expressionToString expression1
        expression2 = fol.parse string
        expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
      it "sentences with everything", ->
        expression1 = fol.parse 'all τ some y (F(τ) and R(a,y) and P and φ and a=x and not τ=y)'
        string = util.expressionToString expression1
        expression2 = fol.parse string
        expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
      it "sentences with everything and no extraneous properties", ->
        expression1 = fol.parse 'all τ some y (F(τ) and R(a,y) and P and φ and a=x and not τ=y)'
      
        # `util.delExtraneousProperties` will remove information about the symbols used 
        # in the original string (the input to `fol.parse`).
        # So this test ensures that `util.expressionToString` is providing  ok replacements.
        util.delExtraneousProperties expression1
      
        string = util.expressionToString expression1
        expression2 = fol.parse string
        expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
        
      it "sentences with boxes", ->
        expression1 = fol.parse '[a] F(x)'
        string = util.expressionToString expression1
        expression2 = fol.parse string
        expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
      it "just a box boxes", ->
        expression1 = fol.parse '[a]'
        string = util.expressionToString expression1
        expression2 = fol.parse string
        expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true

      describe 'for expressions with substitutions', ->
        it "copes with single substitutions (terms)", ->
          expression1 = fol.parse 'F(x) [x->a]'
          string = util.expressionToString expression1
          expression2 = fol.parse string
          expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
        it "copes with single substitutions (sentence variables)", ->
          expression1 = fol.parse 'A [A->B and C]'
          string = util.expressionToString expression1
          expression2 = fol.parse string
          expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
        it "works with complex expressions", ->
          expression1 = fol.parse '(φ and φ) [φ->B and C]'
          string = util.expressionToString expression1
          expression2 = fol.parse string
          expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
        it "works with inner substitutions", ->
          expression1 = fol.parse '(φ [φ->B and C]) and φ'
          string = util.expressionToString expression1
          expression2 = fol.parse string
          expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
        it "works with nested substitutions", ->
          expression1 = fol.parse 'A [A->B[B->C]]'
          string = util.expressionToString expression1
          expression2 = fol.parse string
          expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
          

  describe 'sameElementsDeep', ->
    it "ignores order", ->
      list1 = [{a:1}, {b:2}, {c:3}]
      list2 = [ {b:2}, {c:3}, {a:1}]
      result = util.sameElementsDeep list1, list2
      expect(result).to.be.true

    it "fails to match different lists", ->
      list1 = [{a:1}, {b:2}, {c:3}, {d:4}]
      list2 = [{a:2}, {b:2}, {c:3}, {d:4}]
      result = util.sameElementsDeep list1, list2
      expect(result).to.be.false
      # check reverse parameters
      result2 = util.sameElementsDeep list2, list1
      expect(result2).to.be.false

    it "fails to match lists of different lengths", ->
      list1 = [{a:1}, {b:2}, {c:3}, {d:4}]
      list2 = [ list1[1], list1[2]]
      result = util.sameElementsDeep list1, list2
      expect(result).to.be.false
      # check reverse parameters
      result2 = util.sameElementsDeep list2, list1
      expect(result2).to.be.false

    it "works with lists containing duplicates", ->
      list1 = [{a:1}, {b:2}, {c:3}]
      list2 = [{b:2}, {c:3}, {a:1}]
      list1.push list1[0]
      list2.push list1[0]
      result = util.sameElementsDeep list1, list2
      expect(result).to.be.true
      
    it "works with FOL expressions", ->
      list1 = [fol.parse("P"), fol.parse("all x F(x)"), (fol.parse("F(x)")).termlist[0]]
      list2 = [ list1[1], list1[2], list1[0]]
      result = util.sameElementsDeep list1, list2
      expect(result).to.be.true


  describe "exhaust", ->
    it "removes all elements from a simple list", ->
      fn = (list) -> 
        list.pop()
        return list
      theList = [1,2,3,4]
      result = util.exhaust(theList, fn, _.isEqual)
      expect(result).to.deep.equal([])
    
    it "does not modify `expression` in place", ->
      fn = (list) -> 
        list.pop()
        return list
      theList = ['1','2','3','4']
      result = util.exhaust(theList, fn, _.isEqual)
      expect(theList).to.deep.equal(['1','2','3','4'])
    
    it "works with a function that does nothing", ->
      fn = (list) -> return list
      theList = [1,2,3,4]
      result = util.exhaust(theList, fn, _.isEqual)
      expect(result).to.deep.equal(theList)
      

  describe "atomicExpressionComparator", ->
    it "puts sentence letters before predicates",->
      result = util.atomicExpressionComparator fol.parse('A'), fol.parse('A(x)')
      expect(result).to.equal(-1)

    it "puts truth values (true, false) first",->
      result = util.atomicExpressionComparator fol.parse('true'), fol.parse('A')
      expect(result).to.equal(-1)
    
    it "sorts identity statements",->
      result = util.atomicExpressionComparator fol.parse('d=c'), fol.parse('d=b')
      expect(result).to.equal(1)
    
    it "sorts identity statements (irrespective of order)",->
      result = util.atomicExpressionComparator fol.parse('d=a'), fol.parse('c=b')
      expect(result).to.equal(-1)

    it "puts negations just after the thing negated", ->
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
        
    it "sorts a mixed list of atomic expressions correctly", ->
      list = ['F(x)','A','b=b','B2','B1','not A','true','a=b']
      list = (fol.parse(e) for e in list)
      list = list.sort(util.atomicExpressionComparator)
      # console.log "list #{(util.expressionToString(e) for e in list)}"
      expectedResult = ['true','A','not A','B1','B2','F(x)','a=b','b=b']
      expectedResult = (fol.parse(e) for e in expectedResult)
      for expected, i in expectedResult
        expect( util.areIdenticalExpressions(expected, list[i]) ).to.be.true


  describe "addParents", ->
    it "adds parents to children", ->
      e = fol.parse "A and B"
      util.delExtraneousProperties e
      util.addParents e
      expect(e.left.parent).to.equal(e)
      expect(e.right.parent).to.equal(e)
    it "adds parents to children (more complex example)", ->
      e = fol.parse "all y some x (R(x,y) and F(x))"
      util.delExtraneousProperties e
      util.addParents e
      expect(e.left.left.parent).to.equal(e.left)
      expect(e.left.left.left.parent).to.equal(e.left.left)
    
  describe "walkMutate", ->
    it "turns A to B", ->
      e = fol.parse "A"
      mutate = (e) ->
        if e.letter? and e.letter is 'A'
          e.letter = 'B'
        return e
      result = util.walkMutate e, mutate
      console.log util.expressionToString(result)
      expect(result.letter).to.equal('B')
    
    it "turns A to D (complex case)", ->
      e = fol.parse "(A and B) or (A and C)"
      mutate = (e) ->
        if e.letter? and e.letter is 'A'
          e.letter = 'D'
        return e
      result = util.walkMutate e, mutate
      console.log util.expressionToString(result)
      expect(result.left.left.letter).to.equal('D')
      expect(result.right.left.letter).to.equal('D')
    
    it "turns a to c", ->
      e = fol.parse "a=b"
      mutate = (e) ->
        if e.name? and e.name is 'a'
          e.name = 'c'
        return e
      result = util.walkMutate e, mutate
      console.log util.expressionToString(result)
      expect(result.termlist[0].name).to.equal('c')
    
    it "turns a to c (complex case)", ->
      e = fol.parse "(a=b and B)"
      mutate = (e) ->
        if e.name? and e.name is 'a'
          e.name = 'c'
        return e
      result = util.walkMutate e, mutate
      # console.log "#{JSON.stringify result,null,4}"
      console.log util.expressionToString(result)
      expect(result.left.termlist[0].name).to.equal('c')
    
