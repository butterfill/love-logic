chai = require('chai')
assert = chai.assert
expect = chai.expect
substitute = require('../substitute')
fol = require '../parser/awFOL'
util = require('../util')
symmetry = require('../symmetry')

PROP_P = fol.parse "P"
PROP_Q = fol.parse "Q"
VARIABLE_X = fol.parse("F(x)").termlist[0]
VARIABLE_Y = fol.parse("F(y)").termlist[0]


describe "symmetry", ->
  describe "listJuncts", ->
    it "should get the juncts right in 'P and (Q and (R or (P1 and P2)))'", ->
      result = symmetry.listJuncts fol.parse('P and (Q and (R or (P1 and P2)))'), 'and'
      # console.log "result #{JSON.stringify (util.expressionToString(e) for e in result)}"
      # console.log "result.length #{result.length}"
      expectedResult = [PROP_P, PROP_Q, fol.parse('(R or (P1 and P2))')]
      expect(result.length).to.equal(3)
      for expression, i in result
        expect( util.areIdenticalExpressions(result[i],expectedResult[i]) ).to.be.true
    
    it "should get the juncts right in '(F(x) or not F(y)) or P'", ->
      result = symmetry.listJuncts fol.parse('(F(x) or not F(y)) or P'), 'or'
      expect(result.length).to.equal(3)
      expect( result[1].type).to.equal('not')
    
    it "should get the juncts right when there aren't any", ->
      result = symmetry.listJuncts fol.parse('(F(x) or not F(y)) or P'), 'and'
      expect(result.length).to.equal(1)


  describe "listQuants", ->
    it "should identify the variables in 'all x all y F(x,y)'", ->
      expression = fol.parse('all x all y F(x,y)')
      result = symmetry.listQuants expression, 'universal_quantifier'
      expect(result.boundVariables.length).to.equal(2)
      if util.areIdenticalExpressions(result.boundVariables[0], VARIABLE_Y)
        expect( util.areIdenticalExpressions(result.boundVariables[1], VARIABLE_X)).to.be.true
      else
        expect( util.areIdenticalExpressions(result.boundVariables[0], VARIABLE_X)).to.be.true
        expect( util.areIdenticalExpressions(result.boundVariables[1], VARIABLE_Y)).to.be.true
        
    it "should identify the quantified expressions in 'all x all y F(x,y)'", ->
      expression = fol.parse('all x all y F(x,y)')
      result = symmetry.listQuants expression, 'universal_quantifier'
      expect(result.quantifiedExpression.type).to.equal('predicate')
      expect(result.quantifiedExpression.name).to.equal('F')
      
    it "should identify the variables in 'exists x exists y all z (F(x,y,z) and P)'", ->
      expression = fol.parse 'exists x exists y all z (F(x,y,z) and P)'
      result = symmetry.listQuants expression, 'existential_quantifier'
      expect(result.boundVariables.length).to.equal(2)
      if util.areIdenticalExpressions(result.boundVariables[0], VARIABLE_Y)
        expect( util.areIdenticalExpressions(result.boundVariables[1], VARIABLE_X)).to.be.true
      else
        expect( util.areIdenticalExpressions(result.boundVariables[0], VARIABLE_X)).to.be.true
        expect( util.areIdenticalExpressions(result.boundVariables[1], VARIABLE_Y)).to.be.true

    it "should identify the quantified expression in 'exists x exists y all z (F(x,y,z) and P)'", ->
      expression = fol.parse 'exists x exists y all z (F(x,y,z) and P)'
      result = symmetry.listQuants expression, 'existential_quantifier'
      expect(result.quantifiedExpression.type).to.equal('universal_quantifier')
      expect(result.quantifiedExpression.boundVariable.name).to.equal('z')


  describe "rebuildExpression", ->
    it "should rebuild a conjunction", ->
      juncts = [ fol.parse 'A'
                  fol.parse 'B'
                  fol.parse 'C'
                ]
      result = symmetry.rebuildExpression juncts, 'and'
      expectedResult = fol.parse "A and (B and C)"
      # console.log "result #{util.expressionToString result}"
      # console.log "result #{JSON.stringify util.delExtraneousProperties(result),null,4}"
      expect( util.areIdenticalExpressions(result, expectedResult) ).to.be.true

    it "should rebuild a disjunction", ->
      juncts = [ fol.parse 'A'
                  fol.parse 'B'
                  fol.parse 'C'
                ]
      result = symmetry.rebuildExpression juncts, 'or'
      expectedResult = fol.parse "A or (B or C)"
      console.log "result #{util.expressionToString result}"
      expect( util.areIdenticalExpressions(result, expectedResult) ).to.be.true

  describe "sortPNFExpression", ->
    it "should re-order a simple expression", ->
      expression = fol.parse '(B or C) and (C or A)'
      result = symmetry.sortPNFExpression expression
      expectedResult = fol.parse '(A or C) and (B or C)'
      # console.log "sorted expression : #{util.expressionToString result } "
      expect( util.areIdenticalExpressions(result, expectedResult) ).to.be.true
      
    it "should re-order an expression involving quantifiers", ->
      expression = fol.parse 'exists x all y ( P and (x=y or R(x,y) ) )'
      result = symmetry.sortPNFExpression expression
      expectedResult = fol.parse 'exists x all y ( P and (R(x,y) or x=y))'
      # console.log "sorted expression : #{util.expressionToString result } "
      expect( util.areIdenticalExpressions(result, expectedResult) ).to.be.true
      
    it "should order some more complex expressions of uniqueness", ->
      theF = [ 
        fol.parse 'exists x (F(x) and all y (F(y) arrow x=y))'
        fol.parse 'exists x (all y (F(y) arrow x=y) and F(x))'
        fol.parse 'exists x all y (F(y) ↔ x=y)'
        fol.parse 'exists x all y (x=y ↔ F(y))'
      ]
      pnf = ( substitute.prenexNormalForm(e) for e in theF )
      pnf = ( symmetry.sortPNFExpression(e) for e in pnf )
      # for e in pnf
      #   console.log "the F : #{util.expressionToString e} "
      expect( util.areIdenticalExpressions(pnf[0], pnf[1]) ).to.be.true
      expect( util.areIdenticalExpressions(pnf[2], pnf[3]) ).to.be.true
      #expect( util.areIdenticalExpressions(pnf[4], pnf[5]) ).to.be.true
      

  describe "arePrefixedQuantifiersEquivalent", ->
    it "should match when the quantifiers are identical", ->
      left = fol.parse "all x all y P"
      right = fol.parse "all x all y (Q and R)"
      expect( symmetry.arePrefixedQuantifiersEquivalent(left, right) ).to.be.true
      
    it "should match when universal quantifiers are different", ->
      left = fol.parse "all y all x P"
      right = fol.parse "all x all y (Q and R)"
      expect( symmetry.arePrefixedQuantifiersEquivalent(left, right) ).to.be.true
      
    it "should still work when left expression is just the quantifiers", ->
      left = fol.parse "all y all x P"
      left = symmetry.getPrefixedQuantifiers left
      right = fol.parse "all x all y (Q and R)"
      expect( symmetry.arePrefixedQuantifiersEquivalent(left, right) ).to.be.true

    it "should still work when right expression is just the quantifiers", ->
      left = fol.parse "all y all x P"
      right = fol.parse "all x  (Q and R)"
      right = symmetry.getPrefixedQuantifiers right
      expect( symmetry.arePrefixedQuantifiersEquivalent(left, right) ).to.be.false

    it "should match when multiple types of quantifiers are different", ->
      left = fol.parse "all y all x exists z1 exists z2 all z3 P"
      right = fol.parse "all x all y exists z2 exists z1 all z3 (Q and R)"
      expect( symmetry.arePrefixedQuantifiersEquivalent(left, right) ).to.be.true
    
    it "should not match when variables are different", ->
      left = fol.parse "all x all y P"
      right = fol.parse "all x all z4 (Q and R)"
      expect( symmetry.arePrefixedQuantifiersEquivalent(left, right) ).to.be.false
      
    it "should not match when variables are different (version 2)", ->
      left = fol.parse "all x all z P"
      right = fol.parse "all y all z (Q and R)"
      expect( symmetry.arePrefixedQuantifiersEquivalent(left, right) ).to.be.false
      
    it "should not match when number of quantifiers is different", ->
      left = fol.parse "all x all y P"
      right = fol.parse "all x all y all z (Q and R)"
      expect( symmetry.arePrefixedQuantifiersEquivalent(left, right) ).to.be.false

    it "should not match when order of quantifiers is different", ->
      left = fol.parse "all x exists y P"
      right = fol.parse "exists y all x (Q and R)"
      expect( symmetry.arePrefixedQuantifiersEquivalent(left, right) ).to.be.false

    it "should not match when order of quantifiers is different (version 2)", ->
      left = fol.parse "all x exists y P"
      right = fol.parse "exists x all y (Q and R)"
      expect( symmetry.arePrefixedQuantifiersEquivalent(left, right) ).to.be.false
      
    
  describe "arePNFExpressionsEquivalent", ->
    it "should say true and true are equivalent", ->
      e1 = fol.parse 'true'
      e2 = fol.parse 'true'
      expect( symmetry.areExpressionsEquivalent(e1, e2) ).to.be.true

    it "should say A and A are equivalent", ->
      e1 = fol.parse 'A'
      e2 = fol.parse 'A'
      expect( symmetry.areExpressionsEquivalent(e1, e2) ).to.be.true
      
    it "should cope when a quantifier doesn't bind any variables", ->
      e1 = fol.parse 'exists x A'
      e2 = fol.parse 'exists x A'
      expect( symmetry.areExpressionsEquivalent(e1, e2) ).to.be.true
    
    it "should be ok with all x all y Loves(x,y) things", ->
      expressions = [
        fol.parse 'all x all y Loves(x,y)'
        fol.parse 'all x all y Loves(y,x)'
        fol.parse 'all y all x Loves(x,y)'
        fol.parse 'all y all x Loves(y,x)'
      ]
      for e1 in expressions
        for e2 in expressions when e2 isnt e1
          expect( symmetry.arePNFExpressionsEquivalent(e1, e2) ).to.be.true

    it "should be fine with identities containing names occurring in different orders", ->
      e1 = fol.parse "a=b and x=d and x=y"
      e2 = fol.parse "b=a and d=x and y=x"
      expect( symmetry.arePNFExpressionsEquivalent(e1, e2) ).to.be.true

    it "should be fine with sentence letters occurring in different orders", ->
      e1 = fol.parse "A and B and C"
      e2 = fol.parse "C and A and B"
      expect( symmetry.arePNFExpressionsEquivalent(e1, e2) ).to.be.true

    it "should be fine with sentence letters being repeated", ->
      e1 = fol.parse "A and (A or A)"
      e2 = fol.parse "A"
      expect( symmetry.arePNFExpressionsEquivalent(e1, e2) ).to.be.true

    it "should realise quantifier order matters in exists x all y Loves(x,y)", ->
      e1 = fol.parse 'exists x all y Loves(x,y)'
      e2 = fol.parse 'all y exists x Loves(x,y)'
      expect( symmetry.arePNFExpressionsEquivalent(e1, e2) ).to.be.false
    
    it "should realise the order of variables matters in exists x all y Loves(x,y)", ->
      e1 = fol.parse 'exists x all y Loves(x,y)'
      e2 = fol.parse 'exists x all y Loves(y,x)'
      expect( symmetry.arePNFExpressionsEquivalent(e1, e2) ).to.be.false

    it "should cope with reversals of identity (version 1a)", ->
      # This was failing because there are multiple possible matches for the core expressions.
      # Solved by sorting identity expressions according to the order in which variables 
      # appear in the quantifiers.
      e1 = fol.parse 'exists x all y x=y'
      e2 = fol.parse 'exists x all y y=x'
      expect( symmetry.arePNFExpressionsEquivalent(e1, e2) ).to.be.true
      
    it "should cope with reversals of identity (version 1b)", ->
      # This matters because it shows the problem posed by 1a
      # can't be solved by sorting relative to
      # variable names.
      e1 = fol.parse 'exists y all x x=y'
      e2 = fol.parse 'exists x all y x=y'
      expect( symmetry.arePNFExpressionsEquivalent(e1, e2) ).to.be.true
      
    it "should cope with reversals of identity (version 1c)", ->
      # This is fine (by contrast with version 1a) because the order of the quantifiers doesn't matter.
      e1 = fol.parse 'exists x exists y x=y'
      e2 = fol.parse 'exists x exists y y=x'
      expect( symmetry.arePNFExpressionsEquivalent(e1, e2) ).to.be.true
    
    it "should cope with reversals of identity (version 2a)", ->
      e1 = fol.parse "exists x (a=x)"
      e2 = fol.parse "exists x (x=a)"
      expect( symmetry.arePNFExpressionsEquivalent(e1, e2) ).to.be.true
      
    it "should cope with reversals of identity (version 2b)", ->
      e1 = fol.parse "exists x exists y (a=x and b=y)"
      e2 = fol.parse "exists y exists x (y=b and x=a)"
      expect( symmetry.arePNFExpressionsEquivalent(e1, e2) ).to.be.true
    
    it "should detect differences with identity", ->
      e1 = fol.parse 'exists x all y x=y'
      e2 = fol.parse 'exists x all y x=x'
      expect( symmetry.arePNFExpressionsEquivalent(e1, e2) ).to.be.false

    it "should be fine with additional redundant clauses", ->
      e1 = fol.parse 'exists x F(x)'
      e2 = fol.parse 'exists x F(x) and y=y'
      expect( symmetry.areExpressionsEquivalent(e1, e2) ).to.be.true
      
    it "should equate tautologies", ->
      e1 = fol.parse 'exists x (F(x) or not F(x))'
      e2 = fol.parse 'exists x (G(x) or not G(x))'
      expect( symmetry.areExpressionsEquivalent(e1, e2) ).to.be.true
      
    it "should equate contradictions", ->
      e1 = fol.parse 'exists x (F(x) and not F(x))'
      e2 = fol.parse 'exists x (G(x) and not G(x))'
      expect( symmetry.areExpressionsEquivalent(e1, e2) ).to.be.true
      
    it "should equate contradictions even with multiple quantifiers", ->
      e1 = fol.parse 'exists x (F(x) and not F(x))'
      e2 = fol.parse 'exists x exists y (G(x,y) and not G(x,y))'
      expect( symmetry.areExpressionsEquivalent(e1, e2) ).to.be.true

    it "should equate tautologies even with multiple quantifiers", ->
      e1 = fol.parse 'exists x (F(x) or not F(x))'
      e2 = fol.parse 'exists x exists y (G(x,y) or not G(x,y))'
      expect( symmetry.areExpressionsEquivalent(e1, e2) ).to.be.true

    it "should identify alternatively ordered expressions of uniqueness", ->
      # Note: it won't identify all of these as equivalent, just 0,1 and 2,3 and 4,5
      theF = [  [ fol.parse 'exists x (F(x) and all y (F(y) arrow x=y))'
                  fol.parse 'exists x (F(x) and all y (F(y) arrow y=x))'
                ]
                [ # Reverse conjuncts.
                  fol.parse 'exists x (F(x) and all y (F(y) arrow x=y))'
                  fol.parse 'exists x (all y (F(y) arrow x=y) and F(x))'
                ]
                [ # Reverse conjuncts and identity expression.
                  fol.parse 'exists x (F(x) and all y (F(y) arrow x=y))'
                  fol.parse 'exists x (all y (F(y) arrow y=x) and F(x))'
                ]
                [ # Reverse constituents.
                  fol.parse 'exists x all y (F(y) ↔ x=y)'
                  fol.parse 'exists x all y (x=y ↔ F(y))'
                ]
                [ # Reverse identity expression.
                  fol.parse 'exists x all y (F(y) ↔ x=y)'
                  fol.parse 'exists x all y (F(y) ↔ y=x)'
                ]
                [ # Reverse consitutents and identity expression.
                  fol.parse 'exists x all y (F(y) ↔ x=y)'
                  fol.parse 'exists x all y (y=x ↔ F(y))'
                ]
                [ fol.parse 'exists x F(x) and exists x all y ( F(y) arrow x=y )'
                  fol.parse 'exists x all y ( F(y) arrow x=y ) and exists x F(x)'
                ]
                [ fol.parse 'exists x F(x) and exists x all y ( F(y) arrow x=y )'
                  fol.parse 'exists x all y ( F(y) arrow y=x ) and exists x F(x)'
                ]
      ]
      pnf = ( (substitute.prenexNormalForm(e) for e in pair) for pair in theF )
      pnf = ( (symmetry.sortPNFExpression(e) for e in pair) for pair in pnf )
      for pair in pnf
        expect( symmetry.arePNFExpressionsEquivalent(pair[0], pair[1]) ).to.be.true
  
  
  describe "_getVariableOrder", ->
    it "should order single variable expressions", ->
      e = fol.parse "all y all x F(x)"
      result = symmetry._getVariableOrder e
      expect(result).to.deep.equal(['x','y'])

    it "should respect differences in quantifier type", ->
      e = fol.parse "all y exists x A"
      result = symmetry._getVariableOrder e
      expect(result).to.deep.equal(['y','x'])

    it "should cope with multiple mixed quantifiers", ->
      e = fol.parse "all z all x exists y2 exists z2 exists y1 A"
      result = symmetry._getVariableOrder e
      expect(result).to.deep.equal(['x','z','y1','y2','z2'])


  describe "sortIdentityStatements", ->
    it "should sort expressions containing identities with names", ->
      e = fol.parse "A and (b=a)"
      result = symmetry.sortIdentityStatements(e)
      expectedResult = fol.parse "A and (a=b)"
      expect( util.areIdenticalExpressions(e, expectedResult) ).to.be.true

    it "should sort expressions containing identities with variables and", ->
      e = fol.parse "x=a"
      result = symmetry.sortIdentityStatements(e)
      expectedResult = fol.parse "a=x"
      expect( util.areIdenticalExpressions(e, expectedResult) ).to.be.true
      

    it "should sort expressions containing identities according to quantifier order", ->
      e = fol.parse "exists y all x ( x=y and Loves(x,y) )"
      result = symmetry.sortIdentityStatements(e)
      expectedResult = fol.parse "exists y all x ( y=x and Loves(x,y) )"
      expect( util.areIdenticalExpressions(result, expectedResult) ).to.be.true
      
    it "should sort expressions containing identities according to quantifier order (version 2)", ->
      e = fol.parse "exists y exists x x=y"
      result = symmetry.sortIdentityStatements(e)
      expectedResult = fol.parse "exists y exists x x=y"
      expect( util.areIdenticalExpressions(result, expectedResult) ).to.be.true

      
  describe "eliminateRedundancyInPNF", ->    
    it "should not alter the truth table of propositional sentences"
    # TODO
    
    it "should transform A or (not a=a or not A)", ->
      e = fol.parse "A or (not a=a or not A)"
      result = symmetry.eliminateRedundancyInPNF(e)
      expectedResult = fol.parse "true"
      expect( util.areIdenticalExpressions(result, expectedResult) ).to.be.true
  
  
  describe "isVariableFree", ->
    it "should report that x is free", ->
      e = fol.parse "R(x,y)"
      expect( symmetry.isVariableFree('x',e) ).to.be.true
    it "should report that x is free when there's a quantifier", ->
      e = fol.parse "all y R(x,y)"
      expect( symmetry.isVariableFree('x',e) ).to.be.true
    it "should report that x is free when there's a quantifier but x isn't in its scope", ->
      e = fol.parse "all y R(x,y) and exists x F(x)"
      expect( symmetry.isVariableFree('x',e) ).to.be.true
    it "should report that x is not free when it doesn't appear", ->
      e = fol.parse "R(z,y)"
      expect( symmetry.isVariableFree('x',e) ).to.be.false
    it "should report that x is not free when it is bound", ->
      e = fol.parse "all x R(x,y)"
      expect( symmetry.isVariableFree('x',e) ).to.be.false
    it "should report that x is not free in 'exists x all y F(x)'", ->
      e = fol.parse "exists x all y F(x)"
      expect( symmetry.isVariableFree('x',e) ).to.be.false
  
  
  describe "removeQuantifiersThatBindNothing", ->
    it "should remove a single quantifier", ->
      e = fol.parse "exists x A"
      result = symmetry.removeQuantifiersThatBindNothing e
      expectedResult = fol.parse 'A'
      expect( util.areIdenticalExpressions(result, expectedResult) ).to.be.true
    
    it "should remove an inner quantifier", ->
      e = fol.parse "exists x all y F(x)"
      result = symmetry.removeQuantifiersThatBindNothing e
      expectedResult = fol.parse 'exists x F(x)'
      util.delExtraneousProperties(result)
      util.delExtraneousProperties(expectedResult)
      # console.log "result = #{JSON.stringify result,null,4}"
      # console.log "result = #{util.expressionToString result}"
      expect(result).to.deep.equal(expectedResult)

    it "should remove an outer quantifier", ->
      e = fol.parse "exists x all y F(y)"
      result = symmetry.removeQuantifiersThatBindNothing e
      expectedResult = fol.parse 'all y F(y)'
      util.delExtraneousProperties(result)
      util.delExtraneousProperties(expectedResult)
      expect(result).to.deep.equal(expectedResult)

    it "should remove a middle quantifier", ->
      e = fol.parse "exists x exists y all z R(x,z)"
      result = symmetry.removeQuantifiersThatBindNothing e
      expectedResult = fol.parse 'exists x all z R(x,z)'
      util.delExtraneousProperties(result)
      util.delExtraneousProperties(expectedResult)
      expect(result).to.deep.equal(expectedResult)

    it "should remove multiple quantifiers", ->
      e = fol.parse "exists x exists y all z F(x)"
      result = symmetry.removeQuantifiersThatBindNothing e
      expectedResult = fol.parse 'exists x F(x)'
      util.delExtraneousProperties(result)
      util.delExtraneousProperties(expectedResult)
      expect(result).to.deep.equal(expectedResult)
    