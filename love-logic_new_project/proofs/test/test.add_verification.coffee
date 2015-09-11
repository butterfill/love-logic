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


bp = require '../block_parser'
ln = require '../add_line_numbers'
addJustification = require '../add_justification'
addSentences = require '../add_sentences'

verify = require '../add_verification'

PRF1 = '''
1. hello    // premise
2. A and B  // duff justification
'''

describe "the verify module:", ->
  describe "`verifyLine` (aka `_line`)", ->
    it "tells you when a line has a syntax error", ->
      result = verify._line 1, PRF1
      expect(result.verified).to.be.false
      expect(_.isString(result.sentenceErrors)).to.be.true
      expect(result.sentenceErrors.length>0).to.be.true
      # console.log "result.message = #{result.message}"
      # console.log "result.sentenceErrors = #{result.sentenceErrors}"

    it "tells you when a line has faulty justification", ->
      result = verify._line 2, PRF1
      expect(result.verified).to.be.false
      expect(_.isString(result.justificationErrors)).to.be.true
      expect(result.justificationErrors.length>0).to.be.true
      # console.log "result.message = #{result.message}"

    it "tells you when a line has no justification", ->
      proof = '''
        1. A      // premise
        2. A and B  
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.false
      test = result.message.length > 0 or _.isString(result.justificationErrors)
      expect(test).to.be.true
      # console.log "result.message = #{result.message}"

    it "tells you when a line has blank justification", ->
      proof = '''
        1. A          // premise
        2. A and B    //   
      '''
      result = verify._line 2, proof
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
      result = verify._line 5, proof
      expect(result.verified).to.be.false
      # console.log "result.message = #{result.message}"
      
    it "tells you when you forget to cite a line", ->
      proof = '''
        1. A and B    // premise
        2. A        // and elim
      '''
      result = verify._line 2, proof
      #console.log "result.message = #{result.message}"
      expect(result.verified).to.be.false
      
    it "tells you when you incorrectly cite a block rather than a line", ->
      proof = '''
        1. hello      // premise
        |  2. A and B
        |  3. A and B
        4. A          // and elim 2-3.
      '''
      result = verify._line 4, proof
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
      result = verify._line 2, proof
      expect(result.verified).to.be.false
      # console.log "result.message = #{result.message}"
      
    it "tells you when you incorrectly cite a line that doesn't exist", ->
      proof = '''
        1. hello    // premise
        2. A        // and elim 5
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.false
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
      expect(result.verified).to.be.false


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
      expect(result.verified).to.be.false

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
      expect(result.verified).to.be.false


  describe "proofs with reit", ->
    it "confirms correct use of reit", ->
      proof = '''
        1. A          // premise
        2. A          // reit 1
      '''
      result = verify._line 2, proof
      console.log "result.message = #{result.message}" if result.verified is false
      expect(result.verified).to.be.true

    it "detects incorrect use of reit", ->
      proof = '''
        1. B          // premise
        2. A          // reit 1
      '''
      result = verify._line 2, proof
      # console.log "result.message = #{result.message}"
      expect(result.verified).to.be.false


  describe "proofs with the rules for and", ->
    it "verifies correct use of and elim left", ->
      proof = '''
        1. A and B    // premise
        2. A          // and elim left 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.true
      
    it "identifies incorrect use of and elim left", ->
      proof = '''
        1. A and B     // premise
        2. B          // and elim left 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.false

    it "verifies correct use of and elim right", ->
      proof = '''
        1. A and B    // premise
        2. B          // and elim right 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.true
      
    it "identifies incorrect use of and elim right", ->
      proof = '''
        1. A and B     // premise
        2. A          // and elim  right 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.false

    it "verifies correct use of and elim ", ->
      proof = '''
        1. A and B     // premise
        2. A          // and elim 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.true
      
    it "identifies incorrect use of and elim ", ->
      proof = '''
        1. A or B     // premise
        2. A          // and elim 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.false
      
    it "identifies incorrect use of and elim (wrong conjuncts)", ->
      proof = '''
        1. A and B     // premise
        2. C          // and elim 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.false

    it "verifies correct use of `and intro` ", ->
      proof = '''
        1. A           // premise
        2. B
        3. A and B     // and intro 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true

    it "verifies correct use of and intro for A and A citing the same line twice", ->
      proof = '''
        1. A           // premise
        2. B
        3. A and A     // and intro 1,1
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true

    it "identifies incorrect use of and intro (wrong connective)", ->
      proof = '''
        1. A          // premise
        2. B          // premise
        3. A or B     // and intro 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.false
      
    it "identifies incorrect use of and intro (wrong lines cited)", ->
      proof = '''
        1. A            // premise
        2. C            // premise
        3. A or B       // and intro 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.false


  describe "proofs with the rules for exists", ->
    it "verifies correct use of exists intro", ->
      proof = '''
        1. F(a)           // premise
        2. exists x F(x)  // exists intro 1
      '''
      result = verify._line 2, proof
      #console.log "result.message = #{result.message}"
      expect(result.verified).to.be.true

    it "verifies correct use of exists intro (another example)", ->
      proof = '''
        1. F(a) and all y F(a,y)              // premise
        2. exists x (F(x) and all y F(x,y))   // exists intro 1
      '''
      result = verify._line 2, proof
      #console.log "result.message = #{result.message}"
      expect(result.verified).to.be.true

    it "spots subtle mistake in use of exists intro (another example)", ->
      proof = '''
        1. F(a) and all y F(a,y)              // premise
        2. exists x (F(x) and all y F(y,x))   // exists intro 1
      '''
      result = verify._line 2, proof
      #console.log "result.message = #{result.message}"
      expect(result.verified).to.be.false

    it "spots mistaken use of exists intro (wrong premise)", ->
      proof = '''
        1. F(a) and G(a)  // premise
        2. exists x F(x)  // exists intro 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.false

    it "spots mistaken use of exists intro (wrong conclusion)", ->
      proof = '''
        1. F(a)           // premise
        2. exists x G(x)  // exists intro 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.false

    it "spots mistaken use of exists intro (wrong quantifier)", ->
      proof = '''
        1. F(a)           // premise
        2. some x G(x)  // exists intro 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.false

    it "verifies correct use of exists elim", ->
      proof = '''
        1. exists x F(x)      // premise
        2.    [a] F(a)        // assumption
        3.    contradiction   //
        4. contradiction      // exists elim 1, 2-3
      '''
      result = verify._line 4, proof
      expect(result.verified).to.be.true

    it "verifies correct use of exists elim (more complex example)", ->
      proof = '''
        1. exists x (F(x) and x = b)      // premise
        2.    [a] F(a) and a = b          // assumption
        3.    contradiction               //
        4. contradiction                  // exists elim 1, 2-3
      '''
      result = verify._line 4, proof
      expect(result.verified).to.be.true

    it "does not verify use of exists elim when box is missing", ->
      proof = '''
        1. exists x F(x)    // premise
        2.    F(a)          // assumption
        3.    contradiction //
        4. contradiction    // exists elim 1, 2-3
      '''
      result = verify._line 4, proof
      expect(result.verified).to.be.false

    it "does not verify use of exists elim when box contains a wrong letter", ->
      proof = '''
        1. exists x F(x)    // premise
        2.    [b] F(a)          // assumption
        3.    contradiction //
        4. contradiction    // exists elim 1, 2-3
      '''
      result = verify._line 4, proof
      expect(result.verified).to.be.false

    it "spots mistaken use of exists elim where the conclusion doesn't match the conclusion of the subproof", ->
      proof = '''
        1. exists x F(x)    // premise
        2.    [a] F(a)          // assumption
        3.    F(a)          // reit 2
        4. contradiction    // exists elim 1, 2-3
      '''
      result = verify._line 4, proof
      expect(result.verified).to.be.false

    it "spots mistaken use of exists elim where subproof premise doesn't match the existential statement", ->
      proof = '''
        1. exists x F(x)        // premise
        2.    [a] G(a)          // assumption
        3.    F(a)              // reit 2
        4. contradiction        // exists elim 1, 2-3
      '''
      result = verify._line 4, proof
      expect(result.verified).to.be.false

    it "spots mistaken use of exists elim where the new name is in the conclusion", ->
      proof = '''
        1. exists x F(x)    // premise
        2.    [a] F(a)          // assumption
        3.    F(a)          // reit 2
        4. F(a)             // exists elim 1, 2-3
      '''
      result = verify._line 4, proof
      expect(result.verified).to.be.false


  describe "proofs with the rules for not", ->
    it "verifies correct use of not elim", ->
      proof = '''
        1. not not A    // premise
        2. A            // not elim 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.true
    it "spots an incorrect use of not elim", ->
      proof = '''
        1. not not B    // premise
        2. A            // not elim 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.false
    it "verifies correct use of not intro", ->
      proof = '''
        1. |
        2. | | A              // assumption
        3. | |-------
        4. | | contradiction  // contradiction intro 1,2
        5. | not A            // not intro 2-4
      '''
      result = verify._line 5, proof
      expect(result.verified).to.be.true
    it "spots an correct use of not intro", ->
      proof = '''
           |
        1. | | A              // assumption
           | |-------
        2. | | B              // contradiction intro 1,2
        3. | not A            // not intro 1-2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.false

  describe "proofs with the rules for not", ->
    it "verifies correct use of contradiction elim", ->
      proof = '''
        1. contradiction    // premise
        2. A            // contradiction elim 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.true
    it "spots incorrect use of contradiction elim", ->
      proof = '''
        1. A          // premise
        2. A            // contradiction elim 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.false
    it "verifies correct use of contradiction intro", ->
      proof = '''
        1. A              // premise
        2. not A          // premise
        3. contradiction  // contradiction intro 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true
    it "verifies correct use of contradiction intro (not first)", ->
      proof = '''
        1. not A              // premise
        2. A          // premise
        3. contradiction  // contradiction intro 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true
    it "verifies correct use of contradiction intro (tricky case, not first)", ->
      # This test fails while `rule`'s methods for checking do not 
      # consider making matches for requirements in differnt orders.
      proof = '''
        1. not A              // premise
        2. not not A          // premise
        3. contradiction  // contradiction intro 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true
    it "spots mistake in use of contradiction intro (tricky case, not first)", ->
      # This test fails while `rule`'s methods for checking do not 
      # consider making matches for requirements in differnt orders.
      proof = '''
        1. not A              // premise
        2. not not B          // premise
        3. contradiction  // contradiction intro 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.false
    it "verifies correct use of contradiction intro (tricky case, not first)", ->
      # This test could fail if `rule`'s methods for checking did not 
      # consider making matches for requirements in differnt orders.
      proof = '''
        1. not not A              // premise
        2. not A          // premise
        3. contradiction  // contradiction intro 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true
    it "detects dodgy use of contradiction intro (tricky case)", ->
      proof = '''
        1. not not A          // premise
        2. contradiction      // contradiction intro 1,1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.false
      
      
  describe "proofs with the rules for arrow", ->
    it "verifies correct use of arrow elim", ->
      proof = '''
        1. A                // premise
        2. A arrow B        // premise
        3. B                // arrow elim 1,2
      '''
      result = verify._line 3, proof
      console.log result.message if not result.verified
      expect(result.verified).to.be.true
    it "detects mistaken use arrow elim (right to left)", ->
      proof = '''
        1. B                // premise
        2. A arrow B           // premise
        3. A                // arrow elim 1,2
      '''
      result = verify._line 3, proof
      console.log result.message if not result.verified
      expect(result.verified).to.be.false
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
      expect(result.verified).to.be.true
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
      expect(result.verified).to.be.false
    
    
  describe "proofs with the rules for double_arrow", ->
    it "verifies correct use double_arrow elim", ->
      proof = '''
        1. A                // premise
        2. A ↔ B           // premise
        3. B                // ↔ elim 1,2
      '''
      result = verify._line 3, proof
      console.log result.message if not result.verified
      expect(result.verified).to.be.true
    it "verifies correct use double_arrow elim (right to left)", ->
      proof = '''
        1. B                // premise
        2. A ↔ B           // premise
        3. A                // ↔ elim 1,2
      '''
      result = verify._line 3, proof
      console.log result.message if not result.verified
      expect(result.verified).to.be.true
    it "detects incorrect use double_arrow elim (wrong conclusion)", ->
      proof = '''
        1. B                // premise
        2. A ↔ B           // premise
        3. B                // ↔ elim 1,2
      '''
      result = verify._line 3, proof
      console.log "\t#{result.message}" if not result.verified
      expect(result.verified).to.be.false
    it "detects incorrect use double_arrow elim (wrong arrow) ", ->
      proof = '''
        1. B                // premise
        2. B ↔ B           // premise
        3. A                // ↔ elim 1,2
      '''
      result = verify._line 3, proof
      console.log "\t#{result.message}" if not result.verified
      expect(result.verified).to.be.false
    it "detects incorrect use double_arrow elim (wrong arrow) ", ->
      proof = '''
        1. B                // premise
        2. A ↔ B           // premise
        3. A                // ↔ elim 2,2
      '''
      result = verify._line 3, proof
      console.log "\t#{result.message}" if not result.verified
      expect(result.verified).to.be.false
      
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
      expect(result.verified).to.be.true
      
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
      expect(result.verified).to.be.false
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
      expect(result.verified).to.be.false
    
  describe "proofs with the rules for identity", ->
    it "confirms correct use of =intro", ->
      proof = '''
        1. b=b              // identity intro
      '''
      result = verify._line 1, proof
      expect(result.verified).to.be.true
    it "detects incorrect use of =intro", ->
      proof = '''
        1. b=c              // identity intro
      '''
      result = verify._line 1, proof
      expect(result.verified).to.be.false
    it "confirms correct use of =elim", ->
      proof = '''
        1. a=b              
        2. F(a)
        3. F(b)         // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true
    it "confirms correct use of =elim (right to left)", ->
      proof = '''
        1. a=b              
        2. F(b)
        3. F(a)         // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true
    it "detects incorrect use of =elim", ->
      proof = '''
        1. a=b              
        2. G(a)
        3. F(c)         // = elim 1,2
      '''
      result = verify._line 3, proof
      console.log(result.message)
      expect(result.verified).to.be.false
    it "confirms correct use of =elim (reverse lines)", ->
      proof = '''
        1. F(b)
        2. a=b              
        3. F(a)         // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true
    it "confirms correct use of =elim (complex example)", ->
      proof = '''
        1  all x (x=b arrow (F(x) and G(x)))
        2  A
        3  a=b              
        4  B
        5  all x (x=a arrow (F(x) and G(x)))         // = elim 1,3
      '''
      result = verify._line 5, proof
      expect(result.verified).to.be.true
    it "=elim allows not all substitutions to be made", ->
      # test id AF96B036-57DA-11E5-8511-720262EA09BE
      proof = '''
        1  F(a) and G(a)
        2  a=b              
        3  F(a) and G(b)         // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true
    it "=elim allows no substitutions to be made", ->
      proof = '''
        1  F(a) 
        2  a=b              
        3  F(a)          // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true
    it "=elim allows not all substitutions to be made proving a=b therefore b=a", ->
      # test id 69A3AAF2-57DF-11E5-A384-6BFFF2E18425
      proof = '''
        1  a=b
        2  a=a              // = elim              
        3  b=a              // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true
    it "=elim allows not all substitutions to be made proving a=b therefore b=a (variation)", ->
      proof = '''
        1  a=b
        2  b=b              // = elim              
        3  b=a              // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true
    it "=elim allows not all substitutions to be made (multiple clauses)", ->
      # test id 2D900196-57DF-11E5-9F54-6BFFF2E18425
      proof = '''
        1  F(a) and a=a and (G(a) and H(a))
        2  a=b              
        3  F(b) and a=b and (G(a) and H(b))         // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true
    it "=elim weird case (to check `rule` doesn't hang)", ->
      proof = '''
        1  F(a) and G(a)
        2  a=a              
        3  F(a) and G(a)         // = elim 1,2
      '''
      result = verify._line 3, proof
      expect(result.verified).to.be.true
    
    
  describe "proofs with the rules for universal", ->
    it "verifies universal elim", ->
      proof = '''
        1. all x F(x)     // premise
        2. F(a)           // universal elim 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.true
    it "spots a mistake with universal elim (predicate)", ->
      proof = '''
        1. all x F(x)     // premise
        2. G(a)           // universal elim 1
      '''
      result = verify._line 2, proof
      expect(result.verified).to.be.false
    it "verifies universal intro", ->
      proof = '''
        1. A
        2.    [a]            // assumption
        3.    F(a)          
        4. all x F(x)        // universal intro 2-3
      '''
      result = verify._line 4, proof
      expect(result.verified).to.be.true
    it "spots a mistake in universal intro", ->
      proof = '''
        1. A
        2.    [a]            // assumption
        3.    F(b)          
        4. all x F(x)        // universal intro 2-3
      '''
      result = verify._line 4, proof
      expect(result.verified).to.be.false
    it "does not let you use universal intro when the name you box is not new", ->
      # test id 454092AA-57A4-11E5-9C09-B0C78BD11E5D
      proof = '''
        1. F(a)
        2.    [a]            // assumption
        3.    F(a)          
        4. all x F(x)        // universal intro 2-3
      '''
      result = verify._line 4, proof
      expect(result.verified).to.be.false
    it "allows you use universal intro when you make only partial replacements", ->
      # test id A7774B7C-57DA-11E5-B920-720262EA09BE
      proof = '''
        1. 
        2.    [a]                   // assumption
        3.    F(a) and G(a)          
        4. all x (F(x) and G(a))    // universal intro 2-3
      '''
      result = verify._line 4, proof
      expect(result.verified).to.be.true

  describe "verifying premises and assumptions", ->
    # Here we just need to test that the rule is implemented;
    # to check that it works we have the tests for the `rule` module.
    it "verifies premises", ->
      proof = '''
        1. A              // assumption
      '''
      result = verify._line 1, proof
      expect(result.verified).to.be.true
      
