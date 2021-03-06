chai = require 'chai' 
expect = chai.expect
assert = chai.assert
should = require('chai').should() 
_ = require 'lodash'

fol = require '../../fol'
bp = require '../block_parser'
ln = require '../add_line_numbers'
addJustification = require '../add_justification'
addSentences = require '../add_sentences'
addStatus = require '../add_status'
rule = require '../rule'

_parse = (proofText) ->
  block = bp.parse proofText
  ln.to block
  addJustification.to block
  addSentences.to block
  addStatus.to block
  return block

premiseRule = rule.from().to( rule.premise() )

describe "`rule`", ->
  
  describe ".from", ->
    it "allows chaining with to and check", ->
      result = rule.from('not not φ').to('φ')
      expect(typeof result.check).to.equal('function')

    it "allows adding requirements with .and", ->
      result = rule.from('φ or ψ').and(rule.subproof('φ', 'χ')).and(rule.subproof('ψ', 'χ')).to('χ')
      expect(typeof result.check).to.equal('function')

    it "returns something with .type 'rule'", ->
      result = rule.from('not not φ').to('φ')
      expect(result.type).to.equal 'rule'
      
    it "allows you to define multiple rules for later use", ->
      proof = '''
        1. not A
        2. not A            // reit 1
        3. a=a              // = intro
      ''' 
      proof = _parse proof
      idIntro = new rule.to('α=α')
      reit = (new rule.from('φ')).to('φ')
      line = proof.getLine(2)
      result1 = reit.check(line)
      console.log line.status.getMessage() if result1 isnt true
      expect(result1).to.be.true
      
      result2 = idIntro.check(proof.getLine(3))
      console.log result2.getMessage() if result2 isnt true
      expect(result2).to.be.true


  describe "premises and assumptions", ->
    it "`rule.from` allows creation of an empty rule", ->
      proof = '''
        1. A        // premise
      ''' 
      proof = _parse proof
      emptyRule = rule.from()
      result = emptyRule.check proof.getLine(1)
      expect(result).to.be.true
    it "the empty rule, `rule.from()`, checks that no lines are cited", ->
      proof = '''
        1. A
        2. A          // assumption 1
      ''' 
      proof = _parse proof
      emptyRule = rule.from()
      result = emptyRule.check proof.getLine(2)
      expect(result).not.to.be.true
    it "the empty rule, `rule.from()`, checks that no subpoofs are cited", ->
      proof = '''
        1. A
        2.    B
        3.    B
        4. A          // assumption 2-3
      ''' 
      proof = _parse proof
      emptyRule = rule.from()
      result = emptyRule.check proof.getLine(4)
      expect(result).not.to.be.true
      
      
    describe "`rule.premise()`", ->
      it "allows the first line to be a premise", ->
        proof = '''
          1. A        // premise
        ''' 
        proof = _parse proof
        result = premiseRule.check proof.getLine(1)
        expect(result).to.be.true
      it "allows the second line of the main proof to be a premise", ->
        proof = '''
          1. A        // premise
          2. B        // premise
        ''' 
        proof = _parse proof
        result = premiseRule.check proof.getLine(2)
        console.log line.status.getMessage() if result isnt true
        expect(result).to.be.true
      it "does not allow the second line of a subproof to be a premise", ->
        proof = '''
          1. A        // premise
          2.   A      // premise
          3.   B      // premise
        ''' 
        proof = _parse proof
        result = premiseRule.check proof.getLine(3)
        expect(result).not.to.be.true
      it "does not allow a premise to occur after a subproof", ->
        proof = '''
          1. A and B        // premise
          2.    B              // premise
          3.    C              
          4. C           // premise
        ''' 
        proof = _parse proof
        result = premiseRule.check proof.getLine(4)
        expect(result).not.to.be.true
      it "adds a message to the `line.status` object when a line is not verified", ->
        proof = '''
          1. A        // premise
          2.   A      // premise
          3.   B      // premise
        ''' 
        proof = _parse proof
        line =  proof.getLine(3)
        result = premiseRule.check line
        expect(result).not.to.be.true
        expect( line.status.getMessage().length > 0 ).to.be.true
  
  
      

  describe "checking rules",->
    it "allows checking cited things are correct when one line is required", ->
      proof = '''
        1. not not A
        2. A            // not elim 1
      ''' 
      proof = _parse proof
      line = proof.getLine 2
      result = rule.from('not not φ').to('φ').check(line)
      console.log "getMessage() = #{line.status.getMessage()}" if result isnt true
      expect(result).to.be.true

    it "allows checking cited things are correct when one line and two subproofs are required", ->
      proof = '''
        1. A or B    // premise
        2.    A         // assumption
        3.    C         // 
        4.
        5.    B
        6.    C
        7. C          // or elim 1, 2-3, 5-6
      '''
      proof = _parse proof
      line = proof.getLine 7
      test = rule.from('φ or ψ').and(rule.subproof('φ', 'χ')).and(rule.subproof('ψ', 'χ')).to('χ')
      result = test.check(line)
      console.log line.status.getMessage() if result isnt true
      expect(result).to.be.true

    it "provides a message when required citations to subproofs are missing", ->
      proof = '''
        1. A or B    // premise
        2.    A         // assumption
        3.    C         // 
        4.  
        5.    B
        6.    C
        7. C          // or elim 1, 2-3
      '''
      proof = _parse proof
      line = proof.getLine 7
      test = rule.from('φ or ψ').and(rule.subproof('φ', 'χ')).and(rule.subproof('ψ', 'χ')).to('χ')
      result = test.check(line)
      expect(result).not.to.be.true
      expect(line.status.getMessage().length > 0).to.be.true

    it "provides a message when required citations to lines are missing", ->
      proof = '''
        1. not not A
        2. A            // not elim
      ''' 
      proof = _parse proof
      line = proof.getLine 2
      result = rule.from('not not φ').to('φ').check(line)
      expect(result).not.to.be.true
      expect(line.status.getMessage().length > 0).to.be.true

    it "provides a message when superfluous citations are added", ->
      proof = '''
        1. not not A
        2. A            // not elim 1, 1
      ''' 
      proof = _parse proof
      line = proof.getLine 2
      result = rule.from('not not φ').to('φ').check(line)
      expect(result).not.to.be.true
      expect(line.status.getMessage().length > 0).to.be.true

  describe "LineChecker, RequirementChecker and Pathfinder", ->
    it "allows you to confirm correct use of reit", ->
      proof = '''
        1. not A
        2. not A            // reit 1
      ''' 
      proof = _parse proof
      line = proof.getLine 2
      result = rule.from('φ').to('φ').check(line)
      console.log line.status.getMessage() if result isnt true
      expect(result).to.be.true

    it "works when there is no from (as in = intro)", ->
      proof = '''
        1. a=a        // = intro
      '''
      proof = _parse proof
      line = proof.getLine 1
      result = rule.from().to('α=α').check(line)
      expect(result).to.be.true

    it "detects errors in rules with no from (as in = intro)", ->
      proof = '''
        1. a=b        // = intro
      '''
      proof = _parse proof
      line = proof.getLine 1
      result = rule.to('α=α').check(line)
      expect(result).not.to.be.true
    it "generates an error message when mistakes are made with rules with no from (as in = intro)", ->
      proof = '''
        1. a=b        // = intro
      '''
      proof = _parse proof
      line = proof.getLine 1
      result = rule.to('α=α').check(line)
      expect(line.status.getMessage().length > 0).to.be.true

    it "allows correct use of and intro for A and A citing the same line twice", ->
      proof = '''
        1. A           // premise
        2. B
        3. A and A     // and intro 1,1
      '''
      proof = _parse proof
      andIntro = rule.from('ψ').and('φ').to('φ and ψ')
      result = andIntro.check(proof.getLine(3))
      expect(result).to.be.true
      
    it "does not allow citing irrelevant lines in a tricky case with and-intro", ->
      proof = '''
        1. A           // premise
        2. B
        3. A and A     // and intro 1,2
      '''
      proof = _parse proof
      andIntro = rule.from('ψ').and('φ').to('φ and ψ')
      result = andIntro.check(proof.getLine(3))
      expect(result).not.to.be.true
      
      
  describe "In cases where the order in which matches are made matters", ->
    it "can detect incorrect use of arrow elim", ->
      proof = '''
        1. A arrow B
        2. A
        3. A            // arrow elim 1, 2
      ''' 
      proof = _parse proof
      arrowElim = rule.from('φ arrow ψ').and('φ').to('ψ')
      result = arrowElim.check proof.getLine(3)
      expect(result).not.to.be.true
      expect(result).not.to.be.undefined

    it "can verify correct use of arrow elim", ->
      proof = '''
        1. A arrow B
        2. A
        3. B            // arrow elim 1, 2
      ''' 
      proof = _parse proof
      arrowElim = rule.from('φ arrow ψ').and('φ').to('ψ')
      result = arrowElim.check proof.getLine(3)
      expect(result).to.be.true

    it "can verify correct use of arrow elim regardless of the order in which the `.from` requirements occur in the proof", ->
      proof = '''
        1. A
        2. A  arrow B
        3. B            // arrow elim 1, 2
      ''' 
      proof = _parse proof
      arrowElim = rule.from('φ arrow ψ').and('φ').to('ψ')
      result = arrowElim.check proof.getLine(3)
      expect(result).to.be.true

    it "can verify correct use of arrow elim regardless of the order in which the `.from` requirements are specified in defining the rule", ->
      proof = '''
        1. A
        2. A  arrow B
        3. B            // arrow elim 1, 2
      '''
      proof = _parse proof
      arrowElim = rule.from('φ').and('φ arrow ψ').to('ψ')
      result = arrowElim.check proof.getLine(3)
      expect(result).to.be.true
      proof2 = '''
        1. A arrow B
        2. A
        3. B            // arrow elim 1, 2
      '''
      proof2 = _parse proof2
      line = proof2.getLine(3)
      result = arrowElim.check line
      console.log line.status.getMessage() if result isnt true
      expect(result).to.be.true
      
      
    it "can verify correct use of arrow elim where every sentence is an arrow", ->
      proof = '''
        1. (A arrow B) arrow (C arrow D)
        2. A arrow B
        3. C arrow D            // arrow elim 1, 2
      '''
      proof = _parse proof
      arrowElim = rule.from('φ').and('φ arrow ψ').to('ψ')
      result = arrowElim.check proof.getLine(3)
      expect(result).to.be.true
      proof2 = '''
        1. A arrow B
        2. A
        3. B            // arrow elim 1, 2
      '''
      proof2 = _parse proof2
      line = proof2.getLine(3)
      result = arrowElim.check line
      console.log line.status.getMessage() if result isnt true
      expect(result).to.be.true
    
    it "can verify correct use of arrow elim where every sentence is an arrow (reverse order)", ->
      proof = '''
        1. A arrow B
        2. (A arrow B) arrow (C arrow D)
        3. C arrow D            // arrow elim 1, 2
      '''
      proof = _parse proof
      arrowElim = rule.from('φ').and('φ arrow ψ').to('ψ')
      result = arrowElim.check proof.getLine(3)
      expect(result).to.be.true
      proof2 = '''
        1. A arrow B
        2. A
        3. B            // arrow elim 1, 2
      '''
      proof2 = _parse proof2
      line = proof2.getLine(3)
      result = arrowElim.check line
      console.log line.status.getMessage() if result isnt true
      expect(result).to.be.true
    
    
    it "can do =elim where all the statements involve identity (a=c version)", ->
      proof = '''
        1. a=c
        2. b=c
        3. a=b	// = elim 1,2
      '''
      proof = _parse proof
      eqElimLeft = rule.from('α=β').and('φ').to('φ[α-->β]')
      eqElimRight = rule.from('α=β').and('φ').to('φ[β-->α]')
      # eqElimLeft = rule.from('φ').and('α=β').to('φ[α-->β]')
      # eqElimRight = rule.from('φ').and('α=β').to('φ[β-->α]')
      line = proof.getLine(3)
      result1 = eqElimLeft.check line
      result2 = eqElimRight.check line
      result = result1 is true or result2 is true
      console.log line.status.getMessage() if result isnt true
      expect(result).to.be.true
      
    it "can do =elim where all the statements involve identity (a=c, reversed premise order version)", ->
      proof = '''
        1. b=c
        2. a=c
        3. a=b	// = elim 1,2
      '''
      proof = _parse proof
      eqElimLeft = rule.from('α=β').and('φ').to('φ[α-->β]')
      eqElimRight = rule.from('α=β').and('φ').to('φ[β-->α]')
      line = proof.getLine(3)
      result1 = eqElimLeft.check line
      result2 = eqElimRight.check line
      result = result1 is true or result2 is true
      console.log line.status.getMessage() if result isnt true
      expect(result).to.be.true
      
    it "can detect incorrect use of =elim ", ->
      # This proof is incorrect:
      proof = '''
        1. c=a
        2. b=c
        3. a=b	// = elim 1,2
      '''
      proof = _parse proof
      eqElimLeft = rule.from('α=β').and('φ').to('φ[α-->β]')
      eqElimRight = rule.from('α=β').and('φ').to('φ[β-->α]')
      line = proof.getLine(3)
      result1 = eqElimLeft.check line
      result2 = eqElimRight.check line
      result = result1 is true or result2 is true
      expect(result).to.be.false
      
    it "can detect incorrect use of =elim (reversed premise order version)", ->
      # This proof is incorrect:
      proof = '''
        1. b=c
        2. c=a
        3. a=b	// = elim 1,2
      '''
      proof = _parse proof
      eqElimLeft = rule.from('α=β').and('φ').to('φ[α-->β]')
      eqElimRight = rule.from('α=β').and('φ').to('φ[β-->α]')
      line = proof.getLine(3)
      result1 = eqElimLeft.check line
      result2 = eqElimRight.check line
      result = result1 is true or result2 is true
      expect(result).to.be.false
      
    it "can do =elim where all the statements involve identity (c=a, c=b version)", ->
      proof = '''
        1. c=a
        2. c=b
        3. a=b	// = elim 1,2
      '''
      proof = _parse proof
      eqElimLeft = rule.from('α=β').and('φ').to('φ[α-->β]')
      eqElimRight = rule.from('α=β').and('φ').to('φ[β-->α]')
      line = proof.getLine(3)
      result1 = eqElimLeft.check line
      result2 = eqElimRight.check line
      result = result1 is true or result2 is true
      console.log line.status.getMessage() if result isnt true
      expect(result).to.be.true
      
    it "can do =elim where all the statements involve identity (c=a, c=b, reversed premise order version)", ->
      proofTxt = '''
        1. c=b
        2. c=a
        3. a=b	// = elim 1,2
      '''
      proof = _parse proofTxt
      eqElimLeft = rule.from('α=β').and('φ').to('φ[α-->β]')
      eqElimRight = rule.from('α=β').and('φ').to('φ[β-->α]')
      line = proof.getLine(3)
      result1 = eqElimLeft.check line
      result2 = eqElimRight.check line
      result = result1 is true or result2 is true
      if result isnt true
        console.log proofTxt
        console.log line.status.getMessage() 
      expect(result).to.be.true
      
      
  describe "`_permutations`", ->
    it "can permute a single element list", ->
      result = rule._permutations [1]
      expect(result).to.deep.equal([[1]])
    it "can permute a two element list (fragile: depends on list order)", ->
      result = rule._permutations [1,2]
      expect(result).to.deep.equal([[1,2],[2,1]])
    it "can permute a three element list (fragile: depends on list order)", ->
      result = rule._permutations [1,2,3]
      expect(result).to.deep.equal([[1,2,3],[1,3,2],[2,1,3],[2,3,1],[3,1,2],[3,2,1]])
  
  describe ".linesContainPatterns", ->
    it "can find a pattern", ->
      txt = '''
      A
      not A
      '''
      proof = _parse txt
      lines = proof.content
      phi = fol.parse('φ')
      notPhi = fol.parse('not φ')
      test = rule.linesContainPatterns(lines, [phi, notPhi], {})
      expect(test).not.to.be.false
    it "can find a pattern (reverse order)", ->
      txt = '''
      not A
      A
      '''
      proof = _parse txt
      lines = proof.content
      phi = fol.parse('φ')
      notPhi = fol.parse('not φ')
      test = rule.linesContainPatterns(lines, [phi, notPhi], {})
      expect(test).not.to.be.false
    it "can correctly fail to find a pattern", ->
      txt = '''
      A
      not B
      '''
      proof = _parse txt
      lines = proof.content
      phi = fol.parse('φ')
      notPhi = fol.parse('not φ')
      test = rule.linesContainPatterns(lines, [phi, notPhi], {})
      expect(test).to.be.false
    it "can find a pattern despite distractors", ->
      txt = '''
      not B
      not A
      A
      not B
      '''
      proof = _parse txt
      lines = proof.content
      phi = fol.parse('φ')
      notPhi = fol.parse('not φ')
      test = rule.linesContainPatterns(lines, [phi, notPhi], {})
      expect(test).not.to.be.false
    it "can find a pattern despite distractors (reverse order of patterns)", ->
      txt = '''
      not B
      not A
      A
      not B
      '''
      proof = _parse txt
      lines = proof.content
      phi = fol.parse('φ')
      notPhi = fol.parse('not φ')
      test = rule.linesContainPatterns(lines, [notPhi, phi], {})
      expect(test).not.to.be.false
  
  describe "features for tree proofs", ->
    it "rules record which rule and what matches on the lines checked", ->
      proof = _parse '''
        1. A           // premise
        2. B
        3. A and B     // and intro 1,2
      '''
      andIntro = rule.from('φ').and('ψ').to('φ and ψ')
      line = proof.getLine(3)
      result = andIntro.check(line)
      expect(result).to.be.true
      ruleAndMatch = line.rulesChecked[0]
      expect(ruleAndMatch.rule).to.equal(andIntro)
      a = [ruleAndMatch.matches.φ.letter, ruleAndMatch.matches.ψ.letter]
      assert('A' in a)
      assert('B' in a)
      expect(a.length).to.equal(2)
    it "rules record which rule and what matches on the lines checked (term metavariable matches)", ->
      proof = _parse '''
        1. a=a        // = intro
      '''
      line = proof.getLine(1)
      result = rule.from().to('α=α').check(line)
      expect(result).to.be.true
      matches = line.rulesChecked[0].matches
      expect(matches.α.name).to.equal('a')
      
  describe ".where clauses", ->
    it "can cause a rule check to fail", ->
      proof = _parse '''
        1. a=a        // = intro
      '''
      line = proof.getLine(1)
      idIntro = rule.from().to('α=α')
      idIntro.check(line).should.not.be.false
      idIntroWhere = idIntro.where({check:->false})
      idIntroWhere.check(line).should.be.false
    it "does not necessarily cause a rule check to fail", ->
      proof = _parse '''
        1. a=a        // = intro
      '''
      line = proof.getLine(1)
      idIntroWhere = rule.from().to('α=α').where({check:->true})
      idIntroWhere.check(line).should.not.be.false
      
      

      
      

