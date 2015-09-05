chai = require('chai')
assert = chai.assert
expect = chai.expect
substitute = require('../substitute')
fol = require('../fol')
util = require('../util')
symmetry = require('../symmetry')

# some handy FOL objects (defining these presupposes that some of the tests below work ...)
PROP_A = fol.parse "A"
NAME_A = fol.parse("F(a)").termlist[0]   #i.e. {type='name', name='a', ...}
NAME_B = fol.parse("F(b)").termlist[0]
VARIABLE_X = fol.parse("F(x)").termlist[0]
TERM_METAVARIABLE_T = fol.parse("F(τ)").termlist[0]

describe 'substitute', ->
  describe 'findMatches', ->
    it "should find match 'not not φ' with φ='A' in 'not not A'", ->
      pattern = fol.parse 'not not φ'
      expression = fol.parse 'not not A'
      matches = substitute.findMatches expression, pattern
      expectedMatch = PROP_A
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatch)).to.be.true

    it "should find match 'not not φ' with φ='A and B' in 'not not (A and B)'", ->
      pattern = fol.parse 'not not φ'
      expression = fol.parse 'not not (A and B)'
      matches = substitute.findMatches expression, pattern
      expectedMatch = fol.parse("A and B")
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatch)).to.be.true

    it "should fail to find match 'not not φ' in 'not (not A and B)'", ->
      pattern = fol.parse 'not not φ'
      expression = fol.parse 'not (not A and B)'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
 
    it "should find match 'not (φ or ψ)' with φ='A' in 'not (A or (B arrow C))'", ->
      pattern = fol.parse 'not (φ or ψ)'
      expression = fol.parse 'not (A or (B arrow C))'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        φ : PROP_A
        ψ : fol.parse("B arrow C")
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
      expect(util.areIdenticalExpressions(matches.ψ, expectedMatches.ψ)).to.be.true

    it "should not match 'φ or φ' in 'A or B'", ->
      pattern = fol.parse 'φ or φ'
      expression = fol.parse 'A or B'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false

    it "should not match 'φ or φ' in 'A or not A'", ->
      pattern = fol.parse 'φ or φ'
      expression = fol.parse 'A or not A'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false

    it "should not match 'φ or φ' in 'A or A'", ->
      pattern = fol.parse 'φ or φ'
      expression = fol.parse 'A or A'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        φ : fol.parse("A")
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
    
    it "should match a sentence with the same (no expression variables)", ->
      pattern = fol.parse 'A or A'
      expression = fol.parse 'A or A'
      matches = substitute.findMatches expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      
    it "should not match different sentences (no expression variables)", ->
      pattern = fol.parse 'A or A'
      expression = fol.parse 'B or B'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false

    it "should return a matches object with .addMatches method that allows merging matches", ->
      pattern = fol.parse 'φ1 or φ1'
      expression = fol.parse 'A or A'
      matches = substitute.findMatches expression, pattern
      pattern2 = fol.parse 'φ2'
      expression2 = fol.parse 'B'
      matches2 = substitute.findMatches expression2, pattern2
      matches.addMatches matches2
      expectedMatches =
        φ1 : fol.parse("A")
        φ2 : fol.parse("B")
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
      expect(util.areIdenticalExpressions(matches.φ2, expectedMatches.φ2)).to.be.true
      
    

  describe 'findMatches with expressions that are not closed wffs', ->
    it "should match 'all x not φ' in 'all x (not (F(x) and G(x)))", ->
      pattern = fol.parse 'all x not φ'
      expression = fol.parse 'all x (not (F(x) and G(x)))'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        φ : fol.parse("F(x) and G(x)")
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
      

  describe 'findMatches with `term_metavariable`s', ->
    it "should find match 'α=α' with α='a' in 'a=a'", ->
      pattern = fol.parse 'α=α'
      expression = fol.parse 'a=a'
      matches = substitute.findMatches expression, pattern
      expectedMatch = expression.termlist[0]
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.α, expectedMatch)).to.be.true

    it "should find match 'Loves(α,b) and φ'", ->
      pattern = fol.parse 'Loves(α,b) and φ'
      expression = fol.parse 'Loves(a,b) and Loves(b,a)'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        φ : fol.parse("Loves(b,a)")
        α : fol.parse("F(a)").termlist[0] #i.e. {type='name', name='a', ...}
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
      expect(util.areIdenticalExpressions(matches.α, expectedMatches.α)).to.be.true
      
    it "should match for pattern α=β", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      matches = substitute.findMatches expression1, pattern
      expectedMatches =
        "α" : NAME_A
        "β" : NAME_B
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.α, expectedMatches.α)).to.be.true
      expect(util.areIdenticalExpressions(matches.β, expectedMatches.β)).to.be.true

    it "should match for pattern 'all τ φ", ->
      pattern = fol.parse 'all τ φ'
      expression = fol.parse '(all x) (F(x) and G(x))'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        "τ" : VARIABLE_X
        "φ" : expression.left
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.τ, expectedMatches.τ)).to.be.true
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
    
    it "should match 'exists τ1 exists τ2 (F(τ1) and G(τ2))'", ->
      expression = fol.parse 'exists x exists y (F(x) and G(y))'
      pattern = fol.parse 'exists τ1 exists τ2 (F(τ1) and G(τ2))'
      result = substitute.findMatches expression, pattern
      expect(result).not.to.be.false


  describe 'findMatches where identity can be treated as symmetric', ->
    it "should not find match 'α1=α2 and α1=α2' when identity is not symmetric", ->
      pattern = fol.parse 'α1=α2 and α1=α2'
      expression = fol.parse 'a=b and b=a'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
      
    it "should find match 'α1=α2 and α1=α2' when identity is symmetric", ->
      pattern = fol.parse 'α1=α2 and α1=α2'
      expression = fol.parse 'a=b and b=a'
      matches = substitute.findMatches expression, pattern, null, {symmetricIdentity:true}
      expect(matches).not.to.be.false


  describe 'using findMatches where what the expression variables must match is stipulated', ->
    it "should match for pattern α=β with specified matches (expect success)", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      stipulatedMatches = {"α":NAME_A, "β":NAME_B}
      matches = substitute.findMatches expression1, pattern, stipulatedMatches
      expect(matches).not.to.be.false
      
    it "should match for pattern α=β with specified matches (expect failure)", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      stipulatedMatches =
        "α" : NAME_B
        "β" : NAME_A
      matches = substitute.findMatches expression1, pattern, stipulatedMatches
      expect(matches).to.be.false


  describe 'replace (replaces one expression or term with another)', ->    
    it "should help with testing whether a=b, F(a) therefore F(b) is ok", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      matches = substitute.findMatches expression1, pattern
      expression2 = fol.parse 'F(a)'
      result = substitute.replace expression2, {from:matches.α, to:matches.β}
      expression3 = fol.parse 'F(b)'
      expect(util.areIdenticalExpressions(result,expression3)).to.be.true
      
    it "should help with testing whether a=b, F(a) therefore G(b) is ok", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      matches = substitute.findMatches expression1, pattern
      expression2 = fol.parse 'F(a)'
      result = substitute.replace expression2, {from:matches.α, to:matches.β}
      expression3 = fol.parse 'G(b)'
      expect(util.areIdenticalExpressions(result,expression3)).to.be.false
      
    it "should help with testing whether a=b, F(b) therefore F(a) is ok", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      matches = substitute.findMatches expression1, pattern
      expression2 = fol.parse 'F(b)'
      result = substitute.replace expression2, {from:matches.α, to:matches.β}
      expression3 = fol.parse 'F(a)'
      expect(util.areIdenticalExpressions(result,expression3)).to.be.false
    
    it "should allow us to replace a variable with a `term_metavariable`", ->
      expression = fol.parse "Loves(x,a)"
      whatToReplace = 
        from : VARIABLE_X
        to : TERM_METAVARIABLE_T
      result = substitute.replace expression, whatToReplace
      expectedResult = fol.parse "Loves(τ,a)"
      expect( util.areIdenticalExpressions(result,expectedResult) ).to.be.true
    
    it "should replace all instances of a variable with a `term_metavariable`", ->
      expression = fol.parse "Loves(x,a) and F(x) arrow G(x)"
      whatToReplace = 
        from : VARIABLE_X
        to : TERM_METAVARIABLE_T
      result = substitute.replace expression, whatToReplace
      expectedResult = fol.parse "Loves(τ,a) and F(τ) arrow G(τ)"
      expect( util.areIdenticalExpressions(result,expectedResult) ).to.be.true

    it "should allow us to tell whether 'F(a)' is an instance of 'all x F(x)'", ->
      expression = fol.parse "all x F(x)"
      boundVariable = expression.boundVariable
      expressionMinusQuantifier = expression.left
      whatToReplace = 
        from : boundVariable
        to : TERM_METAVARIABLE_T
      thePattern = substitute.replace expressionMinusQuantifier, whatToReplace
      aCandidateInstance = fol.parse "F(a)"
      theMatch = substitute.findMatches aCandidateInstance, thePattern
      expect(theMatch).not.to.be.false
      
    it "should allow us to tell whether 'G(a)' is an instance of 'all x F(x)'", ->
      expression = fol.parse "all x F(x)"
      boundVariable = expression.boundVariable
      expressionMinusQuantifier = expression.left
      whatToReplace = 
        from : boundVariable
        to : TERM_METAVARIABLE_T
      thePattern = substitute.replace expressionMinusQuantifier, whatToReplace
      aCandidateInstance = fol.parse "G(a)"
      theMatch = substitute.findMatches aCandidateInstance, thePattern
      expect(theMatch).to.be.false
      
    it "should allow us to tell whether 'F(b) and G(b)' is an instance of 'all y (F(y) and G(y))'", ->
      expression = fol.parse "all y (F(y) & G(y))"
      boundVariable = expression.boundVariable
      expressionMinusQuantifier = expression.left
      whatToReplace = 
        from : boundVariable
        to : TERM_METAVARIABLE_T
      thePattern = substitute.replace expressionMinusQuantifier, whatToReplace
      aCandidateInstance = fol.parse "F(b) & G(b)"
      theMatch = substitute.findMatches aCandidateInstance, thePattern
      expect(theMatch).not.to.be.false
      
    it "should allow us to tell whether 'F(a) and G(b)' is an instance of 'all y (F(y) and G(y))'", ->
      expression = fol.parse "all y (F(y) & G(y))"
      boundVariable = expression.boundVariable
      expressionMinusQuantifier = expression.left
      whatToReplace = 
        from : boundVariable
        to : TERM_METAVARIABLE_T
      thePattern = substitute.replace expressionMinusQuantifier, whatToReplace
      aCandidateInstance = fol.parse "F(a) & G(b)"
      theMatch = substitute.findMatches aCandidateInstance, thePattern
      expect(theMatch).to.be.false
      

  describe 'applyMatches', ->
    it "should correctly apply a simple match to a pattern", ->
      pattern = fol.parse 'not not φ'
      matches = 
        φ : fol.parse 'A'
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'not not A'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "should correctly apply a simple match to a pattern when the match occurs more than once", ->
      pattern = fol.parse 'not not (φ and (φ or φ))'
      matches = 
        φ : fol.parse 'A'
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'not not (A and (A or A))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "should correctly apply a match with multiple `expression_variable`s to a pattern", ->
      pattern = fol.parse 'not (φ and not ψ)'
      matches = 
        φ : fol.parse 'A'
        ψ : fol.parse 'B or C'
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'not (A and not (B or C))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "should correctly apply a match a `term_metavariable` to a pattern", ->
      pattern = fol.parse 'Loves(α,b) and not α=b'
      matches = 
        α : fol.parse('F(a)').termlist[0] #i.e. {type='name', name='a', ...}
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'Loves(a,b) and not a=b'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true


  describe 'doSub', ->
    it "should do a double-negation substitution", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not not A'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'A'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "should be fine when a double-negation substitution can't be done", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not A'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'not A'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "should do a deMorgan substitution", ->
      sub = 
        from : fol.parse 'not (φ and ψ)'
        to : fol.parse '(not φ) or (not ψ)'
      expression = fol.parse 'not ((A arrow B) and C)'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse '(not (A arrow B)) or (not C)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it 'should do a "φ or true" substitution', ->
      sub = 
        from : fol.parse 'φ or true'
        to : fol.parse 'true'
      expression = fol.parse '((A arrow B) or true)'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'true'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "should not modify `expression` in place ", ->
      sub = 
        from : fol.parse 'φ or true'
        to : fol.parse 'true'
      expression = fol.parse '((A arrow B) or true)'
      pre = util.cloneExpression expression
      substitute.doSub expression, sub
      post = util.cloneExpression expression
      expect(pre).to.deep.equal(post)


  describe 'doSubRecursive', ->
    it "should do a double-negation substitution", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not not A'
      result = substitute.doSubRecursive expression, sub
      expectedResult = fol.parse 'A'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "should do a double-negation substitution when the double neg is nested", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not (not not A & B)'
      result = substitute.doSubRecursive expression, sub
      # console.log "result #{util.expressionToString result}"
      expectedResult = fol.parse 'not (A and B)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "should not modify `expression` in place ", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not not A'
      pre = util.cloneExpression expression
      substitute.doSubRecursive expression, sub
      post = util.cloneExpression expression
      expect(pre).to.deep.equal(post)


  describe 'subs, the built-in substitutions', ->
    it "should do not_exists substitution", ->
      sub = substitute.subs.not_exists
      expression = fol.parse 'not exists y ( F(y))'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'all y (not F(y))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "should do deMorgan1", ->
      expression = fol.parse 'not (not A and not (B or not C))'
      sub = substitute.subs.demorgan1
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'not not A or not not (B or not C)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "should convert arrow correctly", ->
      expression = fol.parse 'A arrow B'
      sub = substitute.subs.replace_arrow
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'not A or B'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
        
    it "should convert arrow correctly (when antecedent is complex)", ->
      expression = fol.parse '(A and B) arrow (C and D)'
      sub = substitute.subs.replace_arrow
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'not (A and B) or (C and D)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
        
    it "should do replace_double_arrow", ->
      expression = fol.parse '(A ↔ B) ↔ (B and (A ↔ (A ↔ C)))'
      doubleArrowSymbol = expression.type
      result = substitute.doSubRecursive expression, substitute.subs.replace_double_arrow
      resultString = util.expressionToString result
      expect(resultString.indexOf(doubleArrowSymbol)).to.equal(-1)
    
    it "should do not_all substitution", ->
      sub = substitute.subs.not_all
      expression = fol.parse 'not all z ( Loves(a,z))'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'exists z (not Loves(a,z))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "should do all_and_left substitution", ->
      sub = substitute.subs.all_and_left
      expression = fol.parse 'P and all z ( Loves(a,z))'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'all z (P and Loves(a,z))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "should do all_and_right substitution", ->
      sub = substitute.subs.all_and_right
      expression = fol.parse 'all z ( R(a,z)) and P'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'all z (R(a,z) and P)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "should do all_or_left substitution", ->
      sub = substitute.subs.all_or_left
      expression = fol.parse 'exists x F(x) or all z G(z)'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'all z (exists x F(x) or G(z))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "should not alter the truth table of propositional sentences"
    # TODO


  describe 'subs_eliminate_redundancy', ->
    it "should transform A or (not a=a or not A)", ->
      e = fol.parse "A or (not a=a or not A)"
      subs = substitute.subs_eliminate_redundancy
      sub = subs.identity
      result = substitute.doSubRecursive e, sub
      expectedResult = fol.parse 'A or (not true or not A)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

  describe 'renameVariables', ->
    it "should rename the variables in a single quantifier phrase properly", ->
      expression = fol.parse 'exists(x) F(x)'
      substitute.renameVariables expression
      #console.log "expression #{JSON.stringify expression,null,4}"
      expect(expression.boundVariable.name).to.equal('xx1')
      expect(expression.left.termlist[0].name).to.equal('xx1')
      
    it "should rename the variables in a multiple quantifier phrase properly", ->
      expression = fol.parse 'exists(x) all(y) some(z) R(y,a,x,z)'
      substitute.renameVariables expression
      quantifier1 = expression
      quantifier2 = quantifier1.left
      quantifier3 = quantifier2.left
      predicate =  quantifier3.left
      terms = predicate.termlist
      expect(quantifier1.boundVariable.name).to.equal('xx1')
      expect(quantifier2.boundVariable.name).to.equal('xx2')
      expect(quantifier3.boundVariable.name).to.equal('xx3')
      expect(terms[0].name).to.equal(quantifier2.boundVariable.name)
      expect(terms[1].name).to.equal('a') #i.e. was not renamed
      expect(terms[2].name).to.equal(quantifier1.boundVariable.name)
      expect(terms[3].name).to.equal(quantifier3.boundVariable.name)
      
    it "should rename the variables in a tricky quantifier phrase properly", ->
      expression = fol.parse 'exists(x) (F(x) and all(x) G(x))'
      substitute.renameVariables expression
      quantifier1 = expression
      quantifier2 = expression.left.right
      predicate1 = quantifier1.left.left
      predicate2 = quantifier2.left
      expect(quantifier1.boundVariable.name).to.equal('xx1')
      expect(quantifier2.boundVariable.name).to.equal('xx2')
      expect(predicate1.termlist[0].name).to.equal(quantifier1.boundVariable.name)
      expect(predicate2.termlist[0].name).to.equal(quantifier2.boundVariable.name)
      
    it "should rename the variables in expressions involving identity", ->
      expression = fol.parse 'exists(x) x=a'
      substitute.renameVariables expression
      expect(expression.left.termlist[0].name).to.equal('xx1')
    
    it "should not repeat a variable name", ->
      expression = fol.parse '(exists x F(x)) and (exists x G(x))'
      substitute.renameVariables expression
      quantifier1 = expression.left
      quantifier2 = expression.right
      predicate1 = quantifier1.left
      predicate2 = quantifier2.left
      expect(quantifier1.boundVariable.name).to.equal('xx1')
      expect(quantifier2.boundVariable.name).to.equal('xx2')
      
    it "should create patterns if newVariableBaseName is a term metavariable symbol", ->
      expression = fol.parse '(exists x F(x)) and (exists x G(x))'
      substitute.renameVariables expression, 'τ'
      pattern = expression
      expression2 = fol.parse '(exists y F(y)) and (exists x1 G(x1))'
      match = substitute.findMatches expression2, pattern
      expect(match).not.to.be.false
      

  describe "odds and ends", ->
    it "should exhaustively apply substitutions", ->
      expression = fol.parse 'not (not A and not (B or not C))'
      fn = (expression) ->
        result = expression
        result = substitute.doSubRecursive result, substitute.subs.demorgan1
        result = substitute.doSubRecursive result, substitute.subs.demorgan2
        result = substitute.doSubRecursive result, substitute.subs.dbl_neg
        return result
      result = util.exhaust expression, fn
      # console.log "#{util.expressionToString result}"
      expect(result.type).to.not.equal('not')
    
    it "I just want to see this", ->
      theF = [ 
        fol.parse 'exists x (F(x) and all y (F(y) arrow x=y))'
        fol.parse 'exists x all y (F(y) ↔ x=y)'
        fol.parse 'exists x F(x) and exists x all y ( F(y) arrow x=y )'
      ]
      pnf = ( substitute.prenexNormalForm(e) for e in theF )
      for e in pnf
        symmetry.sortPNFExpression(e)
        symmetry.sortIdentityStatements(e)
        e = symmetry.eliminateRedundancyInPNF(e)
        console.log "the F : #{util.expressionToString e} "
      throw "E"


  describe "isPNF", ->
    it "can tell you something isn't in PNF (quantifier scope wrong)", ->
      expression = fol.parse 'F(a) and exists(x) G(x)'
      expect( substitute.isPNF(expression) ).to.be.false
    it "can tell you something isn't in PNF (disjunction outside conjunction)", ->
      expression = fol.parse 'A and (B or (A and B))'
      expect( substitute.isPNF(expression) ).to.be.false
    it "can tell you something is in PNF", ->
      expression = fol.parse 'exists x all y ( (F(x) or G(x) ) and (F(y) or G(y)) )'
      expect( substitute.isPNF(expression) ).to.be.true
      

  describe "prenexNormalForm", ->
    it "gets rid of arrow", ->
      expression = fol.parse 'A arrow (B arrow C)'
      
      # Later we use util.expressionToString to help in checking whether all instances of 
      # arrow have been removed.  To do this we want to check how an arrow will appear in
      # this function.
      arrowSymbol = expression.type
      
      result = substitute.prenexNormalForm expression
      #console.log "#{util.expressionToString result}"
      expect(result.type).not.to.equal('arrow')
      resultString = util.expressionToString result
      expect(resultString.indexOf(arrowSymbol)).to.equal(-1)
      
    it "gets rid of double arrow", ->
      expression = fol.parse '(A ↔ B) ↔ (B and (A ↔ C))'
      doubleArrowSymbol = expression.type
      result = substitute.prenexNormalForm expression
      resultString = util.expressionToString result
      expect(resultString.indexOf(doubleArrowSymbol)).to.equal(-1)

    it "sorts out conjunction, negation and disjunction", ->
      expression = fol.parse 'not (not ((A and not B) or not (C or (D and not E))))'
      result = substitute.prenexNormalForm expression
      # If it is in PNF then we should have conjunctions of disjunctions of atomic sentences.
      conjuncts = symmetry.listJuncts result, 'and'
      nestedDisjuncts = ( symmetry.listJuncts(junct, 'or') for junct in conjuncts)
      for someDisjuncts in nestedDisjuncts
        for disjunct in someDisjuncts
          if disjunct.type isnt 'not'
            expect(disjunct.type).to.equal('sentence_letter')

    it "puts existential quantifiers outwards of conjuncts", ->
      expression = fol.parse '(exists x F(x)) and (exists x G(x))'
      result = substitute.prenexNormalForm expression
      #console.log "result = #{util.expressionToString result}"
      expectedMatch = fol.parse 'exists τ1 exists τ2 (F(τ2) and G(τ1))'
      test = substitute.findMatches result, expectedMatch
      expect(test).not.to.be.false
    
    it "deals with an example from wikipedia", ->
      expression = fol.parse 'all x ((exists y F(y)) or ((exists z G(z)) arrow H(x)))'
      result = substitute.prenexNormalForm expression
      # console.log "result = #{util.expressionToString result}"
      test = substitute.isPNF result
      expect(test).to.be.true
      








