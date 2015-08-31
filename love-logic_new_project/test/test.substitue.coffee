chai = require('chai')
assert = chai.assert
expect = chai.expect
substitute = require('../substitute')
fol = require('../fol')
util = require('../util')


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


  describe 'using findMatches where what expression variables must match is stipulated', ->
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
      boundVariable = expression.variable
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
      boundVariable = expression.variable
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
      boundVariable = expression.variable
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
      boundVariable = expression.variable
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


  describe 'subs, the built-in substitutions', ->
    it "should do not_exists substitution", ->
      sub = substitute.subs.not_exists
      expression = fol.parse 'not exists y ( F(y))'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'all y (not F(y))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
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
      
  describe 'listVariables', ->
    it "should return a list of all variables in a phrase with one quantifier"
    it "should return a list of all variables in a phrase with multiple quantifiers"

  describe 'renameVariables', ->
    it "should rename the variables in a single quantifier phrase properly"
    it "should rename the variables in a multiple quantifier phrase properly"
    it "should rename the variables in a tricky quantifier phrase properly"










