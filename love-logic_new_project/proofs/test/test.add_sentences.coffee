_ = require 'lodash'

util = require 'util'

chai = require('chai')
assert = chai.assert
expect = chai.expect

fol = require '../../parser/awFOL'


bp = require '../block_parser'
ln = require '../add_line_numbers'
addJustification = require '../add_justification'
addSentences = require '../add_sentences'

INPUT = "1 A and B // premise \n 2.1 all(x) F(x) \n 2.2 // and elim 1\n\n 3.1 A and //assumption\n 3.2 x=y // invalid justification and or elim\n  3.2.1 A arrow B // and elim missing numbers\n4 some x F(x) //reit 1"
BLOCK = bp.parse INPUT
ln.to BLOCK
addJustification.to BLOCK

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
      lineWithError = BLOCK.getLine(4)
      expect( lineWithError.sentenceErrors.slice(0,5) ).to.equal('Parse')  
      