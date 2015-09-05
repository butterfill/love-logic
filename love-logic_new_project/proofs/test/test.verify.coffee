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

verify = require '../verify'

PRF1 = '''
1. hello    // premise
2. A and B  // duff justification
'''

describe "the verify module:", ->
  describe "general features (not specific to any rule) include that it", ->
    it "tells you when a line has a syntax error", ->
      result = verify.line 1, PRF1
      expect(result.verified).to.be.false
      expect(_.isString(result.sentenceErrors)).to.be.true
      # console.log "result.message = #{result.message}"
      # console.log "result.sentenceErrors = #{result.sentenceErrors}"

    it "tells you when a line has faulty justification", ->
      result = verify.line 2, PRF1
      expect(result.verified).to.be.false
      expect(_.isString(result.justificationErrors)).to.be.true
      # console.log "result.message = #{result.message}"

    it "tells you when you incorrectly cite a line from a closed block", ->
      proof = '''
        1. hello    // premise
        2. A and B  // duff justification
        |  3. you can't cite this from 5.
        |  4. A
        5. A // and elim 3.
      '''
      result = verify.line 5, proof
      expect(result.verified).to.be.false
      # console.log "result.message = #{result.message}"
      
    it "tells you when you forget to cite a line", ->
      proof = '''
        1. A and B    // premise
        2. A        // and elim
      '''
      result = verify.line 2, proof
      #console.log "result.message = #{result.message}"
      expect(result.verified).to.be.false
      
    it "tells you when you incorrectly cite a block rather than a line", ->
      proof = '''
        1. hello      // premise
        |  2. A and B
        |  3. A and B
        4. A          // and elim 2-3.
      '''
      result = verify.line 4, proof
      #console.log "result.message = #{result.message}"
      expect(result.verified).to.be.false

    it "tells you when you incorrectly cite a line from later in the proof", ->
      proof = '''
        1. hello    // premise
        2. A        // and elim 5
        |  3. you can't cite this from 5.
        |  4. 
        5. A and B // and elim 3.
      '''
      result = verify.line 2, proof
      expect(result.verified).to.be.false
      # console.log "result.message = #{result.message}"
      
    it "Tells you when you incorrectly cite a line that doesn't exist", ->
      proof = '''
        1. hello    // premise
        2. A        // and elim 5
      '''
      result = verify.line 2, proof
      expect(result.verified).to.be.false
      # console.log "result.message = #{result.message}"
      
    it "Tells you when you incorrectly cite a line that doesn't exist", ->
      proof = '''
        1. hello    // premise
        2. A        // and elim 5
      '''
      result = verify.line 2, proof
      expect(result.verified).to.be.false
      # console.log "result.message = #{result.message}"

  # The `test` object provides conditions used in verifying rules.
  describe "the `test` object", ->
    it "detects when a block and line is cited", ->
      proofText = '''
        1. hello
        2.    block start
        3.    block end
        4. cite block and line  // exists elim 1, 2-3
      ''' 
      proof = verify._parseProof proofText
      line = proof.goto 4
      result = verify._test.lineAndBlockCited(line)
      expect(result).to.equal(true)
      
    it "detects when a block and line is not cited", ->
      proofText = '''
        1. hello
        2.    block start
        3.    block end
        99blank.
        4.    block2 start
        5.    block2 end
        6. cite block and line  // exists elim 2-3, 5-6
      ''' 
      proof = verify._parseProof proofText
      line = proof.goto 6
      result = verify._test.lineAndBlockCited(line)
      expect(result).not.to.equal(true)
      
    it "tells you when you use a rule that doesn't exist (e.g. and intro left)", ->
      proof = '''
        1. A          
        2. B
        3. A and B    // and intro left 1, 2
      ''' 
      result = verify.line 3, proof
      console.log "result.message = #{result.message}" if result.verified is false
      expect(result.verified).to.be.false
      


  describe "proofs with reit", ->
    it "confirms correct use of reit", ->
      proof = '''
        1. A          // premise
        2. A          // reit 1
      '''
      result = verify.line 2, proof
      console.log "result.message = #{result.message}" if result.verified is false
      expect(result.verified).to.be.true

    it "detects incorrect use of reit", ->
      proof = '''
        1. B          // premise
        2. A          // reit 1
      '''
      result = verify.line 2, proof
      # console.log "result.message = #{result.message}"
      expect(result.verified).to.be.false

  describe "proofs with the rules for and", ->
    it "verifies correct use of and elim left", ->
      proof = '''
        1. A and B    // premise
        2. A          // and elim left 1
      '''
      result = verify.line 2, proof
      expect(result.verified).to.be.true
      
    it "identifies incorrect use of and elim left", ->
      proof = '''
        1. A and B     // premise
        2. B          // and elim left 1
      '''
      result = verify.line 2, proof
      expect(result.verified).to.be.false

    it "verifies correct use of and elim right", ->
      proof = '''
        1. A and B    // premise
        2. B          // and elim right 1
      '''
      result = verify.line 2, proof
      expect(result.verified).to.be.true
      
    it "identifies incorrect use of and elim right", ->
      proof = '''
        1. A and B     // premise
        2. A          // and elim  right 1
      '''
      result = verify.line 2, proof
      expect(result.verified).to.be.false

    it "verifies correct use of and elim ", ->
      proof = '''
        1. A and B     // premise
        2. A          // and elim 1
      '''
      result = verify.line 2, proof
      expect(result.verified).to.be.true
      
    it "identifies incorrect use of and elim ", ->
      proof = '''
        1. A or B     // premise
        2. A          // and elim 1
      '''
      result = verify.line 2, proof
      expect(result.verified).to.be.false
      
    it "identifies incorrect use of and elim (wrong conjuncts)", ->
      proof = '''
        1. A and B     // premise
        2. C          // and elim 1
      '''
      result = verify.line 2, proof
      expect(result.verified).to.be.false

    it "verifies correct use of `and intro` ", ->
      proof = '''
        1. A           // premise
        2. B
        3. A and B     // and intro 1,2
      '''
      result = verify.line 3, proof
      expect(result.verified).to.be.true

    it "verifies correct use of and intro for A and A citing the same line twice", ->
      proof = '''
        1. A           // premise
        2. B
        3. A and A     // and intro 1,1
      '''
      result = verify.line 3, proof
      expect(result.verified).to.be.true

    it "identifies incorrect use of and intro (wrong connective)", ->
      proof = '''
        1. A          // premise
        2. B          // premise
        3. A or B     // and intro 1,2
      '''
      result = verify.line 3, proof
      expect(result.verified).to.be.false
      
    it "identifies incorrect use of and intro (wrong lines cited)", ->
      proof = '''
        1. A            // premise
        2. C            // premise
        3. A or B       // and intro 1,2
      '''
      result = verify.line 3, proof
      expect(result.verified).to.be.false


  describe "proofs with the rules for exists", ->
    it "verifies correct use of exists intro", ->
      proof = '''
        1. F(a)           // premise
        2. exists x F(x)  // exists intro 1
      '''
      result = verify.line 2, proof
      #console.log "result.message = #{result.message}"
      expect(result.verified).to.be.true

    it "spots mistaken use of exists intro (wrong premise)", ->
      proof = '''
        1. F(a) and G(a)  // premise
        2. exists x F(x)  // exists intro 1
      '''
      result = verify.line 2, proof
      expect(result.verified).to.be.false

    it "spots mistaken use of exists intro (wrong conclusion)", ->
      proof = '''
        1. F(a)           // premise
        2. exists x G(x)  // exists intro 1
      '''
      result = verify.line 2, proof
      expect(result.verified).to.be.false

    it "spots mistaken use of exists intro (wrong quantifier)", ->
      proof = '''
        1. F(a)           // premise
        2. some x G(x)  // exists intro 1
      '''
      result = verify.line 2, proof
      expect(result.verified).to.be.false

    it "verifies correct use of exists elim", ->
      proof = '''
        1. exists x F(x)    // premise
        2.    F(a)          // assumption
        3.    contradiction //
        4. contradiction    // exists elim 1, 2-3
      '''
      result = verify.line 4, proof
      expect(result.verified).to.be.true

    it "spots mistaken use of exists elim where the conclusion doesn't match the conclusion of the subproof", ->
      proof = '''
        1. exists x F(x)    // premise
        2.    F(a)          // assumption
        3.    F(a)          // reit 2
        4. contradiction    // exists elim 1, 2-3
      '''
      result = verify.line 4, proof
      expect(result.verified).to.be.false

    it "spots mistaken use of exists elim where the new name is in the conclusion", ->
      proof = '''
        1. exists x F(x)    // premise
        2.    F(a)          // assumption
        3.    F(a)          // reit 2
        4. F(a)             // exists elim 1, 2-3
      '''
      result = verify.line 4, proof
      expect(result.verified).to.be.false

