_ = require 'lodash'

util = require 'util'

chai = require 'chai'
expect = chai.expect

bp = require '../block_parser'
jp = require '../justification_parser' 
ln = require '../add_line_numbers'
addJustification = require '../add_justification'


INPUT = "1 // premise \n 2.1 no justification \n 2.2 // and elim 1\n\n 3.1 //assumption\n 3.2 // invalid justification and or elim\n  3.2.1 // and elim missing numbers\n4 //reit 1"
BLOCK = bp.parse INPUT

_parse = (input) ->
  block = bp.parse input
  ln.to block
  addJustification.to block
  return block


describe "add_justification", ->
  describe "addJustification", ->
    it "adds justification to a test block", ->
      block = addJustification.to BLOCK
      expect(block.getLastLine().justification.rule.connective).to.equal('reit')
      # console.log BLOCK.toString()
    
    it "calling it twice is not harmful", ->
      block = addJustification.to BLOCK
      block = addJustification.to BLOCK
      expect(block.getLastLine().justification.rule.connective).to.equal('reit')

    it "strips justification from `line.content`", ->
      block = addJustification.to BLOCK
      expect(block.getLine(3).content).to.equal('2.2')

    it "records error messages where justification can't be parsed", ->
      block = addJustification.to BLOCK
      line = block.getLine(6)
      #console.log util.inspect(line)
      expect(line.justificationErrors.slice(0,5)).to.equal('Parse')

    it "doesn't mess with the text of lines missing justification", ->
      block = addJustification.to BLOCK
      expect(block.getLine(2).content.trim()).to.equal(INPUT.split('\n')[1].trim())
    
    it "can treat 3 or more spaces as indicating the start of justification", ->
      r = bp.parse "1 A and B \n2 ---\n3 A   and elim 1"
      block = addJustification.to r
      expect(block.getLine(3).justification.rule.connective).to.equal('and')
    
    it "correctly identifies the justification in a simple proof", ->
      proof = _parse '''
        | A
        | C
        |---
        | B or C						// or intro 2
        | 
        | A ∧ (B ∨ C )			// and intro 1, 4
      '''
      line = proof.getLine(4)
      expect(line.justification.rule.connective).to.equal('or')
      line = proof.getLine(6)
      expect(line.justification.rule.connective).to.equal('and')
    
    it "correctly identifies the justification in a simple proof (where whitespace separates justification)", ->
      proof = _parse '''
        | A
        | C
        |---
        | B or C						or intro 2
        | 
        | A ∧ (B ∨ C )			and intro 1, 4
      '''
      line = proof.getLine(4)
      expect(line.justification.rule.connective).to.equal('or')
      line = proof.getLine(6)
      expect(line.justification.rule.connective).to.equal('and')
    
    it "correctly identifies the justification in a simple proof (no |)", ->
      proof = _parse '''
        (A->B)&(B->C)
        A->B			// and elim 1
        B->C			// and elim 1
          A				
          B				// arrow elim 2,4
          C				// arrow elim 3,5
        A->C		// arrow intro 4-6
      '''
      expect(proof.getLine(2).justification.rule.connective).to.equal('and')
      expect(proof.getLine(6).justification.rule.connective).to.equal('arrow')
      expect(proof.getLine(7).justification.rule.connective).to.equal('arrow')
    
    it "correctly identifies the justification in a simple proof (no |, whitespace separates justification)", ->
      proof = _parse '''
        (A->B)&(B->C)
        A->B			 and elim 1
        B->C			 and elim 1
          A				
          B				 arrow elim 2,4
          C				 arrow elim 3,5
        A->C		 arrow intro 4-6
      '''
      console.log proof.getLine(5)
      expect(proof.getLine(2).justification.rule.connective).to.equal('and')
      expect(proof.getLine(6).justification.rule.connective).to.equal('arrow')
      expect(proof.getLine(7).justification.rule.connective).to.equal('arrow')
    
    
    it "adds justification to premises where necessary", ->
      block = addJustification.to BLOCK
      expect(block.getLine(2).justification.rule.connective).to.equal('premise')
      
    it "adds justification to premises where necessary (longer example)", ->
      proof = _parse '''
        A → B
        B → C
        ---
          A
          B		// arrow elim 1,3
          C		// arrow elim 2,4
        A → C // arrow intro 3-5
      '''
      line = proof.getLine(2)
      expect(addJustification._isPremise(line)).to.be.true
      expect(line.justification.rule.connective).to.equal('premise')

    


    it "adds doesn't add justification to non-premises", ->
      block = bp.parse "1. A\n2. A\n A"
      block = addJustification.to block
      expect(block.getLine(1).justification.rule.connective).to.equal('premise')
      expect(block.getLine(2).justification?).to.be.false

    it "treats everything above the divider as a premise in the outer block", ->
      block = bp.parse "1. A\n2. A\n---\n3. A"
      block = addJustification.to block
      expect(block.getLine(2).justification.rule.connective).to.equal('premise')

    it "doesn't treats everything above the divider as a premise in inner blocks", ->
      block = bp.parse "1. A\n| |2. A\n| |3. A\n| |---\n| |4. A"
      block = addJustification.to block
      expect(block.getLine(2).justification.rule.connective).to.equal('premise')
      expect(block.getLine(3).type).to.equal('line')
      expect(block.getLine(3).justification?).to.be.false
      
    it "only treats the first divider as significant in working out what's a premise in the outer block", ->
      block = bp.parse "1. A\n2. A\n---\n3. A\n---\n4. A"
      block = addJustification.to block
      expect(block.getLine(2).justification.rule.connective).to.equal('premise')
      expect(block.getLine(4).type).to.equal('line')
      expect(block.getLine(4).justification?).to.be.false

    it "enables a line tell you the name of its rule", ->
      ln.to BLOCK
      block = addJustification.to BLOCK
      line = block.getLine 3
      #console.log line.getRuleName()
      expect(line.getRuleName()).to.equal('∧ elim')
      
    it "enables a line to get you the block it references", ->
      input = '''
        1. A
        | 2. A
        | 3. contradiction
        4. not A // not elim 2-3
      '''
      block = _parse input
      expected = block.getLine(2).parent
      line4 = block.getLine 4
      # console.log input
      # console.log block.toString()
      expect(line4.getCitedBlocks()[0]).to.equal(expected)
    
    it "tells you when a line has faulty justification", ->
      proof = _parse '''
        1. A          // premise
        2. A and B    // ayiu aksoupp
      '''
      line = proof.getLine(2)
      expect(line.justification?).to.be.false
      expect(line.justificationErrors?).to.be.true

    it "does not add justification when a line has no justification", ->
      proof = _parse '''
        1. A      // premise
        2. A and B // and intro 1
        3. A and B  
      '''
      line = proof.getLine(3)
      expect(line.justification?).to.be.false

    it "tells you when a line has blank justification", ->
      proof = _parse '''
        1. A          // premise
        2. A and B    //   
      '''
      line = proof.getLine(2)
      expect(line.justification?).to.be.false
      expect(line.justificationErrors?).to.be.true

    