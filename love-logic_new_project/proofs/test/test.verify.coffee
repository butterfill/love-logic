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

describe "verify", ->
  describe "general things (not specific to any rule)", ->
    it "Tells you when a line has a syntax error", ->
      result = verify.line 1, PRF1
      expect(result.verified).to.be.false
      expect(_.isString(result.sentenceErrors)).to.be.true
      # console.log "result.message = #{result.message}"
      # console.log "result.sentenceErrors = #{result.sentenceErrors}"

    it "Tells you when a line has faulty justification", ->
      result = verify.line 2, PRF1
      expect(result.verified).to.be.false
      expect(_.isString(result.justificationErrors)).to.be.true
      # console.log "result.message = #{result.message}"

    it "Tells you when you incorrectly cite a line from a closed block", ->
      proof = '''
        1. hello    // premise
        2. A and B  // duff justification
        |  3. you can't cite this from 5.
        |  4. 
        5. A // and elim 3.
      '''
      result = verify.line 5, proof
      expect(result.verified).to.be.false
      # console.log "result.message = #{result.message}"
      
    it "Tells you when you forget to cite a line", ->
      proof = '''
        1. A and B    // premise
        2. A        // and elim
      '''
      result = verify.line 2, proof
      console.log "result.message = #{result.message}"
      expect(result.verified).to.be.false
      

    it "Tells you when you incorrectly cite a block rather than a line", ->
      proof = '''
        1. hello      // premise
        |  2. A and B
        |  3. A and B
        4. A          // and elim 2-3.
      '''
      result = verify.line 4, proof
      console.log "result.message = #{result.message}"
      expect(result.verified).to.be.false

    it "Tells you when you incorrectly cite a line from later in the proof", ->
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
      console.log "result.message = #{result.message}"
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
      console.log "result.message = #{result.message}"
      expect(result.verified).to.be.false

    it "verifies correct use of and elim ", ->
      proof = '''
        1. A and B     // premise
        2. A          // and elim 1
      '''
      result = verify.line 2, proof
      console.log "result.message = #{result.message}"
      expect(result.verified).to.be.true
      
    it "identifies incorrect use of and elim ", ->
      proof = '''
        1. A or B     // premise
        2. A          // and elim 1
      '''
      result = verify.line 2, proof
      console.log "result.message = #{result.message}"
      expect(result.verified).to.be.false
      
    it "identifies incorrect use of and elim (wrong conjuncts)", ->
      proof = '''
        1. A and B     // premise
        2. C          // and elim 1
      '''
      result = verify.line 2, proof
      console.log "result.message = #{result.message}"
      expect(result.verified).to.be.false
                        