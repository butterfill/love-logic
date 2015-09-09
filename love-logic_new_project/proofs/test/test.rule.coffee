chai = require 'chai' 
expect = chai.expect
_ = require 'lodash'


util = require 'util'

fol = require '../../fol'

# TODO: remove this dependence (verify depends on rule!)
verify = require '../add_verification'

rule = require '../rule'


describe "`rule`", ->
  
  describe "`RequirementChecker`", ->
    it "collects the metavariables from subproofs", ->
      req = rule.subproof('[α]φ[τ->α]', 'ψ')
      line = { sentence : fol.parse 'not not A' }
      rc = new rule.RequirementChecker(req, [line])
      expect(rc.metaVariableNames.inSub.left.length).to.equal(1)
      expect(rc.metaVariableNames.inSub.left[0]).to.equal('τ')
      expect(rc.canCheckAlready()).to.be.false
    
    it "has a `canCheckAlready` method", ->
      req = fol.parse 'not not φ'
      line = { sentence : fol.parse 'not not A' }
      rc = new rule.RequirementChecker(req, [line])
      expect(rc.canCheckAlready()).to.be.true
      
    it "says no to `canCheckAlready` when necessary", ->
      req = fol.parse 'ψ[α->null]' 
      line = { sentence : fol.parse 'not not A' }
      rc = new rule.RequirementChecker(req, [line])
      console.log rc.metaVariableNames.inSub.left
      expect(rc.canCheckAlready()).to.be.false
      
    it "says yes to `canCheckAlready` when possible", ->
      req = fol.parse 'φ[α->a]'
      line = { sentence : fol.parse 'not not A' }
      matches = 
        α : (fol.parse 'F(b)').termlist[0]
      rc = new rule.RequirementChecker(req, [line], matches)
      expect(rc.canCheckAlready()).to.be.true
    
    it "says yes to `canCheckAlready` when possible for a subproof", ->
      req = rule.subproof('[α]φ[τ->α]', 'ψ')
      line = { sentence : fol.parse 'not not A' }
      matches = 
        τ : (fol.parse 'F(x)').termlist[0]
      rc = new rule.RequirementChecker(req, [line])
      rc.setMatches(matches)
      expect(rc.canCheckAlready()).to.be.true
    
    it "can save and restore matches", ->
      req = fol.parse 'not not φ'
      line = { sentence : fol.parse 'not not A' }
      matches = 
        α : (fol.parse 'F(b)').termlist[0]
      rc = new rule.RequirementChecker(req, [line], matches)
      expect(rc.matches.α.name).to.equal('b')
      rc.saveMatches()
      rc.matches.α = (fol.parse 'F(c)').termlist[0]
      expect(rc.matches.α.name).to.equal('c')
      rc.restoreMatches()
      expect(rc.matches.α.name).to.equal('b')
    
    it "can check whether a requirement is met", ->
      req = fol.parse 'not not φ'
      proof = '''
        1. not not A
      ''' 
      proof = verify._parseProof proof
      line = proof.getLine 1
      rc = new rule.RequirementChecker(req, [line])
      result = rc.check()
      expect(result).not.to.be.false

    it "returns matches when a requirement is met", ->
      req = fol.parse 'not not φ'
      proof = '''
        1. not not A
      ''' 
      proof = verify._parseProof proof
      line = proof.getLine 1
      rc = new rule.RequirementChecker(req, [line])
      result = rc.check()
      matches = result['1']
      expect(matches.φ.letter).to.equal('A')

    it "knows when a requirement is not met", ->
      req = fol.parse 'not not φ'
      proof = '''
        1. A
      ''' 
      proof = verify._parseProof proof
      line = proof.getLine 1
      rc = new rule.RequirementChecker(req, [line])
      result = rc.check()
      expect(result).to.be.false
    
    it "deals with a tricky case involving matches and substitutions (`[α]φ[τ->α]`)", ->
      req = fol.parse '[α]φ[τ->α]'
      proof = '''
        1. [a]F(a)
      ''' 
      proof = verify._parseProof proof
      line = proof.getLine 1
      matches = 
        φ : fol.parse "F(x)"
        τ : (fol.parse 'F(x)').termlist[0]
      rc = new rule.RequirementChecker(req, [line])
      rc.setMatches(matches)
      result = rc.check()
      expect(result).not.to.be.false
      matches = result['1']
      expect(matches.α.name).to.equal('a')
      
      
      
  
  describe ".from", ->
    it "allows chaining with to and check", ->
      result = rule.from('not not φ').to('φ')
      expect(typeof result.check).to.equal('function')

    it "allows adding requirements with .and", ->
      result = rule.from('φ or ψ').and(rule.subproof('φ', 'χ')).and(rule.subproof('ψ', 'χ')).to('χ')
      expect(typeof result.check).to.equal('function')

    it "keeps track of requirements (including those added with .to and .and)", ->
      result = rule.from('φ or ψ').and(rule.subproof('φ', 'χ')).and(rule.subproof('ψ', 'χ')).to('χ')
      # This is a fragile test that depends on inner workings.
      expect result._requirements?
        .to.be.true
      expect result._requirements.from.length
        .to.equal 3
      expect result._requirements.from[0].type
        .to.equal 'or'

    it "returns something with .type 'rule'", ->
      result = rule.from('not not φ').to('φ')
      expect(result.type).to.equal 'rule'

    it "allows checking cited things are correct when one line is required", ->
      proof = '''
        1. not not A
        2. A            // not elim 1
      ''' 
      proof = verify._parseProof proof
      line = proof.getLine 2
      # console.log util.inspect(line)
      result = rule.from('not not φ').to('φ').check(line)
      console.log "result.getMessage() = #{result.getMessage()}" if result isnt true
      expect(result).to.be.true

    it "allows checking cited things are correct when one line and two subproofs are required", ->
      proof = '''
        1. A or B    // premise
        2.    A         // assumption
        3.    C         // 
        
        4.    B
        5.    C
        6. C          // or elim 1, 2-3, 4-5
      '''
      proof = verify._parseProof proof
      line = proof.getLine 6
      test = rule.from('φ or ψ').and(rule.subproof('φ', 'χ')).and(rule.subproof('ψ', 'χ')).to('χ')
      result = test.check(line)
      # console.log util.inspect(line)
      console.log result.getMessage() if result isnt true
      expect(result).to.be.true

    it "provides a message when required citations to subproofs are missing", ->
      proof = '''
        1. A or B    // premise
        2.    A         // assumption
        3.    C         // 
        
        4.    B
        5.    C
        6. C          // or elim 1, 2-3
      '''
      proof = verify._parseProof proof
      line = proof.getLine 6
      test = rule.from('φ or ψ').and(rule.subproof('φ', 'χ')).and(rule.subproof('ψ', 'χ')).to('χ')
      result = test.check(line)
      expect(result).not.to.be.true
      expect(_.isString(result.getMessage())).to.be.true
      expect(result.getMessage().length > 0).to.be.true

    it "provides a message when required citations to lines are missing", ->
      proof = '''
        1. not not A
        2. A            // not elim
      ''' 
      proof = verify._parseProof proof
      line = proof.getLine 2
      # console.log util.inspect(line)
      result = rule.from('not not φ').to('φ').check(line)
      expect(result).not.to.be.true
      expect(_.isString(result.getMessage())).to.be.true
      expect(result.getMessage().length > 0).to.be.true

    it "provides a message when superfluous citations are added", ->
      proof = '''
        1. not not A
        2. A            // not elim 1, 1
      ''' 
      proof = verify._parseProof proof
      line = proof.getLine 2
      # console.log util.inspect(line)
      result = rule.from('not not φ').to('φ').check(line)
      expect(result).not.to.be.true
      expect(result.getMessage().length > 0).to.be.true

    it "allows you to confirm correct use of reit", ->
      proof = '''
        1. not A
        2. not A            // reit 1
      ''' 
      proof = verify._parseProof proof
      line = proof.getLine 2
      result = rule.from('φ').to('φ').check(line)
      console.log result.getMessage() if result isnt true
      expect(result).to.be.true

    it "works when there is no from (as in = intro)", ->
      proof = '''
        1. a=a        // = intro
      '''
      proof = verify._parseProof proof
      line = proof.getLine 1
      result = rule.from().to('α=α').check(line)
      expect(result).to.be.true

    it "detects errors in rules with no from (as in = intro)", ->
      proof = '''
        1. a=b        // = intro
      '''
      proof = verify._parseProof proof
      line = proof.getLine 1
      result = rule.to('α=α').check(line)
      expect(result).not.to.be.true
      expect(_.isString(result.getMessage())).to.be.true
      expect(result.getMessage().length > 0).to.be.true
      
    it "allows you to define multiple rules for later use", ->
      proof = '''
        1. not A
        2. not A            // reit 1
        3. a=a              // = intro
      ''' 
      proof = verify._parseProof proof
      idIntro = new rule.to('α=α')
      reit = (new rule.from('φ')).to('φ')
      
      result1 = reit.check(proof.getLine(2))
      console.log result1.getMessage() if result1 isnt true
      expect(result1).to.be.true
      
      result2 = idIntro.check(proof.getLine(3))
      console.log result2.getMessage() if result2 isnt true
      expect(result2).to.be.true
      
  describe "In cases where the order in which matches are made matters", ->
    it "can detect incorrect use of arrow elim", ->
      proof = '''
        1. A arrow B
        2. A
        3. A            // arrow elim 1, 2
      ''' 
      proof = verify._parseProof proof
      arrowElim = rule.from('φ arrow ψ').and('φ').to('ψ')
      result = arrowElim.check proof.getLine(3)
      expect(result).not.to.be.true

    it "can verify correct use of arrow elim", ->
      proof = '''
        1. A arrow B
        2. A
        3. B            // arrow elim 1, 2
      ''' 
      proof = verify._parseProof proof
      arrowElim = rule.from('φ arrow ψ').and('φ').to('ψ')
      result = arrowElim.check proof.getLine(3)
      expect(result).to.be.true

    it "can verify correct use of arrow elim regardless of the order in which the `.from` requirements occur in the proof", ->
      proof = '''
        1. A
        2. A  arrow B
        3. B            // arrow elim 1, 2
      ''' 
      proof = verify._parseProof proof
      arrowElim = rule.from('φ arrow ψ').and('φ').to('ψ')
      result = arrowElim.check proof.getLine(3)
      expect(result).to.be.true

    it "can verify correct use of arrow elim regardless of the order in which the `.from` requirements are specified in defining the rule", ->
      proof = '''
        1. A
        2. A  arrow B
        3. B            // arrow elim 1, 2
      '''
      proof = verify._parseProof proof
      arrowElim = rule.from('φ').and('φ arrow ψ').to('ψ')
      result = arrowElim.check proof.getLine(3)
      expect(result).to.be.true
      proof2 = '''
        1. A arrow B
        2. A
        3. B            // arrow elim 1, 2
      '''
      proof2 = verify._parseProof proof2
      result = arrowElim.check proof2.getLine(3)
      console.log result.getMessage() if result isnt true
      expect(result).to.be.true


  describe "premises and assumptions", ->
    it "`rule.from` allows creation of an empty rule", ->
      proof = '''
        1. A        // premise
      ''' 
      proof = verify._parseProof proof
      emptyRule = rule.from()
      result = emptyRule.check proof.getLine(1)
      expect(result).to.be.true
    it "the empty rule, `rule.from()`, checks that no lines are cited", ->
      proof = '''
        1. A
        2. A          // assumption 1
      ''' 
      proof = verify._parseProof proof
      emptyRule = rule.from()
      result = emptyRule.check proof.getLine(2)
      # if result isnt true
      #   console.log result.getMessage()
      expect(result).not.to.be.true
    it "the empty rule, `rule.from()`, checks that no subpoofs are cited", ->
      proof = '''
        1. A
        2.    B
        3.    B
        4. A          // assumption 2-3
      ''' 
      proof = verify._parseProof proof
      emptyRule = rule.from()
      result = emptyRule.check proof.getLine(4)
      # if result isnt true
      #   console.log result.getMessage()
      expect(result).not.to.be.true
      
    describe "`rule.premise()`", ->
      it "allows the first line to be a premise", ->
        proof = '''
          1. A        // premise
        ''' 
        proof = verify._parseProof proof
        premiseRule = rule.premise()
        result = premiseRule.check proof.getLine(1)
        expect(result).to.be.true
      it "allows the second line of the main proof to be a premise", ->
        proof = '''
          1. A        // premise
          2. B        // premise
        ''' 
        proof = verify._parseProof proof
        premiseRule = rule.premise()
        result = premiseRule.check proof.getLine(2)
        console.log result.getMessage() if result isnt true
        expect(result).to.be.true
      it "does not allow the second line of a subproof to be a premise", ->
        proof = '''
          1. A        // premise
          2.   A      // premise
          3.   B      // premise
        ''' 
        proof = verify._parseProof proof
        premiseRule = rule.premise()
        result = premiseRule.check proof.getLine(3)
        expect(result).not.to.be.true
      it "does not allow a premise to occur after a non-premise", ->
        proof = '''
          1. A and B        // premise
          2. B              // and elim 1
          3. C              // premise
        ''' 
        proof = verify._parseProof proof
        premiseRule = rule.premise()
        result = premiseRule.check proof.getLine(3)
        expect(result).not.to.be.true
      it "does not allow a premise to occur after a subproof", ->
        proof = '''
          1. A and B        // premise
          2.    B              // premise
          3.    C              
          4. C           // premise
        ''' 
        proof = verify._parseProof proof
        premiseRule = rule.premise()
        result = premiseRule.check proof.getLine(4)
        expect(result).not.to.be.true
      it "returns a results object with `.getMessage` method when a line is not verified", ->
        proof = '''
          1. A        // premise
          2.   A      // premise
          3.   B      // premise
        ''' 
        proof = verify._parseProof proof
        premiseRule = rule.premise()
        result = premiseRule.check proof.getLine(3)
        expect(result).not.to.be.true
        expect( _.isString(result.getMessage?()) ).to.be.true
