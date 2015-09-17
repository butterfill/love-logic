# TODO: this combines tests for the `verify` module 
# with tests for `fitch_rules`.
#
#

_ = require 'lodash'

util = require 'util'

chai = require('chai')
assert = chai.assert
expect = chai.expect

fol = require '../../parser/awFOL'
util = require '../../util'

bp = require '../block_parser'
ln = require '../add_line_numbers'
addJustification = require '../add_justification'
addSentences = require '../add_sentences'
addStatus = require '../add_status'

verify = require '../add_verification'

PRF1 = '''
1. hello    // premise
2. A and B  // duff justification
'''

_parse = (proofText) ->
  block = bp.parse proofText
  ln.to block
  addJustification.to block
  addSentences.to block
  addStatus.to block
  return block

describe "the verify module:", ->
  describe "`.getPremises` (added to blocks in proof)", ->
    it "returns the premises of a proof", ->
      proofText = '''
        | (A->B)
        | (B->C)
        |---
        | A->B			// and elim 1
        | B->C			// and elim 1
        | |  A				
        | |---
        | |  B				// arrow elim 3,5
        | |  C				// arrow elim 4,7
        | A->C		// arrow intro 5-8
      '''
      proof = _parse proofText
      premises = proof.getPremises()
      expect(premises.length).to.equal(2)
      expectedPremise1 = fol.parse 'A->B'
      expectedPremise1 = util.delExtraneousProperties expectedPremise1 
      premises[0] = util.delExtraneousProperties premises[0]
      expect(premises[0]).to.deep.equal(expectedPremise1)
      expectedPremise2 = fol.parse 'B->C'
      expectedPremise2 = util.delExtraneousProperties expectedPremise2
      premises[1] = util.delExtraneousProperties premises[1]
      expect(premises[1]).to.deep.equal(expectedPremise2)
    it "returns [] when the proof has no premises", ->
      proofText = '''
        | 
        |---
        | A->B			// and elim 1
        | B->C			// and elim 1
        | |  A				
        | |---
        | |  B				// arrow elim 3,5
        | |  C				// arrow elim 4,7
        | A->C		// arrow intro 5-8
      '''
      proof = _parse proofText
      premises = proof.getPremises()
      expect(premises.length).to.equal(0)
      expect(premises).to.deep.equal([])
      
    it "treats [a] as a premise"
  describe "`._linesCitedAreOk`", ->
    it "(preliminary to tests) confirms correct citations", ->
      proofText = '''
        1. | (A->B)&(B->C)
        2. |---
        3. | A->B			// and elim 1
        4. | B->C			// and elim 1
        5. | |  A				
        6. | |---
        7. | |  B				// arrow elim 3,5
        8. | |  C				// arrow elim 4,7
        9. | A->C		// arrow intro 5-8
      '''
      proof = _parse proofText
      nofLines = proofText.split('\n').length
      for n in [1..nofLines] when not (n in [2,6])
        aLine = proof.getLine(n)
        expect(verify._linesCitedAreOk(aLine)).to.be.true

    it "objects when you cite a line from a closed subproof"
    it "objects when you cite a subproof from a closed subproof", ->
        proof = _parse '''
          1. | (A->B)&(B->C)
          2. |---
          3. | A->B			
          4. | B->C			
          5. | |  A				
          6. | |---
          7. | |  B				
          8. | | | C			
          9. | | |---
          10.| | | A->C		
          11.| A          // arrow elim 8-10
        '''
        aLine = proof.getLine(11)
        expect(verify._linesCitedAreOk(aLine)).not.to.be.true
        
    it "objects when you cite a subproof from within it", ->
        proof = _parse '''
          1. | (A->B)&(B->C)
          2. |---
          3. | A->B			
          4. | B->C			
          5. | |  A				
          6. | |---
          7. | |  B				
          8. | |  C				
          9. | | A->C		// arrow intro 5-9
        '''
        aLine = proof.getLine(9)
        expect(verify._linesCitedAreOk(aLine)).not.to.be.true
        console.log verify._linesCitedAreOk(aLine)
        expect(verify._linesCitedAreOk(aLine).search("close it")).not.to.equal(-1)
        
    it "objects when you cite a subproof that ends with a subsubproof", ->
        proof = _parse '''
          1. | (A->B)&(B->C)
          2. |---
          3. | A->B			
          4. | B->C			
          5. | |  A				
          6. | |---
          7. | |  B				
          8. | | | C			
          9. | | |---
          10.| | | A->C		
          11.| A          // arrow elim 5-10
        '''
        # Test the test
        aLine = proof.getLine(11)
        expect(verify._linesCitedAreOk(aLine)).not.to.be.true
        expect(verify._linesCitedAreOk(aLine).search("close it")).not.to.equal(-1)
    
    it "objects when you cite a subproof from deep within it", ->
        proof = _parse '''
          1. | (A->B)&(B->C)
          2. |---
          3. | A->B			// and elim 1
          4. | B->C			// and elim 1
          5. | |  A				
          6. | |---
          7. | |  B				
          8. | | | C				// arrow elim 4,7
          9. | | |---
          10.| | | A->C		// arrow elim 5-10
          11.| A          // arrow elim 5-10
        '''
        aLine = proof.getLine(10)
        expect(verify._linesCitedAreOk(aLine)).not.to.be.true
        console.log verify._linesCitedAreOk(aLine)
        expect(verify._linesCitedAreOk(aLine).search("close it")).not.to.equal(-1)
    it "objects when you cite a badly formed  line", ->
        proof = _parse '''
          1. | *&()&SD_
          2. |---
          3. | A->B			// and elim 1
        '''
        aLine = proof.getLine(3)
        expect(aLine.justification?).to.be.true
        expect(verify._linesCitedAreOk(aLine)).not.to.be.true
    it "objects when you cite a blank line", ->
        proof = _parse '''
          1. | 
          2. |---
          3. | A->B			// and elim 1
        '''
        aLine = proof.getLine(3)
        expect(aLine.justification?).to.be.true
        expect(verify._linesCitedAreOk(aLine)).not.to.be.true
    it "objects when you cite a block whose first line is badly formed", ->
        proof = _parse '''
          1. | (A->B)&(B->C)
          2. |---
          3. | A->B			
          4. | B->C			
          5. | |  %^&*(	
          6. | |---
          7. | |  B			
          8. | |  C			
          9. | A->C		// arrow intro 5-8
        '''
        aLine = proof.getLine(9)
        expect(aLine.justification?).to.be.true
        expect(verify._linesCitedAreOk(aLine)).not.to.be.true
    it "objects when you cite a block whose first line is blank", ->
        proof = _parse '''
          1. | (A->B)&(B->C)
          2. |---
          3. | A->B			
          4. | B->C			
          5. | |
          6. | |---
          7. | |  B			
          8. | |  C			
          9. | A->C		// arrow intro 5-8
        '''
        aLine = proof.getLine(9)
        expect(aLine.justification?).to.be.true
        expect(verify._linesCitedAreOk(aLine)).not.to.be.true
    it "allows you to cite a block that starts with a box", ->
        proof = _parse '''
          1. | (A->B)&(B->C)
          2. |---
          3. | A->B			
          4. | B->C			
          5. | | [a]
          6. | |---
          7. | |  F(x)			
          8. | |  false		
          9. | false		// exists elim 5-8
        '''
        aLine = proof.getLine(9)
        expect(aLine.justification?).to.be.true
        expect(verify._linesCitedAreOk(aLine)).to.be.true
    it "objects when you cite a block whose last line is badly formed", ->
        proof = _parse '''
          1. | (A->B)&(B->C)
          2. |---
          3. | A->B			
          4. | B->C			
          5. | |  A			
          6. | |---
          7. | |  B			
          8. | |  ^&*%$)
          9. | A->C		// arrow intro 5-8
        '''
        aLine = proof.getLine(9)
        expect(aLine.justification?).to.be.true
        expect(verify._linesCitedAreOk(aLine)).not.to.be.true
    it "objects when you cite a block whose last line is blank", ->
        proof = _parse '''
          1. | (A->B)&(B->C)
          2. |---
          3. | A->B			
          4. | B->C			
          5. | |  A			
          6. | |---
          7. | |  B			
          8. | |
          9. | A->C		// arrow intro 5-8
        '''
        aLine = proof.getLine(9)
        expect(aLine.justification?).to.be.true
        expect(verify._linesCitedAreOk(aLine)).not.to.be.true
    it "does not object when you cite a block with a badly formed  middle line", ->
        proof = _parse '''
          1. | (A->B)&(B->C)
          2. |---
          3. | A->B			
          4. | B->C			
          5. | |  A			
          6. | |---
          7. | |  &(*%*%
          8. | |  C			
          9. | A->C		// arrow intro 5-8
        '''
        aLine = proof.getLine(9)
        expect(aLine.justification?).to.be.true
        expect(verify._linesCitedAreOk(aLine)).to.be.true
      
  
  describe "`verifyLine` (aka `_line`)", ->
    it "refuses to verify when a line has a syntax error", ->
      proofText = 'hello\nbye'
      proof = _parse proofText
      line = proof.getLine(1)
      result = verify._line line, PRF1
      expect(result).to.be.false

    it "refuses to verify when a line has faulty justification", ->
      result = verify._line 2, PRF1
      expect(result).to.be.false
    it "refuses to verify when a line has no justification", ->
      proof = _parse '''
        1. A      // premise
        2. A and B  
      '''
      result = verify._line 2, proof
      expect(result).to.be.false
    it "refuses to verify when a line has blank justification", ->
      proof = '''
        1. A          // premise
        2. A and B    //   
      '''
      result = verify._line 2, proof
      expect(result).to.be.false

    it "tells you when you incorrectly cite a line from a closed block", ->
      proof = '''
        1. hello    // premise
        2. A and B  // duff justification
        |  3. you can't cite this from 5.
        |  4. A
        5. A // and elim 3.
      '''
      result = verify._line 5, proof
      expect(result).to.be.false
      # console.log "result.message = #{result.message}"
      
    it "tells you when you forget to cite a line", ->
      proof = '''
        1. A and B    // premise
        2. A        // and elim
      '''
      result = verify._line 2, proof
      #console.log "result.message = #{result.message}"
      expect(result).to.be.false
      
    it "tells you when you incorrectly cite a block rather than a line", ->
      proof = '''
        1. hello      // premise
        |  2. A and B
        |  3. A and B
        4. A          // and elim 2-3.
      '''
      result = verify._line 4, proof
      #console.log "result.message = #{result.message}"
      expect(result).to.be.false

    it "tells you when you incorrectly cite a line from later in the proof", ->
      proof = '''
        1. hello    // premise
        2. A        // and elim 5
        |  3. you can't cite this from 5.
        |  4. 
        5. A and B // and elim 3.
      '''
      result = verify._line 2, proof
      expect(result).to.be.false
      # console.log "result.message = #{result.message}"
      
    it "tells you when you incorrectly cite a line that doesn't exist", ->
      proof = '''
        1. hello    // premise
        2. A        // and elim 5
      '''
      result = verify._line 2, proof
      expect(result).to.be.false
      # console.log "result.message = #{result.message}"
      
    it "objects when you cite the subproof you are in", ->
      proof = '''
        1. A or B    // premise
        2.    A         // assumption
        3.    C         // 
        4.
        5.    B
        6.    C       // or elim 1, 2-3, 4-5
      '''
      result = verify._line 6, proof
      expect(result).to.be.false


  describe "boxes are tricky", ->
    it "lets you use and elim to get from `[a] F(a) and G(a)` to `F(a)`", ->
      proof = '''
        1. exists x (F(x) and G(x))   // premise
        2. not F(a)                   // premise
        3.    [a] F(a) and G(a)       // assumption
        4.    F(a)                    // and elim 3
        5.    contradiction           // contradiction intro 2,4
        6. contradiction              // exists elim 1, 3-5
      '''
      result = verify._line 4, proof
      expect(result).to.be.false

    it "lets you use and reit to get from `[a] F(a)` to `F(a)`", ->
      proof = '''
        1. exists x F(x)              // premise
        2. not F(a)                   // premise
        3.    [a] F(a)                // assumption
        4.    F(a)                    // reit 3
        5.    contradiction           // contradiction intro 2,4
        6. contradiction              // exists elim 1, 3-5
      '''
      result = verify._line 4, proof
      expect(result).to.be.false


  describe "proofs with reit", ->
    it "confirms correct use of reit", ->
      proof = '''
        1. A          // premise
        2. A          // reit 1
      '''
      result = verify._line 2, proof
      console.log "result.message = #{result.message}" if result.verified is false
      expect(result).to.be.true

    it "detects incorrect use of reit", ->
      proof = '''
        1. B          // premise
        2. A          // reit 1
      '''
      result = verify._line 2, proof
      # console.log "result.message = #{result.message}"
      expect(result).to.be.false


  describe "proofs with the rules for and", ->
    it "verifies correct use of and elim left", ->
      proof = '''
        1. A and B    // premise
        2. A          // and elim left 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.true
      
    it "identifies incorrect use of and elim left", ->
      proof = '''
        1. A and B     // premise
        2. B          // and elim left 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.false

    it "verifies correct use of and elim right", ->
      proof = '''
        1. A and B    // premise
        2. B          // and elim right 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.true
      
    it "identifies incorrect use of and elim right", ->
      proof = '''
        1. A and B     // premise
        2. A          // and elim  right 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.false

    it "verifies correct use of and elim ", ->
      proof = '''
        1. A and B     // premise
        2. A          // and elim 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.true
      
    it "identifies incorrect use of and elim ", ->
      proof = '''
        1. A or B     // premise
        2. A          // and elim 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.false
      
    it "identifies incorrect use of and elim (wrong conjuncts)", ->
      proof = '''
        1. A and B     // premise
        2. C          // and elim 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.false

    it "verifies correct use of `and intro` ", ->
      proof = '''
        1. A           // premise
        2. B
        3. A and B     // and intro 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.true

    it "verifies correct use of and intro for A and A citing the same line twice", ->
      proof = '''
        1. A           // premise
        2. B
        3. A and A     // and intro 1,1
      '''
      result = verify._line 3, proof
      expect(result).to.be.true

    it "identifies incorrect use of and intro (wrong connective)", ->
      proof = '''
        1. A          // premise
        2. B          // premise
        3. A or B     // and intro 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.false
      
    it "identifies incorrect use of and intro (wrong lines cited)", ->
      proof = '''
        1. A            // premise
        2. C            // premise
        3. A or B       // and intro 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.false


  describe "proofs with the rules for exists", ->
    it "verifies correct use of exists intro", ->
      proof = '''
        1. F(a)           // premise
        2. exists x F(x)  // exists intro 1
      '''
      result = verify._line 2, proof
      #console.log "result.message = #{result.message}"
      expect(result).to.be.true

    it "verifies correct use of exists intro (another example)", ->
      proof = '''
        1. F(a) and all y F(a,y)              // premise
        2. exists x (F(x) and all y F(x,y))   // exists intro 1
      '''
      result = verify._line 2, proof
      #console.log "result.message = #{result.message}"
      expect(result).to.be.true

    it "spots subtle mistake in use of exists intro (another example)", ->
      proof = '''
        1. F(a) and all y F(a,y)              // premise
        2. exists x (F(x) and all y F(y,x))   // exists intro 1
      '''
      result = verify._line 2, proof
      #console.log "result.message = #{result.message}"
      expect(result).to.be.false

    it "spots mistaken use of exists intro (wrong premise)", ->
      proof = '''
        1. F(a) and G(a)  // premise
        2. exists x F(x)  // exists intro 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.false

    it "spots mistaken use of exists intro (wrong conclusion)", ->
      proof = '''
        1. F(a)           // premise
        2. exists x G(x)  // exists intro 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.false

    it "spots mistaken use of exists intro (wrong quantifier)", ->
      proof = '''
        1. F(a)           // premise
        2. some x G(x)  // exists intro 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.false

    it "verifies correct use of exists elim", ->
      proof = '''
        1. exists x F(x)      // premise
        2.    [a] F(a)        // assumption
        3.    contradiction   //
        4. contradiction      // exists elim 1, 2-3
      '''
      result = verify._line 4, proof
      expect(result).to.be.true

    it "verifies correct use of exists elim (more complex example)", ->
      proof = '''
        1. exists x (F(x) and x = b)      // premise
        2.    [a] F(a) and a = b          // assumption
        3.    contradiction               //
        4. contradiction                  // exists elim 1, 2-3
      '''
      result = verify._line 4, proof
      expect(result).to.be.true

    it "does not verify use of exists elim when box is missing", ->
      proof = '''
        1. exists x F(x)    // premise
        2.    F(a)          // assumption
        3.    contradiction //
        4. contradiction    // exists elim 1, 2-3
      '''
      result = verify._line 4, proof
      expect(result).to.be.false

    it "does not verify use of exists elim when box contains a wrong letter", ->
      proof = '''
        1. exists x F(x)    // premise
        2.    [b] F(a)          // assumption
        3.    contradiction //
        4. contradiction    // exists elim 1, 2-3
      '''
      result = verify._line 4, proof
      expect(result).to.be.false

    it "spots mistaken use of exists elim where the conclusion doesn't match the conclusion of the subproof", ->
      proof = '''
        1. exists x F(x)    // premise
        2.    [a] F(a)          // assumption
        3.    F(a)          // reit 2
        4. contradiction    // exists elim 1, 2-3
      '''
      result = verify._line 4, proof
      expect(result).to.be.false

    it "spots mistaken use of exists elim where subproof premise doesn't match the existential statement", ->
      proof = '''
        1. exists x F(x)        // premise
        2.    [a] G(a)          // assumption
        3.    F(a)              // reit 2
        4. contradiction        // exists elim 1, 2-3
      '''
      result = verify._line 4, proof
      expect(result).to.be.false

    it "spots mistaken use of exists elim where the new name is in the conclusion", ->
      proof = '''
        1. exists x F(x)    // premise
        2.    [a] F(a)          // assumption
        3.    F(a)          // reit 2
        4. F(a)             // exists elim 1, 2-3
      '''
      result = verify._line 4, proof
      expect(result).to.be.false


  describe "proofs with the rules for not", ->
    it "verifies correct use of not elim", ->
      proof = '''
        1. not not A    // premise
        2. A            // not elim 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.true
    it "spots an incorrect use of not elim", ->
      proof = '''
        1. not not B    // premise
        2. A            // not elim 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.false
    it "verifies correct use of not intro", ->
      proof = '''
        1. |
        2. | | A              // assumption
        3. | |-------
        4. | | contradiction  // contradiction intro 1,2
        5. | not A            // not intro 2-4
      '''
      result = verify._line 5, proof
      expect(result).to.be.true
    it "spots an correct use of not intro", ->
      proof = '''
           |
        1. | | A              // assumption
           | |-------
        2. | | B              // contradiction intro 1,2
        3. | not A            // not intro 1-2
      '''
      result = verify._line 5, proof
      expect(result).to.be.false

  describe "proofs with the rules for not", ->
    it "verifies correct use of contradiction elim", ->
      proof = '''
        1. contradiction    // premise
        2. A            // contradiction elim 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.true
    it "spots incorrect use of contradiction elim", ->
      proof = '''
        1. A          // premise
        2. A            // contradiction elim 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.false
    it "verifies correct use of contradiction intro", ->
      proof = '''
        1. A              // premise
        2. not A          // premise
        3. contradiction  // contradiction intro 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.true
    it "verifies correct use of contradiction intro (not first)", ->
      proof = '''
        1. not A              // premise
        2. A          // premise
        3. contradiction  // contradiction intro 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.true
    it "verifies correct use of contradiction intro (tricky case, not first)", ->
      # This test fails while `rule`'s methods for checking do not 
      # consider making matches for requirements in differnt orders.
      proof = '''
        1. not A              // premise
        2. not not A          // premise
        3. contradiction  // contradiction intro 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.true
    it "spots mistake in use of contradiction intro (tricky case, not first)", ->
      # This test fails while `rule`'s methods for checking do not 
      # consider making matches for requirements in differnt orders.
      proof = '''
        1. not A              // premise
        2. not not B          // premise
        3. contradiction  // contradiction intro 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.false
    it "verifies correct use of contradiction intro (tricky case, not first)", ->
      # This test could fail if `rule`'s methods for checking did not 
      # consider making matches for requirements in differnt orders.
      proof = '''
        1. not not A              // premise
        2. not A          // premise
        3. contradiction  // contradiction intro 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.true
    it "detects dodgy use of contradiction intro (tricky case)", ->
      proof = '''
        1. not not A          // premise
        2. contradiction      // contradiction intro 1,1
      '''
      result = verify._line 2, proof
      expect(result).to.be.false
      
      
  describe "proofs with the rules for arrow", ->
    it "verifies correct use of arrow elim", ->
      proof = '''
        1. A                // premise
        2. A arrow B        // premise
        3. B                // arrow elim 1,2
      '''
      result = verify._line 3, proof
      console.log result.message if not result.verified
      expect(result).to.be.true
    it "detects mistaken use arrow elim (right to left)", ->
      proof = '''
        1. B                // premise
        2. A arrow B           // premise
        3. A                // arrow elim 1,2
      '''
      result = verify._line 3, proof
      console.log result.message if not result.verified
      expect(result).to.be.false
    it "verifies correct use of arrow intro", ->
      proof = '''
        1. |
        2. | | A                
        3. | |---
        4. | | false             
        5. | C  
        6. | A arrow false        // arrow intro 2-4
      '''
      result = verify._line 6, proof
      console.log result.message if not result.verified
      expect(result).to.be.true
    it "spots incorrect use of arrow intro", ->
      proof = '''
        1. |
        2. | | B                
        3. | |---
        4. | | A       
        5. | C          
        6. | A arrow B        // arrow intro 2-4
      '''
      result = verify._line 6, proof
      console.log result.message if not result.verified
      expect(result).to.be.false
    
    
  describe "proofs with the rules for double_arrow", ->
    it "verifies correct use double_arrow elim", ->
      proof = '''
        1. A                // premise
        2. A ↔ B           // premise
        3. B                // ↔ elim 1,2
      '''
      result = verify._line 3, proof
      console.log result.message if not result.verified
      expect(result).to.be.true
    it "verifies correct use double_arrow elim (right to left)", ->
      proof = '''
        1. B                // premise
        2. A ↔ B           // premise
        3. A                // ↔ elim 1,2
      '''
      result = verify._line 3, proof
      console.log result.message if not result.verified
      expect(result).to.be.true
    it "detects incorrect use double_arrow elim (wrong conclusion)", ->
      proof = '''
        1. B                // premise
        2. A ↔ B           // premise
        3. B                // ↔ elim 1,2
      '''
      result = verify._line 3, proof
      console.log "\t#{result.message}" if not result.verified
      expect(result).to.be.false
    it "detects incorrect use double_arrow elim (wrong arrow) ", ->
      proof = '''
        1. B                // premise
        2. B ↔ B           // premise
        3. A                // ↔ elim 1,2
      '''
      result = verify._line 3, proof
      console.log "\t#{result.message}" if not result.verified
      expect(result).to.be.false
    it "detects incorrect use double_arrow elim (wrong arrow) ", ->
      proof = '''
        1. B                // premise
        2. A ↔ B           // premise
        3. A                // ↔ elim 2,2
      '''
      result = verify._line 3, proof
      console.log "\t#{result.message}" if not result.verified
      expect(result).to.be.false
      
    it "verifies correct use of double_arrow intro", ->
      # This example also illustrates flexibility with line
      # numbering (naming); note that `.getLine` and `verify._line`
      # want the (1-based) number of the line in file, not the 
      # name given to the line by the proof writer.
      proof = '''
        1. |
        2. | | A                
           | |---
        3. | | false             
           |   
        4. | | false
           | |---
        5. | | A
        6. | A ↔ false        // ↔ intro 2-3, 4-5
      '''
      result = verify._line 9, proof
      console.log result.message if not result.verified
      expect(result).to.be.true
      
    it "spots incorrect use of double_arrow intro", ->
      proof = '''
        1. |
        2. | | A                
           | |---
        3. | | | false
           | | |---
        4. | | | A
        5. | | false             
        6. | A ↔ false        // ↔ intro 2-5, 3-4
      '''
      result = verify._line 8, proof
      console.log result.message if not result.verified
      expect(result).to.be.false
    it "spots incorrect use of double_arrow intro", ->
      proof = '''
        1. |
        2. | | A                
        3. | |---
        4. | | false             
        5. | C  
        6. | A ↔ false        // ↔ intro 2-4, 2-4
      '''
      result = verify._line 6, proof
      console.log result.message if not result.verified
      expect(result).to.be.false
    
  describe "proofs with the rules for identity", ->
    it "confirms correct use of =intro", ->
      proof = '''
        1. b=b              // identity intro
      '''
      result = verify._line 1, proof
      expect(result).to.be.true
    it "detects incorrect use of =intro", ->
      proof = '''
        1. b=c              // identity intro
      '''
      result = verify._line 1, proof
      expect(result).to.be.false
    it "confirms correct use of =elim", ->
      proof = '''
        1. a=b              
        2. F(a)
        3. F(b)         // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.true
    it "confirms correct use of =elim (right to left)", ->
      proof = '''
        1. a=b              
        2. F(b)
        3. F(a)         // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.true
    it "detects incorrect use of =elim", ->
      proof = '''
        1. a=b              
        2. G(a)
        3. F(c)         // = elim 1,2
      '''
      result = verify._line 3, proof
      console.log(result.message)
      expect(result).to.be.false
    it "confirms correct use of =elim (reverse lines)", ->
      proof = '''
        1. F(b)
        2. a=b              
        3. F(a)         // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.true
    it "confirms correct use of =elim (complex example)", ->
      proof = '''
        1  all x (x=b arrow (F(x) and G(x)))
        2  A
        3  a=b              
        4  B
        5  all x (x=a arrow (F(x) and G(x)))         // = elim 1,3
      '''
      result = verify._line 5, proof
      expect(result).to.be.true
    it "=elim allows not all substitutions to be made", ->
      # test id AF96B036-57DA-11E5-8511-720262EA09BE
      proof = '''
        1  F(a) and G(a)
        2  a=b              
        3  F(a) and G(b)         // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.true
    it "=elim allows no substitutions to be made", ->
      proof = '''
        1  F(a) 
        2  a=b              
        3  F(a)          // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.true
    it "=elim allows not all substitutions to be made proving a=b therefore b=a", ->
      # test id 69A3AAF2-57DF-11E5-A384-6BFFF2E18425
      proof = '''
        1  a=b
        2  a=a              // = elim              
        3  b=a              // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.true
    it "=elim allows not all substitutions to be made proving a=b therefore b=a (variation)", ->
      proof = '''
        1  a=b
        2  b=b              // = elim              
        3  b=a              // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.true
    it "=elim allows not all substitutions to be made (multiple clauses)", ->
      # test id 2D900196-57DF-11E5-9F54-6BFFF2E18425
      proof = '''
        1  F(a) and a=a and (G(a) and H(a))
        2  a=b              
        3  F(b) and a=b and (G(a) and H(b))         // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.true
    it "=elim weird case (to check `rule` doesn't hang)", ->
      # test id 2518C33E-587C-11E5-B046-B15A631DAC50
      proof = '''
        1  F(a) and G(a)
        2  a=a              
        3  F(a) and G(a)         // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result).to.be.true
    
    
  describe "proofs with the rules for universal", ->
    it "verifies universal elim", ->
      proof = '''
        1. all x F(x)     // premise
        2. F(a)           // universal elim 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.true
    it "spots a mistake with universal elim (predicate)", ->
      proof = '''
        1. all x F(x)     // premise
        2. G(a)           // universal elim 1
      '''
      result = verify._line 2, proof
      expect(result).to.be.false
    it "verifies universal intro", ->
      proof = '''
        1. A
        2.    [a]            // assumption
        3.    F(a)          
        4. all x F(x)        // universal intro 2-3
      '''
      result = verify._line 4, proof
      expect(result).to.be.true
    it "spots a mistake in universal intro", ->
      proof = '''
        1. A
        2.    [a]            // assumption
        3.    F(b)          
        4. all x F(x)        // universal intro 2-3
      '''
      result = verify._line 4, proof
      expect(result).to.be.false
    it "does not let you use universal intro when the name you box is not new", ->
      # test id 454092AA-57A4-11E5-9C09-B0C78BD11E5D
      proof = '''
        1. F(a)
        2.    [a]            // assumption
        3.    F(a)          
        4. all x F(x)        // universal intro 2-3
      '''
      result = verify._line 4, proof
      expect(result).to.be.false
    it "allows you use universal intro when you make only partial replacements", ->
      # test id A7774B7C-57DA-11E5-B920-720262EA09BE
      proof = '''
        1. 
        2.    [a]                   // assumption
        3.    F(a) and G(a)          
        4. all x (F(x) and G(a))    // universal intro 2-3
      '''
      result = verify._line 4, proof
      expect(result).to.be.true

  describe "verifying premises and assumptions", ->
    # Here we just need to test that the rule is implemented;
    # to check that it works we have the tests for the `rule` module.
    it "verifies premises", ->
      proof = '''
        1. A              // assumption
      '''
      result = verify._line 1, proof
      expect(result).to.be.true
      

  describe "complete proofs", ->
    it "verifies all lines of a proof with one subproof", ->
      proof = '''
        | (A->B)&(B->C)
        | ---
        | A->B			// and elim 1
        | B->C			// and elim 1
        | |  A				
        | | ---
        | |  B				// arrow elim 3,5
        | |  C				// arrow elim 4,7
        | A->C		// arrow intro 5-8
      '''
      nofLines = proof.split('\n').length
      for n in [1..nofLines]
        result = verify._line n, proof
        expect(result).to.be.true
    it "verifies all lines of a proof with one subproof (using `proof.verify()`)", ->
      proof = _parse '''
        | (A->B)&(B->C)
        | ---
        | A->B			// and elim 1
        | B->C			// and elim 1
        | |  A				
        | | ---
        | |  B				// arrow elim 3,5
        | |  C				// arrow elim 4,7
        | A->C		// arrow intro 5-8
      '''
      verify.to proof
      expect( proof.verify() ).to.be.true
    it "does not verify all lines of a proof when there are mistakes (using `proof.verify()`)", ->
      proof = _parse '''
        | (A->B)&(B->C)
        | ---
        | A->B			// and elim 1
        | B->C			// and elim 1
        | |  A				
        | | ---
        | |  C				// arrow elim 3,5
        | |  C				// arrow elim 4,7
        | A->C		// arrow intro 5-8
      '''
      verify.to proof
      expect( proof.verify() ).not.to.be.true
      
    it "verifies all lines of a proof with one subproof (no |)", ->
      proof = '''
        (A->B)&(B->C)
        A->B			// and elim 1
        B->C			// and elim 1
          A				
          B				// arrow elim 2,4
          C				// arrow elim 3,5
        A->C		// arrow intro 4-6
      '''
      nofLines = proof.split('\n').length
      for n in [1..nofLines]
        result = verify._line n, proof
        console.log result if not result
        expect(result).to.be.true
    
    it "verifies a proof of ¬∃x (F(x) ∨ ¬ F(x) ) from no premises", ->
      proof = _parse '''
        | 
        |---
        | | ¬∃x (F(x) ∨ ¬ F(x) )
        | |---
        | | | F(a)
        | | |---
        | | | F(a) ∨ ¬ F(a)		// or intro 5
        | | | ∃x (F(x) ∨ ¬ F(x) ) // exists intro 7
        | | | false 				// contradiction intro 3,8
        | | not F(a)			// not intro 5-9
        | | | ¬F(a)
        | | |---
        | | | F(a) ∨ ¬ F(a)		// or intro 10
        | | | ∃x (F(x) ∨ ¬ F(x) ) // exists intro 13
        | | | false					// contradiction intro 3,14
        | | not not F(a)		// negation intro 11-15
        | | false 		//		contradiction intro 10,16
        | ¬¬∃x (F(x) ∨ ¬ F(x) ) // negation intro 3-17
        | ∃x (F(x) ∨ ¬ F(x) )  // negation elim 18
      '''
      verify.to proof
      expect( proof.verify() ).to.be.true
      
    it "provides a sensible message when you make a mistake in citing a subproof of the wrong form", ->
      # TODO: this is a test of the `rule` module.
      proof = _parse '''
        | A → B
        | B → C
        |---
        | | A 
        | | B
        | | D
        | A → C	//arrow intro 4-6
      '''
      verify.to proof
      line = proof.getLine(7)
      result = verify._line line, proof
      console.log line.status.getMessage()
      expect(line.status.getMessage().search('undefined')).to.equal(-1)