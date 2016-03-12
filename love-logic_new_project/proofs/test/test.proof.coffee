chai = require 'chai' 
expect = chai.expect
_ = require 'lodash'

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
    