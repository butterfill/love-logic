chai = require('chai')
assert = chai.assert
expect = chai.expect
substitute = require('../substitute')
fol = require('../fol')
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


  describe "sortPNFExpression", ->
    it "should order some expressions", ->
      theF = [ 
        fol.parse 'exists x (F(x) and all y (F(y) arrow x=y))'
        fol.parse 'exists x (all y (F(y) arrow x=y) and F(x))'
        fol.parse 'exists x all y (F(y) ↔ x=y)'
        fol.parse 'exists x F(x) and exists x all y ( F(y) arrow x=y )'
      ]
      pnf = ( substitute.prenexNormalForm(e) for e in theF )
      pnf = ( symmetry.sortPNFExpression(e) for e in pnf )
      for e in pnf
        console.log "the F : #{util.expressionToString e} "
      expect( util.areIdenticalExpressions(pnf[0], pnf[1]) ).to.be.true
      
