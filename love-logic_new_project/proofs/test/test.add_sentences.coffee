_ = require 'lodash'

util = require 'util'

chai = require('chai')
assert = chai.assert
expect = chai.expect

fol = require '../../fol'


bp = require '../block_parser'
ln = require '../line_numbers'
addJustification = require '../add_justification'
addSentences = require '../add_sentences'

INPUT = "1 A and B // premise \n 2.1 all(x) F(x) \n 2.2 // and elim 1\n\n 3.1 A and //assumption\n 3.2 x=y // invalid justification and or elim\n  3.2.1 A arrow B // and elim missing numbers\n4 some x F(x) //reit 1"
BLOCK = bp.parse INPUT
ln.addNumbers BLOCK
addJustification.to BLOCK

describe "add_sentences", ->
  describe "to", ->
    it "doesn't throw", ->
      addSentences.to BLOCK
      #console.log BLOCK.toString()
    it "adds sentences", ->
      addSentences.to BLOCK
      expect( BLOCK.goto(2).sentence.type ).to.equal('universal_quantifier')
    it "still works if you call it twice", ->
      addSentences.to BLOCK
      addSentences.to BLOCK
      expect( BLOCK.goto(2).sentence.type ).to.equal('universal_quantifier')
    it "adds error messages", ->
      addSentences.to BLOCK
      expect( BLOCK.goto(5).sentenceErrors.slice(0,5) ).to.equal('Parse')  
    it "enables lines to tell you whether they are identical to another expression", ->
      addSentences.to BLOCK
      line1 = BLOCK.goto(1)
      e = fol.parse "A and B"
      e2 = fol.parse "A"
      expect( line1.isIdenticalExpression(e) ).to.be.true
      expect( line1.isIdenticalExpression(e2) ).to.be.false
      expect( line1.leftIsIdenticalExpression(e2) ).to.be.true
      expect( line1.rightIsIdenticalExpression( fol.parse("B")) ).to.be.true
      