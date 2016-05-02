chai = require 'chai' 
expect = chai.expect
should = chai.should()
_ = require 'lodash'

dialectManager = require('../../dialect_manager/dialectManager')
proof = require '../proof'

describe "proof", ->
  describe ".parse", ->
    it "parses a proof", ->
      proofText = '''
        1. A      // premise
        2. A and B  
      '''
      theProof = proof.parse proofText
      expect(_.isString (theProof)).to.be.false
      expect(theProof.type).to.equal('block')
      
    it "returns a string if the proof can't be parsed", ->
      proofText = '''
        1. A      // premise
        1. A and B  
      '''
      theProof = proof.parse proofText
      console.log theProof
      expect(_.isString (theProof)).to.be.true

    it "returns a string if the proof can't be parsed because of dodgy indentation", ->
      proofText = '''
        1.    A      // premise
        2. A and B  
      '''
      theProof = proof.parse proofText
      console.log theProof
      expect(_.isString (theProof)).to.be.true

    it "provides .getLine for getting individual lines of a proof", ->
      proofText = '''
        1. A and B      // premise
        2. A            // and elim 1  
      '''
      theProof = proof.parse proofText
      expect(_.isString (theProof)).to.be.false
      aLine = theProof.getLine(2)
      expect(aLine.type).to.equal('line')

    it "enables us to verify individual lines", ->
      proofText = '''
        1. A and B      // premise
        2. A            // and elim 1  
      '''
      theProof = proof.parse proofText
      expect(_.isString (theProof)).to.be.false
      aLine = theProof.getLine(2)
      result = aLine.verify()
      expect(result).to.be.true

    it "enables us to verify whole proofs", ->
      proofText = '''
        1. A and B      // premise
        2. A            // and elim 1  
      '''
      theProof = proof.parse proofText
      result = theProof.verify()
      expect(result).to.be.true
    
    it "enables us to get errors associated with a single line"
    it "enables us to get errors associated with each line of the proof"
    
    it "verifies a simple proof", ->
      text = '''
        | A
        | C
        |---
        | B or C						// or intro 2
        | 
        | A ∧ (B ∨ C )			// and intro 1, 4
      '''
      theProof = proof.parse text
      result = theProof.verify()
      expect(result).to.be.true

    
    it "allows blank lines without messing up justification", ->
      proofText = '''
        | A
        | ---
        | | B
        | | ---
        | | 
        | | B				// reit 3
      '''
      theProof = proof.parse proofText
      result = theProof.verify()
      expect(result).to.be.true
    
    it "allows Copi-style use of the |", ->
      proofText = '''
        B
         | A
         | B         reit 1
        A arrow B    arrow intro 2-3
      '''
      theProof = proof.parse proofText
      result = theProof.verify()
      expect(result).to.be.true
      
  describe ".toString", ->
    it "adds line numbers where necessary", ->
      proofText = '''
        | A
        | ---
        | | B
        | | B				// reit 3
      '''
      theProof = proof.parse proofText
      console.log theProof.toString()
      expect(theProof.toString()[0]).to.equal('1')
    it "adds does not add line numbers where unnecessary", ->
      proofText = '''
        | A
        | ---
        | | B
        | | ---
        | | B				// reit 3
      '''
      theProof = proof.parse proofText
      console.log theProof.toString()
      expect(theProof.toString()[0]).not.to.equal('1')
      
  describe ".clone", ->
    it "enables you to clone a proof", ->
      theProof = proof.parse '''
        | A
        | ---
        | | B
        | | B				// reit 3
      '''
      a = theProof.clone()
      a.toString().indexOf('---').should.not.equal(-1)
      a.toString().indexOf('A').should.not.equal(-1)
      a.toString().indexOf('B').should.not.equal(-1)
      a.toString().indexOf('|').should.not.equal(-1)
      
  describe ".detachChildren", ->
    it "enables you to detach children from a", ->
      theProof = proof.parse '''
        | A
        | ---
        | | B
        | | B				// reit 3
      '''
      {childlessProof, children} = theProof.detachChildren()
      childlessProof.getChildren().length.should.equal(0)

  describe ".convertToSymbols", ->
    it "leaves lines with sentences containing syntax errors intact", ->
      theProof = proof.parse '''
        | blah
      '''
      txt = theProof.toString({replaceSymbols:true})
      txt.indexOf('blah').should.not.equal(-1)
    it "leaves lines containing justification with syntax errors intact", ->
      theProof = proof.parse '''
        | A     // blah
      '''
      txt = theProof.toString({replaceSymbols:true})
      txt.indexOf('blah').should.not.equal(-1)
            