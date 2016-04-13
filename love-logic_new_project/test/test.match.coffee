_ = require 'lodash'

chai = require('chai')
assert = chai.assert
expect = chai.expect
match = require '../match'
fol = require '../parser/awFOL'
tellerFOL = require '../parser/tellerFOL'
util = require '../util'
dialectManager = require '../dialect_manager/dialectManager'

# some handy FOL objects (defining these presupposes that some of the tests below work ...)
PROP_A = fol.parse "A"
PROP_B = fol.parse "B"
PROP_C = fol.parse "C"
NAME_A = fol.parse("F(a)").termlist[0]   #i.e. {type='name', name='a', ...}
NAME_B = fol.parse("F(b)").termlist[0]
NAME_C = fol.parse("F(c)").termlist[0]
VARIABLE_X = fol.parse("F(x)").termlist[0]
TERM_METAVARIABLE_T = fol.parse("F(τ)").termlist[0]
(util.delExtraneousProperties(x) for x in [PROP_A, PROP_B, PROP_C, NAME_A, NAME_B, NAME_C, VARIABLE_X,TERM_METAVARIABLE_T])


describe "match (module)", ->
  
  describe "`._addSubToEveryTerm`", ->
    it "adds a (term-)substitution to every term", ->
      e = fol.parse "a=x and F(α)"
      theSub = 
        type : 'substitution'
        from : (fol.parse "F(z)").termlist[0]
        to : (fol.parse "F(c)").termlist[0]
      result = match._addSubToEveryTerm e, theSub
      for term in result.left.termlist.concat(result.right.termlist)
        expect(term.substitutions[0].from.name).to.equal('z')
        expect(term.substitutions[0].to.name).to.equal('c')
        expect(term.substitutions.length).to.equal(1)
    it "adds a substitution to bound variables", ->
      e = fol.parse "all x F(x)"
      theSub = 
        type : 'substitution'
        from : (fol.parse "F(x)").termlist[0]
        to : (fol.parse "F(y)").termlist[0]
      result = match._addSubToEveryTerm e, theSub
      # console.log "#{util.expressionToString result}"
      expect(result.boundVariable.substitutions[0].from.name).to.equal('x')
      expect(result.boundVariable.substitutions[0].to.name).to.equal('y')
      
  describe "`._moveAllSubsInwards`", ->
    it "moves term subs (like [a-->b]) inwards", ->
      e = fol.parse '(c=d)[a-->b]'
      e = util.delExtraneousProperties e
      result = match._moveAllSubsInwards(e)
      console.log "\te : #{util.expressionToString(e)}"
      console.log "\tresult : #{util.expressionToString(result)}"
      expect(result.substitutions?).to.be.false
      expect(result.termlist[0].substitutions.length).to.equal(1)
      expect(result.termlist[1].substitutions.length).to.equal(1)
    it "moves sentence subs (like [A-->B]) inwards", ->
      e = fol.parse '(B and F(x))[A-->D]'
      e = util.delExtraneousProperties e
      result = match._moveAllSubsInwards(e)
      console.log "\te : #{util.expressionToString(e)}"
      console.log "\tresult : #{util.expressionToString(result)}"
      expect(result.substitutions?).to.be.false
      expect(result.left.substitutions.length).to.equal(1)
      expect(result.right.substitutions?).to.be.false
    it "moves multiple, mixed subs (like [A-->B][x-->y]) inwards", ->
      e = fol.parse '(a=b and C)[A-->B][x-->y]'
      e = util.delExtraneousProperties e
      result = match._moveAllSubsInwards(e)
      console.log "\te : #{util.expressionToString(e)}"
      console.log "\tresult : #{util.expressionToString(result)}"
      expect(result.substitutions?).to.be.false
      expect(result.left.substitutions?).to.be.false
      expect(result.left.termlist[0].substitutions.length).to.equal(1)
      expect(result.left.termlist[1].substitutions.length).to.equal(1)
      expect(result.right.substitutions.length).to.equal(1)
    it "doesn't mind being used repeatedly", ->
      e = fol.parse '(a=a)[a-->b]'
      e = util.delExtraneousProperties e
      result1 = match._moveAllSubsInwards(e)
      result2 = match._moveAllSubsInwards(result1)
      console.log util.expressionToString(result2)
      expect(result2).to.deep.equal(result1)
    it "does nothing if there are no subs", ->
      e = fol.parse '(a=a)'
      e = util.delExtraneousProperties e
      result = match._moveAllSubsInwards(e)
      console.log util.expressionToString(result)
      expect(e).to.deep.equal(result)
    it "preserves the order in which subs were written", ->
      results = []
      e = fol.parse '(F(a) and G(a))[a-->b][b-->c][c-->d][d-->e]'
      eFirst = e.substitutions[0].from.name
      eLast = e.substitutions[3].from.name
      result = match._moveAllSubsInwards(e)
      rFirstLeft = result.left.termlist[0].substitutions[0].from.name
      rLastLeft = result.left.termlist[0].substitutions[3].from.name
      rFirstRight = result.right.termlist[0].substitutions[0].from.name
      rLastRight = result.right.termlist[0].substitutions[3].from.name
      console.log "from: #{util.expressionToString e} to: #{util.expressionToString result}"
      expect(eFirst).to.equal(rFirstLeft)
      expect(eLast).to.equal(rLastLeft)
      expect(eFirst).to.equal(rFirstRight)
      expect(eLast).to.equal(rLastRight)
      
  
  describe "`.doAfterApplyingSubstitutions", ->
    it "lists possible substitutions for one substitution", ->
      results = []
      e = fol.parse '(a=a)[a-->b]'
      process = (e) ->
        results.push(e)
        return undefined
      _ignore = match.doAfterApplyingSubstitutions e, process
      results = _.uniq((util.expressionToString(x).replace(/\s/g,'') for x in results)).sort()
      expect(results).to.deep.equal(["a=a","a=b","b=a","b=b"])
    it "lists possible substitutions for one substitution (variant with predicates)", ->
      results = []
      e = fol.parse '(F(a) and G(a))[a-->b]'
      process = (e) ->
        results.push(e)
        return undefined
      _ignore = match.doAfterApplyingSubstitutions e, process
      console.log "\tresults.length = #{results.length}"
      results = _.uniq((util.expressionToString(x) for x in results)).sort()
      console.log "\t\t\tunique results.length = #{results.length}"
      expect(results).to.deep.equal(["F(a) ∧ G(a)","F(a) ∧ G(b)","F(b) ∧ G(a)","F(b) ∧ G(b)"])
    it "lists possible substitutions for two substitutions", ->
      results = []
      e = fol.parse '(F(a) and G(b))[a-->b][b-->c]'
      process = (e) ->
        results.push(e)
        # console.log "found #{util.expressionToString e}"
        return undefined
      _ignore = match.doAfterApplyingSubstitutions e, process
      expectedResults = ["F(a) and G(b)","F(a) and G(c)","F(b) and G(b)","F(b) and G(c)","F(c) and G(b)","F(c) and G(c)"]
      expectedResults = (util.delExtraneousProperties(fol.parse(x)) for x in expectedResults)
      console.log "\tresults.length = #{results.length}"
      results = _.uniq((util.expressionToString(x) for x in results)).sort()
      console.log "\t\t\tunique results.length = #{results.length}"
      expectedResults = _.uniq((util.expressionToString(x) for x in expectedResults)).sort()
      expect(results).to.deep.equal(expectedResults)
    it "lists possible substitutions for four substitutions", ->
      results = []
      e = fol.parse 'F(a)[a-->b][b-->c][c-->d][d-->e]'
      process = (e) ->
        results.push(e)
        return undefined
      _ignore = match.doAfterApplyingSubstitutions e, process
      expectedResults = ["F(a)","F(b)","F(c)","F(d)","F(e)"]
      expectedResults = (util.delExtraneousProperties(fol.parse(x)) for x in expectedResults)
      results = _.uniq((util.expressionToString(x) for x in results)).sort()
      expectedResults = _.uniq((util.expressionToString(x) for x in expectedResults)).sort()
      expect(results).to.deep.equal(expectedResults)
    it "lists possible substitutions for four substitutions (different order)", ->
      results = []
      e = fol.parse 'F(a)[a-->b][b-->c][d-->e][c-->d]'
      process = (e) ->
        results.push(e)
        return undefined
      _ignore = match.doAfterApplyingSubstitutions e, process
      expectedResults = ["F(a)","F(b)","F(c)","F(d)"]
      expectedResults = (util.delExtraneousProperties(fol.parse(x)) for x in expectedResults)
      results = _.uniq((util.expressionToString(x) for x in results)).sort()
      expectedResults = _.uniq((util.expressionToString(x) for x in expectedResults)).sort()
      expect(results).to.deep.equal(expectedResults)
    it "lists possible substitutions for mixed (term and sentence) substitutions", ->
      results = []
      e = fol.parse '(F(a) and A)[a-->b][A-->B]'
      process = (e) ->
        results.push(e)
        return undefined
      _ignore = match.doAfterApplyingSubstitutions e, process
      expectedResults = ["F(a) and A","F(a) and B","F(b) and A","F(b) and B"]
      expectedResults = (util.delExtraneousProperties(fol.parse(x)) for x in expectedResults)
      results = _.uniq((util.expressionToString(x) for x in results)).sort()
      expectedResults = _.uniq((util.expressionToString(x) for x in expectedResults)).sort()
      expect(results).to.deep.equal(expectedResults)
    it "stops when `process` returns a result", ->
      results = []
      e = fol.parse '(a=a)[a-->b]'
      process = (e) ->
        results.push(e)
        return 'hello' if e.termlist[0].name is 'a'
        return undefined
      result = match.doAfterApplyingSubstitutions e, process
      expect(result).to.equal('hello')
      results = _.uniq((util.expressionToString(x).replace(/\s/g,'') for x in results)).sort()
      expect(results).to.deep.equal(["a=b","b=a","b=b"])
    it "lists what I expect for two substitutions in a tricky case", ->
      results = []
      e = fol.parse '(A and A and A)[A-->φ][φ-->ψ][ψ-->χ]'
      util.delExtraneousProperties e
      anExpectedResult = fol.parse "ψ and φ and χ"
      util.delExtraneousProperties anExpectedResult
      process = (e) ->
        return true if util.areIdenticalExpressions(e, anExpectedResult)
        return undefined
      result = match.doAfterApplyingSubstitutions e, process
      expect(result).to.be.true
    it "cares about the order in which substitutions are written", ->
      results = []
      # This is like the previous test but with subs in the opposite order.
      e = fol.parse '(F(a) and G(b))[b-->c][a-->b]'
      process = (e) ->
        console.log "found #{util.expressionToString e}"
        results.push(e)
        return undefined
      _ignore = match.doAfterApplyingSubstitutions e, process
      expectedResults = ["F(a) and G(b)","F(a) and G(c)","F(b) and G(b)","F(b) and G(c)"]
      expectedResults = (util.delExtraneousProperties(fol.parse(x)) for x in expectedResults)
      results = _.uniq((util.expressionToString(x) for x in results)).sort()
      expectedResults = _.uniq((util.expressionToString(x) for x in expectedResults)).sort()
      expect(results).to.deep.equal(expectedResults)
      

  
  
  describe '.find', ->
    it "should find match 'not not φ' with φ='A' in 'not not A'", ->
      pattern = fol.parse 'not not φ'
      expression = fol.parse 'not not A'
      matches = match.find expression, pattern
      expectedMatch = PROP_A
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatch)).to.be.true

    it "should find match 'not not φ' with φ='A' in 'not not A' when dialect is teller", ->
      dialectManager.set('teller')
      pattern = fol.parse 'not not φ'
      expression = fol.parse 'not not A'
      matches = match.find expression, pattern
      expectedMatch = PROP_A
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatch)).to.be.true
      dialectManager.set('default')

    it "should find match 'not not φ' with φ='A and B' in 'not not (A and B)'", ->
      pattern = fol.parse 'not not φ'
      expression = fol.parse 'not not (A and B)'
      matches = match.find expression, pattern
      expectedMatch = fol.parse("A and B")
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatch)).to.be.true

    it "should fail to find match 'not not φ' in 'not (not A and B)'", ->
      pattern = fol.parse 'not not φ'
      expression = fol.parse 'not (not A and B)'
      matches = match.find expression, pattern
      expect(matches).to.be.false
 
    it "should find match 'not (φ or ψ)' with φ='A' in 'not (A or (B arrow C))'", ->
      pattern = fol.parse 'not (φ or ψ)'
      expression = fol.parse 'not (A or (B arrow C))'
      matches = match.find expression, pattern
      expectedMatches =
        φ : PROP_A
        ψ : fol.parse("B arrow C")
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
      expect(util.areIdenticalExpressions(matches.ψ, expectedMatches.ψ)).to.be.true

    it "does not match 'φ or φ' in 'A or B'", ->
      pattern = fol.parse 'φ or φ'
      expression = fol.parse 'A or B'
      matches = match.find expression, pattern
      expect(matches).to.be.false

    it "does not match 'φ or φ' in 'A or not A'", ->
      pattern = fol.parse 'φ or φ'
      expression = fol.parse 'A or not A'
      matches = match.find expression, pattern
      expect(matches).to.be.false

    it "does not match 'φ or φ' in 'A or A'", ->
      pattern = fol.parse 'φ or φ'
      expression = fol.parse 'A or A'
      matches = match.find expression, pattern
      expectedMatches =
        φ : fol.parse("A")
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
    
    it "matches a sentence with the same (no expression variables)", ->
      pattern = fol.parse 'A or A'
      expression = fol.parse 'A or A'
      matches = match.find expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      
    it "does not match different sentences (no expression variables)", ->
      pattern = fol.parse 'A or A'
      expression = fol.parse 'B or B'
      matches = match.find expression, pattern
      expect(matches).to.be.false

    it "should return an object (the matches) in which the values do not have extraneous properties", ->
      pattern = fol.parse 'F(α)'
      expression = fol.parse 'F(a)'
      matches = match.find expression, pattern
      theMatch = matches.α
      theMatchClone = util.cloneExpression theMatch
      util.delExtraneousProperties theMatchClone 
      expect(theMatch).to.deep.equal(theMatchClone)
    it "should return an object (the matches) in which the values do not have extraneous properties (with variables)", ->
      pattern = fol.parse 'F(α)'
      expression = fol.parse 'F(x)'
      matches = match.find expression, pattern
      theMatch = matches.α
      theMatchClone = util.cloneExpression theMatch
      util.delExtraneousProperties theMatchClone 
      expect(theMatch).to.deep.equal(theMatchClone)
    it "should return an object (the matches) in which the values do not have extraneous properties (with propositional expressions)", ->
      pattern = fol.parse 'φ1 or φ1'
      expression = fol.parse 'A or A'
      matches = match.find expression, pattern
      theMatch = matches.φ1
      theMatchClone = util.cloneExpression theMatch
      util.delExtraneousProperties theMatchClone 
      expect(theMatch).to.deep.equal(theMatchClone)
    it "returns new matches plus matches passed in to it, including any unused matches", ->
      pattern = fol.parse 'φ1 or φ2'
      expression = fol.parse 'A or B'
      oldMatches = 
        φ1 : fol.parse 'A'
        φ3 : fol.parse 'C'
      newMatches = match.find expression, pattern, oldMatches
      expect(newMatches.φ1.letter).to.equal('A')
      expect(newMatches.φ2.letter).to.equal('B')
      expect(newMatches.φ3.letter).to.equal('C')
    
    it "does not mutate the `pattern` parameter", ->
      pattern = fol.parse 'φ1 or φ2'
      expression = fol.parse 'A or B'
      patternClone = _.cloneDeep pattern  # Note that we can't use util.cloneExpression here.
      match.find expression, pattern
      expect(pattern).to.deep.equal(patternClone)
    
    it "does not mutate the `expression` parameter", ->
      pattern = fol.parse 'φ1 or φ2'
      expression = fol.parse 'A or B'
      expressionClone = _.cloneDeep expression
      match.find expression, pattern
      expect(expression).to.deep.equal(expressionClone)

    it "should find match(∀τ(φ → ψ))[α-->τ] against ∀x(F(x) → G(x))", ->
      pattern = fol.parse '(∀τ(φ → ψ))[α-->τ]'
      expression = fol.parse '∀x(F(x) → G(x))'
      oldMatches = 
        φ : fol.parse 'F(a)'
        α : NAME_A
      newPattern = match.apply(pattern, oldMatches)
      matches = match.find expression, newPattern, oldMatches
      expect(matches).not.to.be.false
    it "should find match ∀τ φ[α-->τ] against ∀x F(x)", ->
      pattern = fol.parse '∀τ φ[α-->τ]'
      expression = fol.parse '∀x F(x)'
      oldMatches = 
        φ : fol.parse 'F(a)'
        α : NAME_A
        # τ : VARIABLE_X
      newPattern = match.apply(pattern, oldMatches)
      matches = match.find expression, newPattern, oldMatches
      expect(matches).not.to.be.false

    it "should find match [α]φ against [a]F(a)", ->
      pattern = fol.parse '[α]φ'
      expression = fol.parse '[a]F(a)'
      matches = match.find expression, pattern
      # console.log matches
      # The worry is that φ will be [a]F(a) not F(s)
      expect(matches.φ.box?).to.be.false

    it "should match α=α against a^=a^", ->
      pattern = tellerFOL.parse 'α=α'
      expression = tellerFOL.parse 'a^=a^'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
      assert.equal matches.α.name, 'a^'
      
    it "should match (all τ) φ against (∀x)Fx, and then φ[τ-->α^] and against Fa^", ->
      pattern1 = tellerFOL.parse '(all τ) φ'
      expression1 = tellerFOL.parse '(∀x)Fx'
      matches1 = match.find expression1, pattern1
      assert.equal matches1.φ.name, 'F'
      assert.equal matches1.τ.name, 'x'
      pattern2pre = tellerFOL.parse 'φ[τ-->α^]'
      pattern2 = match.apply pattern2pre, matches1
      expression2 = tellerFOL.parse 'Fa^'
      matches2 = match.find expression2, pattern2
      expect(matches2).not.to.be.false
    
    it "should NOT match (all τ) φ against (∀x)Fx, and then φ[τ-->α^] and against Fa (note the missing hat)", ->
      pattern1 = tellerFOL.parse '(all τ) φ'
      expression1 = tellerFOL.parse '(∀x)Fx'
      matches1 = match.find expression1, pattern1
      pattern2pre = tellerFOL.parse 'φ[τ-->α^]'
      pattern2 = match.apply pattern2pre, matches1
      expression2 = tellerFOL.parse 'Fa'
      matches2 = match.find expression2, pattern2
      expect(matches2).to.be.false
    
  describe '`.find` with boxes', ->
    it "matches a pattern to [a] (empty expression)", ->
      pattern = fol.parse '[α]'
      expression = fol.parse '[a]'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
    it "matches pattern '[α] A' to '[a]A'", ->
      pattern = fol.parse '[α] A'
      expression = fol.parse '[a] A'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
    it "doesn't match pattern '[α] A' to 'A'", ->
      pattern = fol.parse '[α] A'
      expression = fol.parse 'A'
      matches = match.find expression, pattern
      expect(matches).to.be.false
    it "doesn't match `[α]φ` to `F(a)` ", ->
      pattern = fol.parse '[α]φ'
      expression = fol.parse 'F(a)'
      matches = match.find expression, pattern
      # Test the test:
      pattern2 = fol.parse 'φ'
      expect( util.areIdenticalExpressions(pattern, pattern2) ).to.be.false
      # The test:
      expect(matches).to.be.false
    it "doesn't match `[α]φ and α=b` to `[b]F(a) and a=b` ", ->
      pattern = fol.parse '[α]φ and α=b'
      expression = fol.parse '[b]F(a) and a=b'
      matches = match.find expression, pattern
      expect(matches).to.be.false
      
    it "matches `[α]φ` to `[b]F(x)`", ->
      pattern = fol.parse '[α]φ'
      expression = fol.parse '[b]F(x)'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
    it "doesn't match `[α]φ` to `[b]F(x)` given `matches` ", ->
      pattern = fol.parse '[α]φ'
      expression = fol.parse '[b]F(x)'
      theMatches = 
        α : (fol.parse 'F(a)').termlist[0]
      matches = match.find expression, pattern, theMatches
      expect(matches).to.be.false
    
    it "matches `all τ φ` to `∀y Loves(b,y)`", ->
      pattern = fol.parse 'all τ φ'
      expression = fol.parse '∀y Loves(b,y)'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
    it "does not match `all τ φ` to ` exists y Loves(b,y)`", ->
      pattern = fol.parse 'all τ φ'
      expression = fol.parse 'exists y Loves(b,y)'
      matches = match.find expression, pattern
      expect(matches).to.be.false
    # I don’t think this is the right behaviour: boxes have to be taken 
    # care of by the rules of proof and proof checker.
    # it "matches `all τ φ` to `[b] ∀y Loves(b,y)`", ->
    #   pattern = fol.parse 'all τ φ'
    #   expression = fol.parse '[b] ∀y Loves(b,y)'
    #   matches = match.find expression, pattern
    #   expect(matches).not.to.be.false

    it "matches `[α]F(α)` to `[a] F(a)`", ->
      pattern = fol.parse '[α]F(α)'
      expression = fol.parse '[a] F(a)'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
      
    # # TODO: this fails; I think it’s fine because the proofs work, and I’ve
    # # just forgotton how `find.match` works with substitutions.
    # it "matches `[α]φ[τ-->α]` to `[a] F(a)`", ->
    #   pattern1 = fol.parse 'exists τ φ'
    #   expression1 = fol.parse 'exists x F(x)'
    #   priorMatches = match.find expression1, pattern1
    #   console.log(JSON.stringify(priorMatches,null,4))
    #   pattern = fol.parse '[α]φ[τ-->α]'
    #   console.log(pattern.toString())
    #   expression = fol.parse '[a] F(a)'
    #   matches = match.find expression, pattern, priorMatches
    #   expect(matches).not.to.be.false
    
      

  describe '`.find` with expressions that are not closed wffs', ->
    it "matches 'all x not φ' in 'all x (not (F(x) and G(x)))", ->
      pattern = fol.parse 'all x not φ'
      expression = fol.parse 'all x (not (F(x) and G(x)))'
      matches = match.find expression, pattern
      expectedMatches =
        φ : fol.parse("F(x) and G(x)")
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
      

  describe '`.find` with `term_metavariable`s', ->
    it "should find match 'α=α' with α='a' in 'a=a'", ->
      pattern = fol.parse 'α=α'
      expression = fol.parse 'a=a'
      matches = match.find expression, pattern
      expectedMatch = expression.termlist[0]
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.α, expectedMatch)).to.be.true

    it "should find match 'Loves(α,b) and φ'", ->
      pattern = fol.parse 'Loves(α,b) and φ'
      expression = fol.parse 'Loves(a,b) and Loves(b,a)'
      matches = match.find expression, pattern
      expectedMatches =
        φ : fol.parse("Loves(b,a)")
        α : fol.parse("F(a)").termlist[0] #i.e. {type='name', name='a', ...}
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
      expect(util.areIdenticalExpressions(matches.α, expectedMatches.α)).to.be.true
      
    it "matches for pattern α=β", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      matches = match.find expression1, pattern
      expectedMatches =
        "α" : NAME_A
        "β" : NAME_B
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.α, expectedMatches.α)).to.be.true
      expect(util.areIdenticalExpressions(matches.β, expectedMatches.β)).to.be.true

    it "matches for pattern 'all τ φ", ->
      pattern = fol.parse 'all τ φ'
      expression = fol.parse '(all x) (F(x) and G(x))'
      matches = match.find expression, pattern
      expectedMatches =
        "τ" : VARIABLE_X
        "φ" : expression.left
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.τ, expectedMatches.τ)).to.be.true
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
    
    it "matches 'exists τ1 exists τ2 (F(τ1) and G(τ2))'", ->
      expression = fol.parse 'exists x exists y (F(x) and G(y))'
      pattern = fol.parse 'exists τ1 exists τ2 (F(τ1) and G(τ2))'
      result = match.find expression, pattern
      expect(result).not.to.be.false


  describe 'findMatches where identity can be treated as symmetric', ->
    it "does not find match 'α1=α2 and α1=α2'", ->
      pattern = fol.parse 'α1=α2 and α1=α2'
      expression = fol.parse 'a=b and b=a'
      matches = match.find expression, pattern
      expect(matches).to.be.false
      

  describe 'using `.find` where what the expression variables must match is stipulated', ->
    it "matches for pattern α=β with specified matches (expect success)", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      stipulatedMatches = {"α":NAME_A, "β":NAME_B}
      matches = match.find expression1, pattern, stipulatedMatches
      expect(matches).not.to.be.false
      
    it "matches for pattern α=β with specified matches (expect failure)", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      stipulatedMatches =
        "α" : NAME_B
        "β" : NAME_A
      matches = match.find expression1, pattern, stipulatedMatches
      expect(matches).to.be.false


  describe 'using `.find` with substitutions', ->
    it "returns {} when expressions match and there are no metavariables", ->
      pattern = fol.parse 'F(a)'
      expression = fol.parse 'F(a)'
      matches = match.find expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "returns false when expressions do not match and there are no metavariables", ->
      pattern = fol.parse 'F(a)'
      expression = fol.parse 'F(b)'
      matches = match.find expression, pattern
      expect(matches).to.be.false
    it "finds matches where applying a substitution would produce a match", ->
      pattern = fol.parse 'F(a)[a-->b]'
      expression = fol.parse 'F(b)'
      matches = match.find expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where applying a substitution would break the match", ->
      pattern = fol.parse 'F(a)[a-->b]'
      expression = fol.parse 'F(a)'
      matches = match.find expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where partially applying a substitution would produce a match", ->
      pattern = fol.parse '(a=a)[a-->b]'
      expression = fol.parse 'a=b'
      matches = match.find expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where partially applying a substitution with a meta variable matches", ->
      pattern = fol.parse '(a=a)[a-->α]'
      expression = fol.parse 'a=b'
      matches = match.find expression, pattern
      expectedMatches = 
        α : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't match where partially applying a substitution with a meta variable would be wrong", ->
      pattern = fol.parse '((a=a) and (a=a))[a-->α]'
      expression = fol.parse 'a=b1 and a=b2'
      matches = match.find expression, pattern
      expect(matches).to.be.false
    it "finds matches where partially applying a substitution would produce a match (example with predicates)", ->
      pattern = fol.parse '(F(a) and F(a))[a-->b]'
      expression = fol.parse 'F(a) and F(b)'
      matches = match.find expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "[test for the next test]", ->
      pattern = fol.parse '(F(a) and F(β))'
      expression = fol.parse 'F(a) and F(b)'
      matches = match.find expression, pattern
      expectedMatches =
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where partially applying a substitution involving a term_metavariable would produce a match (example with predicates)", ->
      pattern = fol.parse '(F(a) and F(a))[a-->β]'
      expression = fol.parse 'F(a) and F(b)'
      matches = match.find expression, pattern
      expectedMatches =
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't match where applying a substitution involving a term_metavariable would require to to have two values", ->
      pattern = fol.parse '(F(a) and F(a))[a-->β]'
      expression = fol.parse 'F(c) and F(b)'
      matches = match.find expression, pattern
      expect(matches).to.be.false
    it "finds matches where partially applying a substitution involving a term_metavariable ... other way around", ->
      # It's important to test two ways around to avoid accidental success 
      # contingent based on the route an expression tree walker takes
      pattern = fol.parse '(F(a) and F(a))[a-->β]'
      expression = fol.parse 'F(b) and F(a)'
      matches = match.find expression, pattern
      expectedMatches =
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where partially applying a substitution involving a term_metavariable ... middle", ->
      # As above, it's important to test different ways around to avoid accidental success 
      # contingent based on the route an expression tree walker takes
      pattern = fol.parse '(F(a) and (F(a) and F(a)))[a-->β]'
      expression = fol.parse '(F(a) and (F(b) and F(a)))'
      matches = match.find expression, pattern
      expectedMatches =
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where partially applying a substitution involving a term_metavariable ... two of four, different branches", ->
      # As above, it's important to test different ways around to avoid accidental success 
      # contingent based on the route an expression tree walker takes
      pattern = fol.parse '((F(a) or F(a)) and (F(a) and F(a)))[a-->β]'
      expression = fol.parse '((F(a) or F(b)) and (F(b) and F(a)))'
      matches = match.find expression, pattern
      expectedMatches =
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't finds matches where partially applying a substitution involving a term_metavariable would require it having multiple values", ->
      # The concern here is that `β` could be matched with `d` in one
      # branch and with `c` in the other branch.  But this would be incorrect:
      # `expression` is not a substitution instance of `pattern`.
      pattern = fol.parse '((F(a) or F(a)) and (F(a) and F(a)))[a-->β]'
      expression = fol.parse '((F(a) or F(d)) and (F(c) and F(a)))'
      matches = match.find expression, pattern
      expect(matches).to.be.false
    it "does finds matches from `F(a)[a-->β] and F(a)[a-->β]` to `F(a) and F(c)`", ->
      pattern = fol.parse 'F(a)[a-->β] and F(a)[a-->β]'
      expression = fol.parse 'F(a) and F(c)'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
    it "doesn't finds matches from `F(a)[a-->β] and F(a)[a-->β]` to `F(b) and F(c)`", ->
      # The concern here is that `β` could be matched with `d` in one
      # branch and with `c` in the other branch.  But this would be incorrect:
      # `expression` is not a substitution instance of `pattern`.
      pattern = fol.parse 'F(a)[a-->β] and F(a)[a-->β]'
      expression = fol.parse 'F(b) and F(c)'
      matches = match.find expression, pattern
      expect(matches).to.be.false
    it "finds matches requiring partially applying a substitution involving a sentence variable", ->
      pattern = fol.parse '(A and B)[B-->φ]'
      expression = fol.parse 'A and A'
      matches = match.find expression, pattern
      expectedMatches =
        φ : PROP_A
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't choke with identical substitutions (like `[φ-->φ]`)", ->
      pattern = fol.parse '(φ and A)[φ-->φ]'
      expression = fol.parse 'A and A'
      matches = match.find expression, pattern
      expectedMatches =
        φ : PROP_A
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't allow identical substitutions (like `[φ-->φ]`) to change things", ->
      pattern = fol.parse '(φ and φ and A)[φ-->φ]'
      expression = fol.parse 'B and C and A'
      matches = match.find expression, pattern
      expect(matches).to.be.false
    it "matches with substitutions between metavariables (like `[φ-->ψ]`)", ->
      pattern = fol.parse '(φ and φ and A)[φ-->ψ]'
      expression = fol.parse 'B and C and A'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
      # There are multiple correct matches that could be made here.
    it "matches with substitutions between metavariables (like `[φ-->ψ]`), more complex case", ->
      pattern = fol.parse '(φ and φ and φ and φ and A)[φ-->ψ]'
      expression = fol.parse 'B and C and C and B and A'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
      # There are multiple correct matches that could be made here.
    it "test simplify (no metavariables)", ->
      # This fails if you allow substitutions to replace within substitutions.
      # It fails because [A-->B] becomes [A-->C] before it can be applied.
      pattern = fol.parse '(A and B)[A-->B][B-->C]'
      expression = fol.parse 'B and C'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
    it "matches with multiple substitutions between metavariables: [φ-->ψ][ψ-->χ] $outerfirst", ->
      # Test id 0A5EAB88-588D-11E5-B11A-FEB2F2E18425 $outerfirst
      pattern = fol.parse '(φ and φ and φ)[φ-->ψ][ψ-->χ]'
      expression = fol.parse 'B and C and A' 
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
      # There are multiple correct matches that could be made here.
    it "matches with multiple substitutions between metavariables: [φ-->ψ][ψ-->χ] (additional rhs conjunction) $outerfirst", ->
      # $outerfirst
      pattern = fol.parse '(φ and φ and φ and D)[φ-->ψ][ψ-->χ]'
      expression = fol.parse 'B and C and A and D'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
      # There are multiple correct matches that could be made here.
      
    it "matches with multiple substitutions, without metavariables", ->
      pattern = fol.parse '(A and A and A)[A-->B][B-->C]'
      expression = fol.parse 'B and C and A'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
      
    it "matches with multiple substitutions between metavariables: variation with nesting", ->
      pattern = fol.parse '((φ and φ)[φ-->ψ] and φ)[φ-->χ]'
      expression = fol.parse 'B and C and A'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
      # There are multiple correct matches that could be made here.
    it "matches with multiple substitutions; variation; without metavariables", ->
      pattern = fol.parse '((A and A)[A-->B] and A)[B-->C]'
      expression = fol.parse 'B and C and A'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
      
    it "matches with multiple substitutions between metavariables: [φ-->ψ][φ-->χ]", ->
      pattern = fol.parse '(φ and φ and φ)[φ-->ψ][φ-->χ]'
      expression = fol.parse 'B and C and A'
      matches = match.find expression, pattern
      expect(matches).not.to.be.false
      # There are multiple correct matches that could be made here.
    it "does not mutate its parameter `_matches` (even when there are multiple substitutions)", ->
      pattern = fol.parse '(F(a,b) and B)[B-->φ][a-->α][b-->β]'
      expression = fol.parse 'F(c,d) and A'
      _matches =
        φ : PROP_A
      _matchesPre = _.cloneDeep _matches
      result = match.find expression, pattern, _matches
      expect(result).not.to.be.false  # Test the test.
      expect(_matchesPre).to.deep.equal(_matches)
    it "does not mutate its parameter `_matches` (even when there are multiple and no match can be made)", ->
      pattern = fol.parse '(F(a,b) and F(a,b) and B)[B-->φ][a-->α][b-->β]'
      expression = fol.parse 'F(c,d) and F(a1,a2) and A'
      _matches =
        φ : PROP_A
      _matchesPre = _.cloneDeep _matches
      result = match.find expression, pattern, _matches
      expect(result).to.be.false  # Test the test.
      expect(_matchesPre).to.deep.equal(_matches)
      

  describe 'using `.find` with nested substitutions', ->
    it "finds matches where nested substitutions are required", ->
      pattern = fol.parse '(F(c)[c-->α] and F(d))[d-->β]'
      expression = fol.parse 'F(a) and F(b)'
      matches = match.find expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where nested, partial substitutions are required", ->
      pattern = fol.parse '((F(c) and F(d) and F(c))[c-->α] and F(d))[d-->β]'
      expression = fol.parse '(F(c) and F(d) and F(a) and F(b))'
      matches = match.find expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where nested, partial substitutions are required (variant1)", ->
      pattern = fol.parse '((F(c) and F(d) and F(c))[c-->α] and F(d))[d-->β]'
      expression = fol.parse '((F(a) and F(d) and F(c)) and F(b))'
      matches = match.find expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where nested, partial substitutions are required (variant2)", ->
      pattern = fol.parse '((F(c) and F(d) and F(c))[c-->α] and F(d))[d-->β]'
      expression = fol.parse '(F(c) and F(b) and F(a) and F(d))'
      matches = match.find expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where nested, partial substitutions are required (variant2b)", ->
      pattern = fol.parse '((F(c) and F(d) and F(c) and F(d))[c-->α] and A)[d-->β]'
      expression = fol.parse '((F(c) and F(b) and F(a) and F(d)) and A)'
      matches = match.find expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)

  describe 'using `.find` with *multiple* substitutions', ->
    it "finds matches where multiple substitutions are required", ->
      pattern = fol.parse '(F(c) and F(d))[c-->α,d-->β]'
      expression = fol.parse 'F(a) and F(b)'
      matches = match.find expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where multiple, partial substitutions are required", ->
      pattern = fol.parse '(F(c) and F(d) and F(c) and F(d))[c-->α,d-->β]'
      expression = fol.parse '(F(c) and F(d) and F(a) and F(b))'
      matches = match.find expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't find matches with multiple, partial substitutions where one metavariable would have to have different values in subexpressions", ->
      pattern = fol.parse '(F(c) and F(d) and F(c) and F(d))[c-->α,d-->β]'
      expression = fol.parse '(F(b) and F(d) and F(a) and F(b))'
      matches = match.find expression, pattern
      expect(matches).to.be.false
    it "finds matches where multiple, partial substitutions are required (variant1)", ->
      pattern = fol.parse '(F(c) and F(d) and F(c) and F(d))[c-->α,d-->β]'
      expression = fol.parse '(F(a) and F(d) and F(c) and F(b))'
      matches = match.find expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't find matches with multiple, partial substitutions where one metavariable would have to have different values in subexpressions (variant1)", ->
      pattern = fol.parse '(F(c) and F(d) and F(c) and F(d))[c-->α,d-->β]'
      expression = fol.parse '(F(a) and F(a) and F(c) and F(b))'
      matches = match.find expression, pattern
      expect(matches).to.be.false
    it "finds matches where multiple, partial substitutions are required (variant2)", ->
      pattern = fol.parse '(F(c) and F(d) and F(c) and F(d))[c-->α,d-->β]'
      expression = fol.parse '(F(c) and F(b) and F(a) and F(d))'
      matches = match.find expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't find matches with multiple, partial substitutions where one metavariable would have to have different values in subexpressions (variant2)", ->
      pattern = fol.parse '(F(c) and F(d) and F(c) and F(d))[c-->α,d-->β]'
      expression = fol.parse '(F(c) and F(b) and F(a) and F(a))'
      matches = match.find expression, pattern
      expect(matches).to.be.false
  
  describe "`.find`, a tricky case involving two or more substitutions", ->
    it "test B[B-->φ]", ->
      pattern = fol.parse '(F(a) and F(a) and B)[B-->φ]'
      expression = fol.parse 'F(a) and F(a) and A'
      result = match.find expression, pattern
      expect(result).not.to.be.false  
    it "copes with a sequence of two substitutions, one partial [B-->φ][a-->α]", ->
      # Test id 82EE71B0-588C-11E5-9F92-48DB8BD11E5D 
      # This is an unexpected failure to do with the order of substitutions.
      pattern = fol.parse '((F(a) and F(a)) and B)[B-->φ][a-->α]'
      expression = fol.parse '(F(c) and F(a)) and A'
      result = match.find expression, pattern
      expect(result).not.to.be.false  
    it "copes with a sequence of two substitutions, one partial [B-->φ][a-->α] (different order)", ->
      # Apparently difficulties with test 82EE71B0-588C-11E5-9F92-48DB8BD11E5D 
      # are specific to what happens with `term_metavariables`.
      pattern = fol.parse '((B and F(a)) and F(a))[B-->φ][a-->α]'
      expression = fol.parse '((A and F(a)) and F(c))'
      result = match.find expression, pattern
      expect(result).not.to.be.false  
    it "copes with a sequence of two partial substitutions [B-->φ][a-->α]", ->
      # Comparing this test with 82EE71B0-588C-11E5-9F92-48DB8BD11E5D ,
      # you can see that the problem is to do with getting all the way to
      # the end of a sentence.
      pattern = fol.parse '((F(a) and F(a)) and B and C)[B-->φ][a-->α]'
      expression = fol.parse '(F(c) and F(a)) and A and C'
      result = match.find expression, pattern
      expect(result).not.to.be.false  
    it "copes with a sequence of three partial substitutions [B-->φ][a-->α][b-->β]", ->
      pattern = fol.parse '(F(a,b) and F(a,b) and B)[B-->φ][a-->α][b-->β]'
      expression = fol.parse 'F(c,d) and F(a,b) and A'
      result = match.find expression, pattern
      expect(result).not.to.be.false  
    it "copes with a sequence of three partial substitutions [B-->φ][a-->α][b-->β] (different expression structure)", ->
      pattern = fol.parse '(F(a,b) and (F(a,b) and B))[B-->φ][a-->α][b-->β]'
      expression = fol.parse 'F(c,d) and (F(a,b) and A)'
      result = match.find expression, pattern
      expect(result).not.to.be.false  
    it "copes with a sequence of three partial substitutions [B-->φ][a-->α][b-->β] (variant2)", ->
      pattern = fol.parse '(F(a,b) and F(a,b) and B and A)[B-->φ][a-->α][b-->β]'
      expression = fol.parse 'F(c,d) and F(a,b) and A and A'
      result = match.find expression, pattern
      expect(result).not.to.be.false  
      
      
  describe 'using `.find` with *sequential* substitutions', ->
    it "finds matches where two sequential substitutions are required", ->
      pattern = fol.parse '(F(c) and F(b))[c-->x,x-->a]'
      expression = fol.parse 'F(a) and F(b)'
      matches = match.find expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where four sequential substitutions are required", ->
      # NB: these are out of order, so the correctness of this test might be
      # questioned.  (See comment to test F72C790A-5887-11E5-8641-BAD061EA09BE .)
      pattern = fol.parse '(F(c) and F(b))[c-->x,x-->y,y-->z,z-->a]'
      expression = fol.parse 'F(a) and F(b)'
      matches = match.find expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where sequential substitutions are required depending on the order in which substitutions are written (other way around)", ->
      # Test id F72C790A-5887-11E5-8641-BAD061EA09BE
      pattern = fol.parse '((F(c) and F(b))[c-->x])[x-->a]'
      expression = fol.parse 'F(a) and F(b)'
      matches = match.find expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "does not find matches where sequential substitutions are required irrespective of the order in which substitutions are written", ->
      # This fails to match because the `[x-->a]` substitution (which is innermost) is 
      # applied (or not) first, and only then is the outer substitution (`[c-->x]`) considered.
      pattern = fol.parse '((F(c) and F(b))[x-->a])[c-->x]'
      expression = fol.parse 'F(a) and F(b)'
      matches = match.find expression, pattern
      expectedMatches = {}
      expect(matches).to.be.false


  describe '`.apply`', ->
    it "correctly applies a simple match to a pattern", ->
      pattern = fol.parse 'not not φ'
      matches = 
        φ : fol.parse 'A'
      result = match.apply pattern, matches
      expectedResult = fol.parse 'not not A'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "correctly applies a simple match to a pattern when the match occurs more than once", ->
      pattern = fol.parse 'not not (φ and (φ or φ))'
      matches = 
        φ : fol.parse 'A'
      result = match.apply pattern, matches
      expectedResult = fol.parse 'not not (A and (A or A))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "correctly applies a match with multiple `expression_variable`s to a pattern", ->
      pattern = fol.parse 'not (φ and not ψ)'
      matches = 
        φ : fol.parse 'A'
        ψ : fol.parse 'B or C'
      result = match.apply pattern, matches
      expectedResult = fol.parse 'not (A and not (B or C))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "correctly applies a match a `term_metavariable` to a pattern", ->
      pattern = fol.parse 'Loves(α,b) and not α=b'
      matches = 
        α : fol.parse('F(a)').termlist[0] #i.e. {type='name', name='a', ...}
      result = match.apply pattern, matches
      expectedResult = fol.parse 'Loves(a,b) and not a=b'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "correctly applies a match a `term_metavariable_hat` to a pattern", ->
      pattern = tellerFOL.parse 'Lα^b and not α^=b'
      matches = 
        'α^' : tellerFOL.parse('Fa^').termlist[0] #i.e. {type='name', name='a^', ...}
      result = match.apply pattern, matches
      expectedResult = tellerFOL.parse 'La^b and not a^=b'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "does not mutate its parameters", ->
      pattern = fol.parse 'not not φ'
      matches = 
        φ : fol.parse 'A'
      prePattern = _.cloneDeep pattern
      preMatches = _.cloneDeep matches
      match.apply pattern, matches
      expect(pattern).to.deep.equal(prePattern)
      expect(matches).to.deep.equal(preMatches)

    it "does not remove the box (as in `[a]F(x)`) when applying matches", ->
      pattern = fol.parse '[α]F(x)'
      matches = 
        α : (fol.parse 'F(a)').termlist[0]
      result = match.apply pattern, matches
      expectedResult = fol.parse '[a]F(x)'
      test = util.areIdenticalExpressions result, expectedResult
      if not test
        console.log "result = #{util.expressionToString result}"
        console.log "expectedResult = #{util.expressionToString expectedResult}"
      expect(test).to.be.true

    it "does not remove the box (as in `[a]F(x)`) when applying matches (when substituting for expression and box)", ->
      pattern = fol.parse '[α]φ'
      matches = 
        φ : fol.parse 'F(x)'
        α : (fol.parse 'F(a)').termlist[0]
      result = match.apply pattern, matches
      expectedResult = fol.parse '[a]F(x)'
      test = util.areIdenticalExpressions result, expectedResult
      if not test
        console.log "result = #{util.expressionToString result}"
        console.log "expectedResult = #{util.expressionToString expectedResult}"
      expect(test).to.be.true

    it "does not remove the box (as in `[a]F(x)`) when applying matches (tricky case)", ->
      pattern = fol.parse '[α]φ[τ-->α]'
      matches = 
        φ : fol.parse 'F(x)'
        τ : (fol.parse 'F(x)').termlist[0]
        α : (fol.parse 'F(a)').termlist[0]
      result = match.apply pattern, matches
      expectedResult = fol.parse '[a]F(x)[x-->a]'
      test = util.areIdenticalExpressions result, expectedResult
      if not test
        console.log "result = #{util.expressionToString result}"
        console.log "expectedResult = #{util.expressionToString expectedResult}"
      expect(test).to.be.true

    it "applies matches to a term in a box (as in `[α]F(x)`)", ->
      pattern = fol.parse '[α]F(x)'
      matches = 
        α : (fol.parse 'F(a)').termlist[0]
      result = match.apply pattern, matches
      expectedResult = fol.parse '[a]F(x)'
      test = util.areIdenticalExpressions result, expectedResult
      if not test
        console.log "result = #{util.expressionToString result}"
        console.log "expectedResult = #{util.expressionToString expectedResult}"
      expect(test).to.be.true

    it "applies matches to just a box (as in `[α]`)", ->
      pattern = fol.parse '[α]'
      matches = 
        α : (fol.parse 'F(a)').termlist[0]
      result = match.apply pattern, matches
      expectedResult = fol.parse '[a]'
      test = util.areIdenticalExpressions result, expectedResult
      if not test
        console.log "result = #{util.expressionToString result}"
        console.log "expectedResult = #{util.expressionToString expectedResult}"
      expect(test).to.be.true

  describe '`.apply` to expressions with substitutions', ->
    it "applies matches within a substitution (terms, lhs)", ->
      pattern = fol.parse 'Loves(a,b)[α-->c]'
      matches = 
        α : fol.parse('F(a)').termlist[0] #i.e. {type='name', name='a', ...}
      result = match.apply pattern, matches
      expectedResult = fol.parse 'Loves(a,b)[a-->c]'
      console.log util.expressionToString(result)
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    it "applies matches within a substitution (terms to variables, lhs)", ->
      pattern = fol.parse 'Loves(a,b)[α-->c]'
      matches = 
        α : fol.parse('F(x)').termlist[0]
      result = match.apply pattern, matches
      expectedResult = fol.parse 'Loves(a,b)[x-->c]'
      console.log util.expressionToString(result)
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    it "applies matches within a substitution (terms, rhs)", ->
      pattern = fol.parse 'Loves(a,b)[b-->α]'
      matches = 
        α : fol.parse('F(a)').termlist[0] #i.e. {type='name', name='a', ...}
      result = match.apply pattern, matches
      expectedResult = fol.parse 'Loves(a,b)[b-->a]'
      console.log util.expressionToString(result)
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    it "applies matches within a substitution (expressions, lhs)", ->
      pattern = fol.parse '(A and B)[φ-->C]'
      matches = 
        φ : fol.parse 'A'
      result = match.apply pattern, matches
      expectedResult = fol.parse '(A and B)[A-->C]'
      console.log util.expressionToString(result)
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    it "applies matches within a substitution (expressions, rhs)", ->
      pattern = fol.parse '(A and B)[A-->φ]'
      matches = 
        φ : fol.parse 'C'
      result = match.apply pattern, matches
      expectedResult = fol.parse '(A and B)[A-->C]'
      console.log util.expressionToString(result)
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "works for φ[τ-->α] (tricky case?)", ->
      pattern = fol.parse 'φ[τ-->α]'
      matches = 
        φ : fol.parse 'F(x)'
        τ : (fol.parse('F(x)')).termlist[0]
      result = match.apply pattern, matches
      expectedResult = fol.parse 'F(x)[x-->α]'
      console.log "result = #{util.expressionToString result}"
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "leaves things alone when there is no match", ->
      pattern = fol.parse 'φ'
      matches = {}
      result = match.apply pattern, matches
      expectedResult = fol.parse 'φ'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "leaves things alone when there is no match (including in substitutions)", ->
      pattern = fol.parse 'φ[τ-->α]'
      matches = {}
      result = match.apply pattern, matches
      expectedResult = fol.parse 'φ[τ-->α]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    
    it "works for A[τ-->α] (tricky case?)", ->
      pattern = fol.parse 'A[τ-->α]'
      matches = 
        φ : fol.parse 'F(x)'
        τ : (fol.parse('F(x)')).termlist[0]
      result = match.apply pattern, matches
      expectedResult = fol.parse 'A[x-->α]'
      # In this case the `.to` from `expectedResult.substitutions` is missing
      console.log "result = #{JSON.stringify result,null,4}"
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "does not remove substitutions with terms (as in `α=b[b-->c]`)", ->
      pattern = fol.parse 'α=b[b-->c]'
      matches = 
        α : fol.parse('F(a)').termlist[0] #i.e. {type='name', name='a', ...}
      result = match.apply pattern, matches
      expectedResult = fol.parse 'a=b[b-->c]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "does not remove substitutions with propositional expressions (as in `φ[A-->B] and C`)", ->
      pattern = fol.parse 'φ[A-->B] and C'
      matches = 
        φ : fol.parse 'A'
      result = match.apply pattern, matches
      expectedResult = fol.parse 'A[A-->B] and C'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "replaces propositional expressions in substitutions (as in `A[φ-->B]`)", ->
      pattern = fol.parse 'A[φ-->B]'
      matches = 
        φ : fol.parse 'A'
      result = match.apply pattern, matches
      expectedResult = fol.parse 'A[A-->B]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "replaces term_metavariables in substitutions (as in `F(a)[α-->x]`)", ->
      pattern = fol.parse 'F(a)[α-->x]'
      matches = 
        α : fol.parse('F(a)').termlist[0] #i.e. {type='name', name='a', ...}
      result = match.apply pattern, matches
      expectedResult = fol.parse 'F(a)[a-->x]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "replaces propositional expressions in the right hand side of substitutions (as in `A[A-->φ]`)", ->
      pattern = fol.parse 'A[A-->φ]'
      matches = 
        φ : fol.parse 'B'
      result = match.apply pattern, matches
      expectedResult = fol.parse 'A[A-->B]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "replaces term_metavariables in the right hand side of substitutions (as in `F(a)[a-->α]`)", ->
      pattern = fol.parse 'F(a)[a-->α]'
      matches = 
        α : fol.parse('F(b)').termlist[0] #i.e. {type='name', name='b', ...}
      result = match.apply pattern, matches
      expectedResult = fol.parse 'F(a)[a-->b]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "doesn't die when given null (as in `F(a)[a-->null]`)", ->
      pattern = fol.parse 'F(α)[α-->null]'
      matches = 
        α : fol.parse('F(b)').termlist[0] #i.e. {type='name', name='b', ...}
      result = match.apply pattern, matches
      expectedResult = fol.parse 'F(b)[b-->null]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true


  describe '`.apply` to expressions with boxes', ->
    it "applies a match to a term_metavariable in a box", ->
      pattern = fol.parse '[α] Loves(α,b)'
      matches = 
        α : fol.parse('F(a)').termlist[0] #i.e. {type='name', name='a', ...}
      result = match.apply pattern, matches
      expectedResult = fol.parse '[a] Loves(a,b)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      

