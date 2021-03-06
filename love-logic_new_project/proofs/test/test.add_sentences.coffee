_ = require 'lodash'

util = require 'util'

chai = require('chai')
assert = chai.assert
expect = chai.expect
should = chai.should()

fol = require '../../parser/awFOL'


bp = require '../block_parser'
ln = require '../add_line_numbers'
addJustification = require '../add_justification'
addSentences = require '../add_sentences'

INPUT = "1 A and B // premise \n 2.1 all(x) F(x) \n 2.2 // and elim 1\n\n 3.1 A and //assumption\n 3.2 x=y // invalid justification and or elim\n  3.2.1 A arrow B // and elim missing numbers\n4 some x F(x) //reit 1"
BLOCK = bp.parse INPUT
ln.to BLOCK
addJustification.to BLOCK

_parse = (proofText) ->
  proof = bp.parse proofText
  ln.to proof
  addJustification.to proof
  addSentences.to proof
  return proof

describe "add_sentences", ->
  describe ".to", ->
    it "doesn't throw", ->
      addSentences.to BLOCK
      #console.log BLOCK.toString()
    it "adds sentences", ->
      addSentences.to BLOCK
      expect( BLOCK.getLine(2).sentence.type ).to.equal('universal_quantifier')
    it "still works if you call it twice", ->
      addSentences.to BLOCK
      addSentences.to BLOCK
      expect( BLOCK.getLine(2).sentence.type ).to.equal('universal_quantifier')
    it "adds error messages", ->
      addSentences.to BLOCK
      lineWithError = BLOCK.getLine(5)
      expect( lineWithError.sentenceErrors.slice(0,5) ).to.equal('Parse')  
    it "tells you when a line has a syntax error", ->
      proofText = 'hello\nbye'
      proof = _parse proofText
      line = proof.getLine(1)
      expect(line.sentenceErrors?).to.be.true
      expect(line.sentenceErrors.length>0).to.be.true

  describe ".canBeDecomposed", ->
    it "tells you when a sentence can be decomposed", ->
      proof = _parse "not not A"
      line = proof.getLine(1)
      line.canBeDecomposed().should.be.true
    it "tells you when a sentence cannot be decomposed", ->
      proof = _parse "not A"
      line = proof.getLine(1)
      line.canBeDecomposed().should.be.false
    it "tells you that an identity sentence cannot be decomposed", ->
      proof = _parse "a=b"
      line = proof.getLine(1)
      line.canBeDecomposed().should.be.false
    it "tells you that a negated identity sentence cannot be decomposed", ->
      proof = _parse "not a=b"
      line = proof.getLine(1)
      line.canBeDecomposed().should.be.false
      
        
  