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
    it "produces clones without extraneous properties", ->
      expression = fol.parse("A and B")
      clone = util.cloneExpression expression
      expect(expression.symbol).to.equal('and')
      expect(clone.symbol?).to.be.false
      
  describe 'areIdenticalExpressions', ->
    it "says that true and false (the values, not the awFOL expressions) are not identical", ->
      expect( util.areIdenticalExpressions(true, false) ).to.be.false
    it "says that 'true' and 'false' are not identical phrases", ->
      expect( util.areIdenticalExpressions(fol.parse("true"), fol.parse("false"))).to.be.false
    it "says that 'true' and 'true' are not identical phrases", ->
      expect( util.areIdenticalExpressions(fol.parse("true"), fol.parse("true"))).to.be.true
    it "says that 'false' and 'false' are not identical phrases", ->
      expect( util.areIdenticalExpressions(fol.parse("false"), fol.parse("false"))).to.be.true
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
    it "says that 'a' and 'a' are identical expressions", ->
      e1 = fol.parse('F(a)').termlist[0]
      e2 = fol.parse('F(a)').termlist[0]
      expect( util.areIdenticalExpressions(e1,e2) ).to.be.true
    it "does not equate expressions with different boxes", ->
      e1 = fol.parse('[a] F(a)')
      e2 = fol.parse('[b] F(a)')
      expect( util.areIdenticalExpressions(e1,e2) ).to.be.false
    it "does not equate expressions with and without boxes", ->
      e1 = fol.parse('[a] F(a)')
      e2 = fol.parse('F(a)')
      expect( util.areIdenticalExpressions(e1,e2) ).to.be.false
    it "does not equate expressions with and without substitutions", ->
      e1 = fol.parse('F(a)[a->b]')
      e2 = fol.parse('F(a)')
      expect( util.areIdenticalExpressions(e1,e2) ).to.be.false
    it "does equate expressions with identical substitutions", ->
      e1 = fol.parse('F(a)[a->b]')
      e2 = fol.parse('F(a)[a->b]')
      expect( util.areIdenticalExpressions(e1,e2) ).to.be.true
    it "does equate not expressions with different right substitutions", ->
      e1 = fol.parse('F(a)[a->b]')
      e2 = fol.parse('F(a)[a->c]')
      expect( util.areIdenticalExpressions(e1,e2) ).to.be.false
    it "does equate not expressions with different left substitutions", ->
      e1 = fol.parse('F(a)[a->b]')
      e2 = fol.parse('F(a)[c->b]')
      expect( util.areIdenticalExpressions(e1,e2) ).to.be.false
    it "does not apply substitutions before comparing expressions", ->
      e1 = fol.parse('F(a)')
      e2 = fol.parse('F(b)[b->a]')
      expect( util.areIdenticalExpressions(e1,e2) ).to.be.false
    it "does not apply propositional substitutions before comparing expressions", ->
      e1 = fol.parse('A')
      e2 = fol.parse('B[B->A]')
      expect( util.areIdenticalExpressions(e1,e2) ).to.be.false
    it "says that 'a' and 'b' are not identical expressions", ->
      e1 = fol.parse('F(a)').termlist[0]
      e2 = fol.parse('F(b)').termlist[0]
      expect( util.areIdenticalExpressions(e1,e2) ).to.be.false
    it "says that 'x' and 'x' are not identical expressions", ->
      e1 = fol.parse('F(x)').termlist[0]
      e2 = fol.parse('F(x)').termlist[0]
      expect( util.areIdenticalExpressions(e1,e2) ).to.be.true
    it "says that 'x' and 'y' are not identical expressions", ->
      e1 = fol.parse('F(x)').termlist[0]
      e2 = fol.parse('F(y)').termlist[0]
      expect( util.areIdenticalExpressions(e1,e2) ).to.be.false
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
    it "works for a tricky case", ->
      e1 = fol.parse "B and (exists x A)"
      e2 = fol.parse "B and (exists x A)"
      expect( util.areIdenticalExpressions(e1,e2) ).to.be.true

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

      describe "for expressions with `null`", ->
        it "can do `ψ[α->null]`", ->
          expression1 = fol.parse 'ψ[α->null]'
          string = util.expressionToString expression1
          expression2 = fol.parse string
          expect(util.areIdenticalExpressions(expression1, expression2)).to.be.true
        it "can do `A[ψ->null]`", ->
          expression1 = fol.parse 'A[ψ->null]'
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


    
  describe "walkMutate", ->
    it "turns A to B", ->
      e = fol.parse "A"
      mutate = (e) ->
        if e?.letter? and e.letter is 'A'
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
    
    it "turns A to D (complex case, swapped sides)", ->
      e = fol.parse "(B and A) or (C and A)"
      mutate = (e) ->
        if e.letter? and e.letter is 'A'
          e.letter = 'D'
        return e
      result = util.walkMutate e, mutate
      console.log util.expressionToString(result)
      expect(result.left.right.letter).to.equal('D')
      expect(result.right.right.letter).to.equal('D')
    
    it "turns a to c", ->
      e = fol.parse "a=b"
      mutate = (e) ->
        if e.name? and e.name is 'a'
          e.name = 'c'
        return e
      result = util.walkMutate e, mutate
      console.log util.expressionToString(result)
      expect(result.termlist[0].name).to.equal('c')
    
    it "turns a to c (swapped sides)", ->
      e = fol.parse "b=a"
      mutate = (e) ->
        if e.name? and e.name is 'a'
          e.name = 'c'
        return e
      result = util.walkMutate e, mutate
      console.log util.expressionToString(result)
      expect(result.termlist[1].name).to.equal('c')
    
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

    it "turns a to c (in the left-side of a substitution)", ->
      e = fol.parse "A[a->b]"
      mutate = (e) ->
        if e.name? and e.name is 'a'
          e.name = 'c'
        return e
      result = util.walkMutate e, mutate
      # console.log "#{JSON.stringify result,null,4}"
      console.log util.expressionToString(result)
      expect(result.substitutions[0].from.name).to.equal('c')

    it "turns a to c (in the right-side of a substitution)", ->
      e = fol.parse "A[b->a]"
      mutate = (e) ->
        if e.name? and e.name is 'a'
          e.name = 'c'
        return e
      result = util.walkMutate e, mutate
      # console.log "#{JSON.stringify result,null,4}"
      console.log util.expressionToString(result)
      expect(result.substitutions[0].to.name).to.equal('c')

    it "turns A to B (in the left-side of a substitution)", ->
      e = fol.parse "C[A->B]"
      mutate = (e) ->
        if e.letter? and e.letter is 'A'
          e.letter = 'B'
        return e
      result = util.walkMutate e, mutate
      # console.log "#{JSON.stringify result,null,4}"
      console.log util.expressionToString(result)
      expect(result.substitutions[0].from.letter).to.equal('B')

    it "turns A to B (in the right-side of a substitution)", ->
      e = fol.parse "C[B->A]"
      mutate = (e) ->
        if e.letter? and e.letter is 'A'
          e.letter = 'B'
        return e
      result = util.walkMutate e, mutate
      # console.log "#{JSON.stringify result,null,4}"
      console.log util.expressionToString(result)
      expect(result.substitutions[0].to.letter).to.equal('B')

  describe "walk", ->
    describe "gives information about where you are", ->
      it "tells you when you are in a box", ->
        e = fol.parse "[a](F(b))"
        fn = (e) ->
          if e?.name? and e.name is 'a'
            if not fn._inBox?
              throw new Error "fail"
          if e.name? and e.name is 'b'
            if fn._inBox?
              throw new Error "fail because false positive"
        util.walk e, fn
          
      it "tells you when you are in a bound variable", ->
        e = fol.parse "A(y) and a=y and all x F(y) and exists x F(y)"
        fn = (e) ->
          if e?.name? and e.name is 'x'
            if not fn._inBoundVariable?
              throw new Error "fail"
          if e.name? and e.name is 'y'
            if fn._inBoundVariable?
              throw new Error "fail because false positive"
        util.walk e, fn

      it "tells you when you are in a substitution", ->
        e = fol.parse "(A and a=b)[C->C and C,c->c]"
        fn = (e) ->
          if (e?.name? and e.name is 'c') or (e?.letter? and e.letter is 'C')
            if not fn._inSub?
              throw new Error "fail"
          if (e.name? and e.name is 'a') or (e.letter? and e.letter is 'A')
            if fn._inSub?
              throw new Error "fail because false positive"
        util.walk e, fn
      it "doesn't choke when 'null' features in substitutions (as in `ψ[α->null]`)", ->
        e = fol.parse 'ψ[α->null]'
        fn = (e) ->
          return util.expressionToString(e)
        util.walk e, fn
        
  describe ".listMetaVariableNames", ->
    it "lists expression_variables in an expression", ->
      e = fol.parse "φ"
      result = util.listMetaVariableNames e
      expect( 'φ' in result.inExpression ).to.be.true
      expect(result.inExpression.length).to.equal(1)
    it "lists several expression_variables in an expression", ->
      e = fol.parse "ψ and (A and φ)"
      result = util.listMetaVariableNames e
      expect( 'φ' in result.inExpression ).to.be.true
      expect( 'ψ' in result.inExpression ).to.be.true
      expect(result.inExpression.length).to.equal(2)
    it "lists term_metavariables in an expression", ->
      e = fol.parse "F(α)"
      result = util.listMetaVariableNames e
      expect(result.inExpression[0]).to.equal('α')
      expect(result.inExpression.length).to.equal(1)
    it "lists term_metavariables in a box", ->
      e = fol.parse "[τ]F(α)"
      result = util.listMetaVariableNames e
      expect(result.inBox[0]).to.equal('τ')
      expect(result.inBox.length).to.equal(1)
    it "lists metavariables in the left of a substitution", ->
      e = fol.parse "F(x)[τ->α]"
      result = util.listMetaVariableNames e
      expect(result.inSub.left[0]).to.equal('τ')
      expect(result.inSub.left.length).to.equal(1)
    it "lists metavariables in the right of a substitution", ->
      e = fol.parse "F(x)[τ->α]"
      result = util.listMetaVariableNames e
      expect(result.inSub.right[0]).to.equal('α')
      expect(result.inSub.right.length).to.equal(1)
    it "lists expression_variables in the right of a substitution", ->
      e = fol.parse "A[A->ψ and φ]"
      result = util.listMetaVariableNames e
      expect( 'φ' in result.inSub.right ).to.be.true
      expect( 'ψ' in result.inSub.right ).to.be.true
      expect(result.inSub.right.length).to.equal(2)
                