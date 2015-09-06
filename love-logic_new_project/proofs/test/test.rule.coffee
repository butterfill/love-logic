chai = require 'chai' 
expect = chai.expect
_ = require 'lodash'


util = require 'util'


verify = require '../verify'

rule = require '../rule'


describe "`rule`", ->
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
      line = proof.goto 2
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
      line = proof.goto 6
      test = rule.from('φ or ψ').and(rule.subproof('φ', 'χ')).and(rule.subproof('ψ', 'χ')).to('χ')
      result = test.check(line)
      # console.log util.inspect(line)
      console.log result.getMessage() if result isnt true
      expect(result).to.be.true

    it "provides a message when required citations to lines are missing", ->
      proof = '''
        1. A or B    // premise
        2.    A         // assumption
        3.    C         // 
        
        4.    B
        5.    C
        6. C          // or elim 1, 2-3
      '''
      proof = verify._parseProof proof
      line = proof.goto 6
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
      line = proof.goto 2
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
      line = proof.goto 2
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
      line = proof.goto 2
      result = rule.from('φ').to('φ').check(line)
      console.log result.getMessage() if result isnt true
      expect(result).to.be.true

    it "works when there is no from (as in = intro)", ->
      proof = '''
        1. a=a        // = intro
      '''
      proof = verify._parseProof proof
      line = proof.goto 1
      result = rule.from().to('α=α').check(line)
      expect(result).to.be.true

    it "detects errors in rules with no from (as in = intro)", ->
      proof = '''
        1. a=b        // = intro
      '''
      proof = verify._parseProof proof
      line = proof.goto 1
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
      
      result1 = reit.check(proof.goto(2))
      console.log result1.getMessage() if result1 isnt true
      expect(result1).to.be.true
      
      result2 = idIntro.check(proof.goto(3))
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
      result = arrowElim.check proof.goto(3)
      expect(result).not.to.be.true

    it "can verify correct use of arrow elim", ->
      proof = '''
        1. A arrow B
        2. A
        3. B            // arrow elim 1, 2
      ''' 
      proof = verify._parseProof proof
      arrowElim = rule.from('φ arrow ψ').and('φ').to('ψ')
      result = arrowElim.check proof.goto(3)
      expect(result).to.be.true

    it "can verify correct use of arrow elim regardless of the order in which the `.from` requirements occur in the proof", ->
      proof = '''
        1. A
        2. A  arrow B
        3. B            // arrow elim 1, 2
      ''' 
      proof = verify._parseProof proof
      arrowElim = rule.from('φ arrow ψ').and('φ').to('ψ')
      result = arrowElim.check proof.goto(3)
      expect(result).to.be.true

    it "can verify correct use of arrow elim regardless of the order in which the `.from` requirements are specified in defining the rule"
      # This test works fine.
      # The problem is just that the `rule.LineChecker` can't cope with this yet. (TODO)
      # , ->
      # proof = '''
      #   1. A
      #   2. A  arrow B
      #   3. B            // arrow elim 1, 2
      # '''
      # proof = verify._parseProof proof
      # arrowElim = rule.from('φ').and('φ arrow ψ').to('ψ')
      # result = arrowElim.check proof.goto(3)
      # expect(result).to.be.true
      # proof2 = '''
      #   1. A arrow B
      #   2. A
      #   3. B            // arrow elim 1, 2
      # '''
      # proof2 = verify._parseProof proof2
      # arrowElim = rule.from('φ').and('φ arrow ψ').to('ψ')
      # result = arrowElim.check proof2.goto(3)
      # console.log result.getMessage() if result isnt true
      # expect(result).to.be.true

        