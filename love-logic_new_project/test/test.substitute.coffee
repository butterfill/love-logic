_ = require 'lodash'

chai = require('chai')
assert = chai.assert
expect = chai.expect
substitute = require('../substitute')
fol = require '../parser/awFOL'
util = require('../util')
match = require '../match'
normalForm = require('../normal_form')

# some handy FOL objects (defining these presupposes that some of the tests below work ...)
PROP_A = fol.parse "A"
PROP_B = fol.parse "B"
PROP_C = fol.parse "C"
NAME_A = fol.parse("F(a)").termlist[0]   #i.e. {type='name', name='a', ...}
NAME_B = fol.parse("F(b)").termlist[0]
NAME_C = fol.parse("F(c)").termlist[0]
VARIABLE_X = fol.parse("F(x)").termlist[0]
TERM_METAVARIABLE_T = fol.parse("F(τ)").termlist[0]
(util.delExtraneousProperties(x) for x in [PROP_A, PROP_B, PROP_C, NAME_A, NAME_B, NAME_C, VARIABLE_X,TERM_METAVARIABLE_T])

describe 'substitute', ->

  describe 'replace (replaces one expression or term with another)', ->    
    it "helps with testing whether a=b, F(a) therefore F(b) is ok", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      matches = match.find expression1, pattern
      expression2 = fol.parse 'F(a)'
      result = substitute.replace expression2, {from:matches.α, to:matches.β}
      expression3 = fol.parse 'F(b)'
      expect(util.areIdenticalExpressions(result,expression3)).to.be.true
      
    it "helps with testing whether a=b, F(a) therefore G(b) is ok", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      matches = match.find expression1, pattern
      expression2 = fol.parse 'F(a)'
      result = substitute.replace expression2, {from:matches.α, to:matches.β}
      expression3 = fol.parse 'G(b)'
      expect(util.areIdenticalExpressions(result,expression3)).to.be.false
      
    it "helps with testing whether a=b, F(b) therefore F(a) is ok", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      matches = match.find expression1, pattern
      expression2 = fol.parse 'F(b)'
      result = substitute.replace expression2, {from:matches.α, to:matches.β}
      expression3 = fol.parse 'F(a)'
      expect(util.areIdenticalExpressions(result,expression3)).to.be.false
    
    it "allows us to replace a variable with a `term_metavariable`", ->
      expression = fol.parse "Loves(x,a)"
      whatToReplace = 
        from : VARIABLE_X
        to : TERM_METAVARIABLE_T
      result = substitute.replace expression, whatToReplace
      expectedResult = fol.parse "Loves(τ,a)"
      expect( util.areIdenticalExpressions(result,expectedResult) ).to.be.true
    
    it "replaces all instances of a variable with a `term_metavariable`", ->
      expression = fol.parse "Loves(x,a) and F(x) arrow G(x)"
      whatToReplace = 
        from : VARIABLE_X
        to : TERM_METAVARIABLE_T
      result = substitute.replace expression, whatToReplace
      expectedResult = fol.parse "Loves(τ,a) and F(τ) arrow G(τ)"
      console.log "#{util.expressionToString result}"
      expect( util.areIdenticalExpressions(result, expectedResult) ).to.be.true

    it "allows us to tell whether 'F(a)' is an instance of 'all x F(x)'", ->
      expression = fol.parse "all x F(x)"
      boundVariable = expression.boundVariable
      expressionMinusQuantifier = expression.left
      whatToReplace = 
        from : boundVariable
        to : TERM_METAVARIABLE_T
      thePattern = substitute.replace expressionMinusQuantifier, whatToReplace
      aCandidateInstance = fol.parse "F(a)"
      theMatch = match.find aCandidateInstance, thePattern
      expect(theMatch).not.to.be.false
      
    it "allows us to tell whether 'G(a)' is an instance of 'all x F(x)'", ->
      expression = fol.parse "all x F(x)"
      boundVariable = expression.boundVariable
      expressionMinusQuantifier = expression.left
      whatToReplace = 
        from : boundVariable
        to : TERM_METAVARIABLE_T
      thePattern = substitute.replace expressionMinusQuantifier, whatToReplace
      aCandidateInstance = fol.parse "G(a)"
      theMatch = match.find aCandidateInstance, thePattern
      expect(theMatch).to.be.false
      
    it "allows us to tell whether 'F(b) and G(b)' is an instance of 'all y (F(y) and G(y))'", ->
      expression = fol.parse "all y (F(y) & G(y))"
      boundVariable = expression.boundVariable
      expressionMinusQuantifier = expression.left
      whatToReplace = 
        from : boundVariable
        to : TERM_METAVARIABLE_T
      thePattern = substitute.replace expressionMinusQuantifier, whatToReplace
      aCandidateInstance = fol.parse "F(b) & G(b)"
      theMatch = match.find aCandidateInstance, thePattern
      expect(theMatch).not.to.be.false
      
    it "allows us to tell whether 'F(a) and G(b)' is an instance of 'all y (F(y) and G(y))'", ->
      expression = fol.parse "all y (F(y) & G(y))"
      boundVariable = expression.boundVariable
      expressionMinusQuantifier = expression.left
      whatToReplace = 
        from : boundVariable
        to : TERM_METAVARIABLE_T
      thePattern = substitute.replace expressionMinusQuantifier, whatToReplace
      aCandidateInstance = fol.parse "F(a) & G(b)"
      theMatch = match.find aCandidateInstance, thePattern
      expect(theMatch).to.be.false
    
    it "replaces things in the box (as in '[a]F(a)')", ->
      expression = fol.parse "[a]F(a)"
      whatToReplace = 
        from : NAME_A
        to : NAME_B
      result = substitute.replace expression, whatToReplace
      expect(result.box.term.name).to.equal('b')
      expect(result.termlist[0].name).to.equal('b')
      
    it "replaces `term_metavariable`s in the box (as in '[τ]F(a)')", ->
      expression = fol.parse "[τ]F(a)"
      whatToReplace = 
        from : TERM_METAVARIABLE_T
        to : NAME_A
      result = substitute.replace expression, whatToReplace
      expect(result.box.term.name).to.equal('a')

    it "allows us to get from A to B", ->
      expression = fol.parse "A"
      whatToReplace =
        from : fol.parse "A"
        to : fol.parse "B"
      result = substitute.replace expression, whatToReplace
      expect(result.letter).to.equal('B')
      
    it "allows us to get from A[A->B] to B", ->
      expression = fol.parse "A[A->B]"
      whatToReplace =
        from : expression.substitutions[0].from
        to : expression.substitutions[0].to
      # Note : if we don't delete the substitutions, this won't work.
      delete expression.substitutions
      result = substitute.replace expression, whatToReplace
      expect(result.letter).to.equal('B')

    it "allows us to get from (A and B)[A->C] to A and C", ->
      expression = fol.parse "(A and B)[A->C]"
      whatToReplace =
        from : expression.substitutions[0].from
        to : expression.substitutions[0].to
      result = substitute.replace expression, whatToReplace
      expect(result.left.letter).to.equal('C')

    it "allows us to get from (a=b)[a->c] to c=b", ->
      expression = fol.parse "(a=b)[a->c]"
      whatToReplace =
        from : expression.substitutions[0].from
        to : expression.substitutions[0].to
      result = substitute.replace expression, whatToReplace
      expect(result.termlist[0].name).to.equal('c')

    it "allows us to get from (a=b)[a->τ] to τ=b", ->
      expression = fol.parse "(a=b)[a->τ]"
      whatToReplace =
        from : expression.substitutions[0].from
        to : expression.substitutions[0].to
      result = substitute.replace expression, whatToReplace
      expect(result.termlist[0].name).to.equal('τ')
    
    it "doesn't mess with substitutions", ->
      expression = fol.parse "(A and B)[C->D]"
      whatToReplace =
        from : fol.parse "A"
        to : fol.parse "B"
      result = substitute.replace expression, whatToReplace
      expect(expression.substitutions.length).to.equal(1)
      expect(result.substitutions.length).to.equal(1)


  describe 'doSub', ->
    it "does a double-negation substitution", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not not A'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'A'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "is fine when a double-negation substitution can't be done", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not A'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'not A'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "does a deMorgan substitution", ->
      sub = 
        from : fol.parse 'not (φ and ψ)'
        to : fol.parse '(not φ) or (not ψ)'
      expression = fol.parse 'not ((A arrow B) and C)'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse '(not (A arrow B)) or (not C)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it 'does a "φ or true" substitution', ->
      sub = 
        from : fol.parse 'φ or true'
        to : fol.parse 'true'
      expression = fol.parse '((A arrow B) or true)'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'true'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "does not modify `expression` in place ", ->
      sub = 
        from : fol.parse 'φ or true'
        to : fol.parse 'true'
      expression = fol.parse '((A arrow B) or true)'
      pre = util.cloneExpression expression
      substitute.doSub expression, sub
      post = util.cloneExpression expression
      expect(pre).to.deep.equal(post)
    it "does a double-negation substitution", ->


  describe 'doSubRecursive', ->
    it "does a double-negation substitution", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not not A'
      result = substitute.doSubRecursive expression, sub
      expectedResult = fol.parse 'A'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "substitutes into substitutions", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'A[A->not not B]'
      result = substitute.doSubRecursive expression, sub
      expectedResult = fol.parse 'A[A->B]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "does a double-negation substitution when the double neg is nested", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not (not not A & B)'
      result = substitute.doSubRecursive expression, sub
      # console.log "result #{util.expressionToString result}"
      expectedResult = fol.parse 'not (A and B)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "does not modify `expression` in place ", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not not A'
      pre = util.cloneExpression expression
      substitute.doSubRecursive expression, sub
      post = util.cloneExpression expression
      expect(pre).to.deep.equal(post)


  describe 'subs, the built-in substitutions', ->
    it "does not_exists substitution", ->
      sub = substitute.subsForPNF.not_exists
      expression = fol.parse 'not exists y ( F(y))'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'all y (not F(y))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "does deMorgan1", ->
      expression = fol.parse 'not (not A and not (B or not C))'
      sub = substitute.subsForPNF.demorgan1
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'not not A or not not (B or not C)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "converts arrow correctly", ->
      expression = fol.parse 'A arrow B'
      sub = substitute.subsForPNF.replace_arrow
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'not A or B'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
        
    it "converts arrow correctly (when antecedent is complex)", ->
      expression = fol.parse '(A and B) arrow (C and D)'
      sub = substitute.subsForPNF.replace_arrow
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'not (A and B) or (C and D)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
        
    it "does replace_double_arrow", ->
      expression = fol.parse '(A ↔ B) ↔ (B and (A ↔ (A ↔ C)))'
      doubleArrowSymbol = expression.type
      result = substitute.doSubRecursive expression, substitute.subsForPNF.replace_double_arrow
      resultString = util.expressionToString result
      expect(resultString.indexOf(doubleArrowSymbol)).to.equal(-1)
    
    it "does not_all substitution", ->
      sub = substitute.subsForPNF.not_all
      expression = fol.parse 'not all z ( Loves(a,z))'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'exists z (not Loves(a,z))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "does all_and_left substitution", ->
      sub = substitute.subsForPNF.all_and_left
      expression = fol.parse 'P and all z ( Loves(a,z))'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'all z (P and Loves(a,z))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "does all_and_right substitution", ->
      sub = substitute.subsForPNF.all_and_right
      expression = fol.parse 'all z ( R(a,z)) and P'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'all z (R(a,z) and P)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "does all_or_left substitution", ->
      sub = substitute.subsForPNF.all_or_left
      expression = fol.parse 'exists x F(x) or all z G(z)'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'all z (exists x F(x) or G(z))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "does not alter the truth table of propositional sentences"
    # TODO (can't yet because don't have truth tables)


  describe 'subs_eliminate_redundancy', ->
    it "should transform A or (not a=a or not A)", ->
      e = fol.parse "A or (not a=a or not A)"
      subs = substitute.subs_eliminate_redundancy
      sub = subs.identity
      result = substitute.doSubRecursive e, sub
      expectedResult = fol.parse 'A or (not true or not A)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true


  describe "odds and ends", ->
    it "should exhaustively apply substitutions", ->
      expression = fol.parse 'not (not A and not (B or not C))'
      fn = (expression) ->
        result = expression
        result = substitute.doSubRecursive result, substitute.subsForPNF.demorgan1
        result = substitute.doSubRecursive result, substitute.subsForPNF.demorgan2
        result = substitute.doSubRecursive result, substitute.subsForPNF.dbl_neg
        return result
      result = util.exhaust expression, fn
      # console.log "#{util.expressionToString result}"
      expect(result.type).to.not.equal('not')
    


  describe "`.applySubstitutions` (as in `A[A->B]`)", ->
    it "works when there are no substitutions", ->
      expression = fol.parse "A and B"
      util.delExtraneousProperties expression
      result = substitute.applySubstitutions expression
      expect(result).to.deep.equal(expression)
    
    it "applies a simple substitution (to the main expression)", ->
      expression = fol.parse "A[A->B]"
      result = substitute.applySubstitutions expression
      expect(result.letter).to.equal('B')

    it "applies a simple substitution (to a component expression)", ->
      expression = fol.parse "(A and D)[A->B]"
      result = substitute.applySubstitutions expression
      expect(result.left.letter).to.equal('B')

    it "applies a substitution which is not at the root expression", ->
      expression = fol.parse "(A[A->B] and D)"
      result = substitute.applySubstitutions expression
      expect(result.left.letter).to.equal('B')

    it "applies two substitutions in the right order", ->
      # NOTE: This may fail if there is a problem with the awFOL parser.
      expression = fol.parse "((A and D)[A->B])[B->C]"
      console.log "expression = #{util.expressionToString(expression)}"
      result = substitute.applySubstitutions expression
      expect(result.left.letter).to.equal('C')
    
    it "takes `(A[A->B] and C)[B->D]` to `D and C`", ->
      expression = fol.parse "(A[A->B] and C)[B->D]"
      result = substitute.applySubstitutions expression
      expect(result.type).to.equal('and')
      expect(result.left.letter).to.equal('D')
      expect(result.right.letter).to.equal('C')

    it "does not mutate its parameter", ->
      expression = fol.parse "(A[A->B] and C)[B->D]"
      util.delExtraneousProperties expression
      pre = _.cloneDeep expression
      result = substitute.applySubstitutions expression
      post = expression
      expect(pre).not.to.deep.equal(result) # Test the test.
      expect(pre).to.deep.equal(post)
    
    describe "in the special case of `[α->null]` substitutions", ->
      it "is helped by `.replace` throwing a useful error", ->
        e = fol.parse "a=b"
        whatToReplace =
          from : (fol.parse "A[a->null]").substitutions[0].from
          to : (fol.parse "A[a->null]").substitutions[0].to
        expect( -> substitute.replace(e, whatToReplace) ).to.throw()
        try 
          substitute.replace(e, whatToReplace) 
        catch e 
          expect(e.message).to.equal("_internal: replace to null")
        
      it "applying `[a->null]` to an expression not containing `a` makes no difference", ->
        expression = fol.parse "b=c[a->null]"
        util.delExtraneousProperties expression
        pre = _.cloneDeep expression
        result = substitute.applySubstitutions expression
        post = expression
        expect(pre).to.deep.equal(post)
        
      it "applying `[a->null]` to `(b=c and A)` makes no difference", ->
        expression = fol.parse "(b=c and A)[a->null]"
        util.delExtraneousProperties expression
        pre = _.cloneDeep expression
        result = substitute.applySubstitutions expression
        post = expression
        expect(pre).to.deep.equal(post)
        
      it "applying `[a->null]` to `(a=c and A)` gives you null", ->
        expression = fol.parse "(a=c and A)[a->null]"
        util.delExtraneousProperties expression
        result = substitute.applySubstitutions expression
        expect(result).to.equal(null)
        
      it "applying `[a->null]` to `a=c` gives you null", ->
        expression = fol.parse "a=b[a->null]"
        util.delExtraneousProperties expression
        result = substitute.applySubstitutions expression
        expect(result).to.equal(null)
        











