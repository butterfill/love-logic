_ = require 'lodash'

chai = require('chai')
assert = chai.assert
expect = chai.expect
substitute = require('../substitute')
fol = require '../parser/awFOL'
util = require('../util')
symmetry = require('../symmetry')

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

describe 'substitute', ->
  describe 'findMatches', ->
    it "should find match 'not not φ' with φ='A' in 'not not A'", ->
      pattern = fol.parse 'not not φ'
      expression = fol.parse 'not not A'
      matches = substitute.findMatches expression, pattern
      expectedMatch = PROP_A
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatch)).to.be.true

    it "should find match 'not not φ' with φ='A and B' in 'not not (A and B)'", ->
      pattern = fol.parse 'not not φ'
      expression = fol.parse 'not not (A and B)'
      matches = substitute.findMatches expression, pattern
      expectedMatch = fol.parse("A and B")
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatch)).to.be.true

    it "should fail to find match 'not not φ' in 'not (not A and B)'", ->
      pattern = fol.parse 'not not φ'
      expression = fol.parse 'not (not A and B)'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
 
    it "should find match 'not (φ or ψ)' with φ='A' in 'not (A or (B arrow C))'", ->
      pattern = fol.parse 'not (φ or ψ)'
      expression = fol.parse 'not (A or (B arrow C))'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        φ : PROP_A
        ψ : fol.parse("B arrow C")
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
      expect(util.areIdenticalExpressions(matches.ψ, expectedMatches.ψ)).to.be.true

    it "does not match 'φ or φ' in 'A or B'", ->
      pattern = fol.parse 'φ or φ'
      expression = fol.parse 'A or B'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false

    it "does not match 'φ or φ' in 'A or not A'", ->
      pattern = fol.parse 'φ or φ'
      expression = fol.parse 'A or not A'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false

    it "does not match 'φ or φ' in 'A or A'", ->
      pattern = fol.parse 'φ or φ'
      expression = fol.parse 'A or A'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        φ : fol.parse("A")
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
    
    it "matches a sentence with the same (no expression variables)", ->
      pattern = fol.parse 'A or A'
      expression = fol.parse 'A or A'
      matches = substitute.findMatches expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      
    it "does not match different sentences (no expression variables)", ->
      pattern = fol.parse 'A or A'
      expression = fol.parse 'B or B'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false

    it "should return an object (the matches) in which the values do not have extraneous properties", ->
      pattern = fol.parse 'F(α)'
      expression = fol.parse 'F(a)'
      matches = substitute.findMatches expression, pattern
      theMatch = matches.α
      theMatchClone = util.cloneExpression theMatch
      util.delExtraneousProperties theMatchClone 
      expect(theMatch).to.deep.equal(theMatchClone)
    it "should return an object (the matches) in which the values do not have extraneous properties (with variables)", ->
      pattern = fol.parse 'F(α)'
      expression = fol.parse 'F(x)'
      matches = substitute.findMatches expression, pattern
      theMatch = matches.α
      theMatchClone = util.cloneExpression theMatch
      util.delExtraneousProperties theMatchClone 
      expect(theMatch).to.deep.equal(theMatchClone)
    it "should return an object (the matches) in which the values do not have extraneous properties (with propositional expressions)", ->
      pattern = fol.parse 'φ1 or φ1'
      expression = fol.parse 'A or A'
      matches = substitute.findMatches expression, pattern
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
      newMatches = substitute.findMatches expression, pattern, oldMatches
      expect(newMatches.φ1.letter).to.equal('A')
      expect(newMatches.φ2.letter).to.equal('B')
      expect(newMatches.φ3.letter).to.equal('C')
    
    it "does not mutate the `pattern` parameter", ->
      pattern = fol.parse 'φ1 or φ2'
      expression = fol.parse 'A or B'
      patternClone = _.cloneDeep pattern  # Note that we can't use util.cloneExpression here.
      substitute.findMatches expression, pattern
      expect(pattern).to.deep.equal(patternClone)
    
    it "does not mutate the `expression` parameter", ->
      pattern = fol.parse 'φ1 or φ2'
      expression = fol.parse 'A or B'
      expressionClone = _.cloneDeep expression
      substitute.findMatches expression, pattern
      expect(expression).to.deep.equal(expressionClone)
    
  describe 'findMatches with boxes', ->
    it "matches a pattern to [a] (empty expression)", ->
      pattern = fol.parse '[α]'
      expression = fol.parse '[a]'
      matches = substitute.findMatches expression, pattern
      expect(matches).not.to.be.false
    it "matches pattern '[α] A' to '[a]A'", ->
      pattern = fol.parse '[α] A'
      expression = fol.parse '[a] A'
      matches = substitute.findMatches expression, pattern
      expect(matches).not.to.be.false
    it "doesn't match pattern '[α] A' to 'A'", ->
      pattern = fol.parse '[α] A'
      expression = fol.parse 'A'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
    it "doesn't match `[α]φ` to `F(a)` ", ->
      pattern = fol.parse '[α]φ'
      expression = fol.parse 'F(a)'
      matches = substitute.findMatches expression, pattern
      # Test the test:
      pattern2 = fol.parse 'φ'
      expect( util.areIdenticalExpressions(pattern, pattern2) ).to.be.false
      # The test:
      expect(matches).to.be.false
    it "doesn't match `[α]φ and α=b` to `[b]F(a) and a=b` ", ->
      pattern = fol.parse '[α]φ and α=b'
      expression = fol.parse '[b]F(a) and a=b'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
      
    it "matches `[α]φ` to `[b]F(x)`", ->
      pattern = fol.parse '[α]φ'
      expression = fol.parse '[b]F(x)'
      matches = substitute.findMatches expression, pattern
      expect(matches).not.to.be.false
    it "doesn't match `[α]φ` to `[b]F(x)` given `matches` ", ->
      pattern = fol.parse '[α]φ'
      expression = fol.parse '[b]F(x)'
      theMatches = 
        α : (fol.parse 'F(a)').termlist[0]
      matches = substitute.findMatches expression, pattern, theMatches
      expect(matches).to.be.false

  describe 'findMatches with expressions that are not closed wffs', ->
    it "matches 'all x not φ' in 'all x (not (F(x) and G(x)))", ->
      pattern = fol.parse 'all x not φ'
      expression = fol.parse 'all x (not (F(x) and G(x)))'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        φ : fol.parse("F(x) and G(x)")
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
      

  describe 'findMatches with `term_metavariable`s', ->
    it "should find match 'α=α' with α='a' in 'a=a'", ->
      pattern = fol.parse 'α=α'
      expression = fol.parse 'a=a'
      matches = substitute.findMatches expression, pattern
      expectedMatch = expression.termlist[0]
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.α, expectedMatch)).to.be.true

    it "should find match 'Loves(α,b) and φ'", ->
      pattern = fol.parse 'Loves(α,b) and φ'
      expression = fol.parse 'Loves(a,b) and Loves(b,a)'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        φ : fol.parse("Loves(b,a)")
        α : fol.parse("F(a)").termlist[0] #i.e. {type='name', name='a', ...}
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
      expect(util.areIdenticalExpressions(matches.α, expectedMatches.α)).to.be.true
      
    it "matches for pattern α=β", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      matches = substitute.findMatches expression1, pattern
      expectedMatches =
        "α" : NAME_A
        "β" : NAME_B
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.α, expectedMatches.α)).to.be.true
      expect(util.areIdenticalExpressions(matches.β, expectedMatches.β)).to.be.true

    it "matches for pattern 'all τ φ", ->
      pattern = fol.parse 'all τ φ'
      expression = fol.parse '(all x) (F(x) and G(x))'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        "τ" : VARIABLE_X
        "φ" : expression.left
      expect(matches).not.to.be.false
      expect(util.areIdenticalExpressions(matches.τ, expectedMatches.τ)).to.be.true
      expect(util.areIdenticalExpressions(matches.φ, expectedMatches.φ)).to.be.true
    
    it "matches 'exists τ1 exists τ2 (F(τ1) and G(τ2))'", ->
      expression = fol.parse 'exists x exists y (F(x) and G(y))'
      pattern = fol.parse 'exists τ1 exists τ2 (F(τ1) and G(τ2))'
      result = substitute.findMatches expression, pattern
      expect(result).not.to.be.false


  describe 'findMatches where identity can be treated as symmetric', ->
    it "does not find match 'α1=α2 and α1=α2'", ->
      pattern = fol.parse 'α1=α2 and α1=α2'
      expression = fol.parse 'a=b and b=a'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
      

  describe 'using findMatches where what the expression variables must match is stipulated', ->
    it "matches for pattern α=β with specified matches (expect success)", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      stipulatedMatches = {"α":NAME_A, "β":NAME_B}
      matches = substitute.findMatches expression1, pattern, stipulatedMatches
      expect(matches).not.to.be.false
      
    it "matches for pattern α=β with specified matches (expect failure)", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      stipulatedMatches =
        "α" : NAME_B
        "β" : NAME_A
      matches = substitute.findMatches expression1, pattern, stipulatedMatches
      expect(matches).to.be.false


  describe 'using findMatches with substitutions', ->
    it "returns {} when expressions match and there are no metavariables", ->
      pattern = fol.parse 'F(a)'
      expression = fol.parse 'F(a)'
      matches = substitute.findMatches expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "returns false when expressions do not match and there are no metavariables", ->
      pattern = fol.parse 'F(a)'
      expression = fol.parse 'F(b)'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
    it "finds matches where applying a substitution would produce a match", ->
      pattern = fol.parse 'F(a)[a->b]'
      expression = fol.parse 'F(b)'
      matches = substitute.findMatches expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where applying a substitution would break the match", ->
      pattern = fol.parse 'F(a)[a->b]'
      expression = fol.parse 'F(a)'
      matches = substitute.findMatches expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where partially applying a substitution would produce a match", ->
      pattern = fol.parse '(a=a)[a->b]'
      expression = fol.parse 'a=b'
      matches = substitute.findMatches expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where partially applying a substitution with a meta variable matches", ->
      pattern = fol.parse '(a=a)[a->α]'
      expression = fol.parse 'a=b'
      matches = substitute.findMatches expression, pattern
      expectedMatches = 
        α : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't match where partially applying a substitution with a meta variable would be wrong", ->
      pattern = fol.parse '((a=a) and (a=a))[a->α]'
      expression = fol.parse 'a=b1 and a=b2'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
    it "finds matches where partially applying a substitution would produce a match (example with predicates)", ->
      pattern = fol.parse '(F(a) and F(a))[a->b]'
      expression = fol.parse 'F(a) and F(b)'
      matches = substitute.findMatches expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "[test for the next test]", ->
      pattern = fol.parse '(F(a) and F(β))'
      expression = fol.parse 'F(a) and F(b)'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where partially applying a substitution involving a term_metavariable would produce a match (example with predicates)", ->
      pattern = fol.parse '(F(a) and F(a))[a->β]'
      expression = fol.parse 'F(a) and F(b)'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't match where applying a substitution involving a term_metavariable would require to to have two values", ->
      pattern = fol.parse '(F(a) and F(a))[a->β]'
      expression = fol.parse 'F(c) and F(b)'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
    it "finds matches where partially applying a substitution involving a term_metavariable ... other way around", ->
      # It's important to test two ways around to avoid accidental success 
      # contingent based on the route an expression tree walker takes
      pattern = fol.parse '(F(a) and F(a))[a->β]'
      expression = fol.parse 'F(b) and F(a)'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where partially applying a substitution involving a term_metavariable ... middle", ->
      # As above, it's important to test different ways around to avoid accidental success 
      # contingent based on the route an expression tree walker takes
      pattern = fol.parse '(F(a) and (F(a) and F(a)))[a->β]'
      expression = fol.parse '(F(a) and (F(b) and F(a)))'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where partially applying a substitution involving a term_metavariable ... two of four, different branches", ->
      # As above, it's important to test different ways around to avoid accidental success 
      # contingent based on the route an expression tree walker takes
      pattern = fol.parse '((F(a) or F(a)) and (F(a) and F(a)))[a->β]'
      expression = fol.parse '((F(a) or F(b)) and (F(b) and F(a)))'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't finds matches where partially applying a substitution involving a term_metavariable would require it having multiple values", ->
      # The concern here is that `β` could be matched with `d` in one
      # branch and with `c` in the other branch.  But this would be incorrect:
      # `expression` is not a substitution instance of `pattern`.
      pattern = fol.parse '((F(a) or F(a)) and (F(a) and F(a)))[a->β]'
      expression = fol.parse '((F(a) or F(d)) and (F(c) and F(a)))'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
    it "does finds matches from `F(a)[a->β] and F(a)[a->β]` to `F(a) and F(c)`", ->
      pattern = fol.parse 'F(a)[a->β] and F(a)[a->β]'
      expression = fol.parse 'F(a) and F(c)'
      matches = substitute.findMatches expression, pattern
      expect(matches).not.to.be.false
    it "doesn't finds matches from `F(a)[a->β] and F(a)[a->β]` to `F(b) and F(c)`", ->
      # The concern here is that `β` could be matched with `d` in one
      # branch and with `c` in the other branch.  But this would be incorrect:
      # `expression` is not a substitution instance of `pattern`.
      pattern = fol.parse 'F(a)[a->β] and F(a)[a->β]'
      expression = fol.parse 'F(b) and F(c)'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
    it "finds matches requiring partially applying a substitution involving a sentence variable", ->
      pattern = fol.parse '(A and B)[B->φ]'
      expression = fol.parse 'A and A'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        φ : PROP_A
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't choke with identical substitutions (like `[φ->φ]`)", ->
      pattern = fol.parse '(φ and A)[φ->φ]'
      expression = fol.parse 'A and A'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        φ : PROP_A
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't allow identical substitutions (like `[φ->φ]`) to change things", ->
      pattern = fol.parse '(φ and φ and A)[φ->φ]'
      expression = fol.parse 'B and C and A'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
    it "matches with substitutions between metavariables (like `[φ->ψ]`)", ->
      pattern = fol.parse '(φ and φ and A)[φ->ψ]'
      expression = fol.parse 'B and C and A'
      matches = substitute.findMatches expression, pattern
      expect(matches).not.to.be.false
      # There are multiple correct matches that could be made here.
    it "matches with substitutions between metavariables (like `[φ->ψ]`), more complex case", ->
      pattern = fol.parse '(φ and φ and φ and φ and A)[φ->ψ]'
      expression = fol.parse 'B and C and C and B and A'
      matches = substitute.findMatches expression, pattern
      expect(matches).not.to.be.false
      # There are multiple correct matches that could be made here.
    it "test simplify (no metavariables)", ->
      # This fails if you allow substitutions to replace within substitutions.
      # It fails because [A->B] becomes [A->C] before it can be applied.
      # (The only way around this would to be to branch for replacements 
      # within substitutions.)
      # log with replacing inside substitutions:
          # branching for sub B->C from pattern = (A[B->C] and B[B->C] )[A->B]
          # branching for sub A->B from pattern = A[B->C,A->B] and B[B->C,A->B]
          # branching for sub A->B from pattern = A[B->C]
          # branching for sub B->C from pattern = A
          # branching for sub B->C from pattern = A
          # branching for sub B->C from pattern = A
          # branching for sub A->B from pattern = A[B->C]
          # branching for sub B->C from pattern = A
          # branching for sub B->C from pattern = A
          # branching for sub B->C from pattern = A
          # branching for sub A->C from pattern = A[A->C] and C[A->C]
          # branching for sub A->C from pattern = A
          # branching for sub A->C from pattern = A
      pattern = fol.parse '(A and B)[A->B][B->C]'
      expression = fol.parse 'B and C'
      matches = substitute.findMatches expression, pattern
      expect(matches).not.to.be.false
    it "matches with multiple substitutions between metavariables: [φ->ψ][ψ->χ] $outerfirst", ->
      # Test id 0A5EAB88-588D-11E5-B11A-FEB2F2E18425 $outerfirst
      # The problem isn't so much that this test fails as that `.findMatches` is 
      # not easily predictable in when the order of substitutions matters (see
      # surrounding tests).
      pattern = fol.parse '(φ and φ and φ)[φ->ψ][ψ->χ]'
      expression = fol.parse 'B and C and A' 
      matches = substitute.findMatches expression, pattern
      expect(matches).not.to.be.false
      # There are multiple correct matches that could be made here.
    it "matches with multiple substitutions between metavariables: [φ->ψ][ψ->χ] (additional rhs conjunction) $outerfirst", ->
      # $outerfirst
      pattern = fol.parse '(φ and φ and φ and D)[φ->ψ][ψ->χ]'
      expression = fol.parse 'B and C and A and D'
      matches = substitute.findMatches expression, pattern
      expect(matches).not.to.be.false
      # There are multiple correct matches that could be made here.
      
    it "matches with multiple substitutions between metavariables: [ψ->χ][φ->ψ]", ->
      pattern = fol.parse '(φ and φ and φ)[ψ->χ][φ->ψ]'
      expression = fol.parse 'B and C and A'
      matches = substitute.findMatches expression, pattern
      expect(matches).not.to.be.false
      # There are multiple correct matches that could be made here.
    it "matches with multiple substitutions, as above without metavariables", ->
      pattern = fol.parse '(A and A and A)[B->C][A->B]'
      expression = fol.parse 'B and C and A'
      matches = substitute.findMatches expression, pattern
      expect(matches).not.to.be.false
      
    it "matches with multiple substitutions between metavariables: variation with nesting", ->
      # This doesn't work because `.findMatches` doesn't try all combinations of 
      # substitutions before making any matches.
      # To make this work, we would need to change `.findMatches` so that it first
      # does all substitutions (in one of each possible combination) and then 
      # attempts to match.
      pattern = fol.parse '((φ and φ)[ψ->χ] and φ)[φ->ψ]'
      expression = fol.parse 'B and C and A'
      matches = substitute.findMatches expression, pattern
      expect(matches).not.to.be.false
      # There are multiple correct matches that could be made here.
    it "matches with multiple substitutions, variation; as above but without metavariables", ->
      pattern = fol.parse '((A and A)[B->C] and A)[A->B]'
      expression = fol.parse 'B and C and A'
      matches = substitute.findMatches expression, pattern
      expect(matches).not.to.be.false
      
    it "matches with multiple substitutions between metavariables: [φ->ψ][φ->χ]", ->
      pattern = fol.parse '(φ and φ and φ)[φ->ψ][φ->χ]'
      expression = fol.parse 'B and C and A'
      matches = substitute.findMatches expression, pattern
      expect(matches).not.to.be.false
      # There are multiple correct matches that could be made here.
    it "does not mutate its parameter `_matches` (even when there are multiple substitutions)", ->
      pattern = fol.parse '(F(a,b) and B)[B->φ][a->α][b->β]'
      expression = fol.parse 'F(c,d) and A'
      _matches =
        φ : PROP_A
      _matchesPre = _.cloneDeep _matches
      result = substitute.findMatches expression, pattern, _matches
      expect(result).not.to.be.false  # Test the test.
      expect(_matchesPre).to.deep.equal(_matches)
    it "does not mutate its parameter `_matches` (even when there are multiple and no match can be made)", ->
      pattern = fol.parse '(F(a,b) and F(a,b) and B)[B->φ][a->α][b->β]'
      expression = fol.parse 'F(c,d) and F(a1,a2) and A'
      _matches =
        φ : PROP_A
      _matchesPre = _.cloneDeep _matches
      result = substitute.findMatches expression, pattern, _matches
      expect(result).to.be.false  # Test the test.
      expect(_matchesPre).to.deep.equal(_matches)
      

  describe 'using findMatches with nested substitutions', ->
    it "finds matches where nested substitutions are required", ->
      pattern = fol.parse '(F(c)[c->α] and F(d))[d->β]'
      expression = fol.parse 'F(a) and F(b)'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where nested, partial substitutions are required", ->
      pattern = fol.parse '((F(c) and F(d) and F(c))[c->α] and F(d))[d->β]'
      expression = fol.parse '(F(c) and F(d) and F(a) and F(b))'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where nested, partial substitutions are required (variant1)", ->
      pattern = fol.parse '((F(c) and F(d) and F(c))[c->α] and F(d))[d->β]'
      expression = fol.parse '((F(a) and F(d) and F(c)) and F(b))'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where nested, partial substitutions are required (variant2)", ->
      pattern = fol.parse '((F(c) and F(d) and F(c))[c->α] and F(d))[d->β]'
      expression = fol.parse '(F(c) and F(b) and F(a) and F(d))'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where nested, partial substitutions are required (variant2b)", ->
      pattern = fol.parse '((F(c) and F(d) and F(c) and F(d))[c->α] and A)[d->β]'
      expression = fol.parse '((F(c) and F(b) and F(a) and F(d)) and A)'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)

  describe 'using findMatches with *multiple* substitutions', ->
    it "finds matches where multiple substitutions are required", ->
      pattern = fol.parse '(F(c) and F(d))[c->α,d->β]'
      expression = fol.parse 'F(a) and F(b)'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where multiple, partial substitutions are required", ->
      pattern = fol.parse '(F(c) and F(d) and F(c) and F(d))[c->α,d->β]'
      expression = fol.parse '(F(c) and F(d) and F(a) and F(b))'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't find matches with multiple, partial substitutions where one metavariable would have to have different values in subexpressions", ->
      pattern = fol.parse '(F(c) and F(d) and F(c) and F(d))[c->α,d->β]'
      expression = fol.parse '(F(b) and F(d) and F(a) and F(b))'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
    it "finds matches where multiple, partial substitutions are required (variant1)", ->
      pattern = fol.parse '(F(c) and F(d) and F(c) and F(d))[c->α,d->β]'
      expression = fol.parse '(F(a) and F(d) and F(c) and F(b))'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't find matches with multiple, partial substitutions where one metavariable would have to have different values in subexpressions (variant1)", ->
      pattern = fol.parse '(F(c) and F(d) and F(c) and F(d))[c->α,d->β]'
      expression = fol.parse '(F(a) and F(a) and F(c) and F(b))'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
    it "finds matches where multiple, partial substitutions are required (variant2)", ->
      pattern = fol.parse '(F(c) and F(d) and F(c) and F(d))[c->α,d->β]'
      expression = fol.parse '(F(c) and F(b) and F(a) and F(d))'
      matches = substitute.findMatches expression, pattern
      expectedMatches =
        α : NAME_A
        β : NAME_B
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "doesn't find matches with multiple, partial substitutions where one metavariable would have to have different values in subexpressions (variant2)", ->
      pattern = fol.parse '(F(c) and F(d) and F(c) and F(d))[c->α,d->β]'
      expression = fol.parse '(F(c) and F(b) and F(a) and F(a))'
      matches = substitute.findMatches expression, pattern
      expect(matches).to.be.false
  
  describe "`.findMatches`, a tricky case involving two or more substitutions", ->
    it "test B[B->φ]", ->
      pattern = fol.parse '(F(a) and F(a) and B)[B->φ]'
      expression = fol.parse 'F(a) and F(a) and A'
      result = substitute.findMatches expression, pattern
      expect(result).not.to.be.false  
    it "copes with a sequence of two substitutions, one partial [B->φ][a->α]", ->
      # Test id 82EE71B0-588C-11E5-9F92-48DB8BD11E5D 
      # This is an unexpected failure to do with the order of substitutions.
      pattern = fol.parse '((F(a) and F(a)) and B)[B->φ][a->α]'
      expression = fol.parse '(F(c) and F(a)) and A'
      result = substitute.findMatches expression, pattern
      expect(result).not.to.be.false  
    it "copes with a sequence of two substitutions, one partial [B->φ][a->α] (different order)", ->
      # Apparently difficulties with test 82EE71B0-588C-11E5-9F92-48DB8BD11E5D 
      # are specific to what happens with `term_metavariables`.
      pattern = fol.parse '((B and F(a)) and F(a))[B->φ][a->α]'
      expression = fol.parse '((A and F(a)) and F(c))'
      result = substitute.findMatches expression, pattern
      expect(result).not.to.be.false  
    it "copes with a sequence of two partial substitutions [B->φ][a->α]", ->
      # Comparing this test with 82EE71B0-588C-11E5-9F92-48DB8BD11E5D ,
      # you can see that the problem is to do with getting all the way to
      # the end of a sentence.
      pattern = fol.parse '((F(a) and F(a)) and B and C)[B->φ][a->α]'
      expression = fol.parse '(F(c) and F(a)) and A and C'
      result = substitute.findMatches expression, pattern
      expect(result).not.to.be.false  
    it "copes with a sequence of three partial substitutions [B->φ][a->α][b->β]", ->
      pattern = fol.parse '(F(a,b) and F(a,b) and B)[B->φ][a->α][b->β]'
      expression = fol.parse 'F(c,d) and F(a,b) and A'
      result = substitute.findMatches expression, pattern
      expect(result).not.to.be.false  
    it "copes with a sequence of three partial substitutions [B->φ][a->α][b->β] (different expression structure)", ->
      pattern = fol.parse '(F(a,b) and (F(a,b) and B))[B->φ][a->α][b->β]'
      expression = fol.parse 'F(c,d) and (F(a,b) and A)'
      result = substitute.findMatches expression, pattern
      expect(result).not.to.be.false  
    it "copes with a sequence of three partial substitutions [B->φ][a->α][b->β] (variant2)", ->
      pattern = fol.parse '(F(a,b) and F(a,b) and B and A)[B->φ][a->α][b->β]'
      expression = fol.parse 'F(c,d) and F(a,b) and A and A'
      result = substitute.findMatches expression, pattern
      expect(result).not.to.be.false  
      
      
  describe 'using findMatches with *sequential* substitutions', ->
    it "finds matches where two sequential substitutions are required", ->
      pattern = fol.parse '(F(c) and F(b))[c->x,x->a]'
      expression = fol.parse 'F(a) and F(b)'
      matches = substitute.findMatches expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where four sequential substitutions are required", ->
      # NB: these are out of order, so the correctness of this test might be
      # questioned.  (See comment to test F72C790A-5887-11E5-8641-BAD061EA09BE .)
      pattern = fol.parse '(F(c) and F(b))[c->x,x->y,y->z,z->a]'
      expression = fol.parse 'F(a) and F(b)'
      matches = substitute.findMatches expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where sequential substitutions are required irrespective of the order in which substitutions are written", ->
      pattern = fol.parse '((F(c) and F(b))[x->a])[c->x]'
      expression = fol.parse 'F(a) and F(b)'
      matches = substitute.findMatches expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)
    it "finds matches where sequential substitutions are required irrespective of the order in which substitutions are written (other way around)", ->
      # Test id F72C790A-5887-11E5-8641-BAD061EA09BE
      # You might regard this (or the previous) as an error.  I regard it as correct because `[x->a]` can
      # be applied to the `x` in `[c->x]`.  To change the behaviour of `.findMatches` such 
      # that this is incorrect, it would not be enough to restrice its use of `substitute.replace`
      # so that it doesn't replace in substitutions.
      pattern = fol.parse '((F(c) and F(b))[c->x])[x->a]'
      expression = fol.parse 'F(a) and F(b)'
      matches = substitute.findMatches expression, pattern
      expectedMatches = {}
      expect(matches).not.to.be.false
      expect(matches).to.deep.equal(expectedMatches)


  describe 'replace (replaces one expression or term with another)', ->    
    it "helps with testing whether a=b, F(a) therefore F(b) is ok", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      matches = substitute.findMatches expression1, pattern
      expression2 = fol.parse 'F(a)'
      result = substitute.replace expression2, {from:matches.α, to:matches.β}
      expression3 = fol.parse 'F(b)'
      expect(util.areIdenticalExpressions(result,expression3)).to.be.true
      
    it "helps with testing whether a=b, F(a) therefore G(b) is ok", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      matches = substitute.findMatches expression1, pattern
      expression2 = fol.parse 'F(a)'
      result = substitute.replace expression2, {from:matches.α, to:matches.β}
      expression3 = fol.parse 'G(b)'
      expect(util.areIdenticalExpressions(result,expression3)).to.be.false
      
    it "helps with testing whether a=b, F(b) therefore F(a) is ok", ->
      pattern = fol.parse 'α=β'
      expression1 = fol.parse 'a=b'
      matches = substitute.findMatches expression1, pattern
      expression2 = fol.parse 'F(b)'
      result = substitute.replace expression2, {from:matches.α, to:matches.β}
      expression3 = fol.parse 'F(a)'
      expect(util.areIdenticalExpressions(result,expression3)).to.be.false
    
    it "allows us to replace a variable with a `term_metavariable`", ->
      expression = fol.parse "Loves(x,a)"
      whatToReplace = 
        from : VARIABLE_X
        to : TERM_METAVARIABLE_T
      result = substitute.replace expression, whatToReplace
      expectedResult = fol.parse "Loves(τ,a)"
      expect( util.areIdenticalExpressions(result,expectedResult) ).to.be.true
    
    it "replaces all instances of a variable with a `term_metavariable`", ->
      expression = fol.parse "Loves(x,a) and F(x) arrow G(x)"
      whatToReplace = 
        from : VARIABLE_X
        to : TERM_METAVARIABLE_T
      result = substitute.replace expression, whatToReplace
      expectedResult = fol.parse "Loves(τ,a) and F(τ) arrow G(τ)"
      console.log "#{util.expressionToString result}"
      expect( util.areIdenticalExpressions(result, expectedResult) ).to.be.true

    it "allows us to tell whether 'F(a)' is an instance of 'all x F(x)'", ->
      expression = fol.parse "all x F(x)"
      boundVariable = expression.boundVariable
      expressionMinusQuantifier = expression.left
      whatToReplace = 
        from : boundVariable
        to : TERM_METAVARIABLE_T
      thePattern = substitute.replace expressionMinusQuantifier, whatToReplace
      aCandidateInstance = fol.parse "F(a)"
      theMatch = substitute.findMatches aCandidateInstance, thePattern
      expect(theMatch).not.to.be.false
      
    it "allows us to tell whether 'G(a)' is an instance of 'all x F(x)'", ->
      expression = fol.parse "all x F(x)"
      boundVariable = expression.boundVariable
      expressionMinusQuantifier = expression.left
      whatToReplace = 
        from : boundVariable
        to : TERM_METAVARIABLE_T
      thePattern = substitute.replace expressionMinusQuantifier, whatToReplace
      aCandidateInstance = fol.parse "G(a)"
      theMatch = substitute.findMatches aCandidateInstance, thePattern
      expect(theMatch).to.be.false
      
    it "allows us to tell whether 'F(b) and G(b)' is an instance of 'all y (F(y) and G(y))'", ->
      expression = fol.parse "all y (F(y) & G(y))"
      boundVariable = expression.boundVariable
      expressionMinusQuantifier = expression.left
      whatToReplace = 
        from : boundVariable
        to : TERM_METAVARIABLE_T
      thePattern = substitute.replace expressionMinusQuantifier, whatToReplace
      aCandidateInstance = fol.parse "F(b) & G(b)"
      theMatch = substitute.findMatches aCandidateInstance, thePattern
      expect(theMatch).not.to.be.false
      
    it "allows us to tell whether 'F(a) and G(b)' is an instance of 'all y (F(y) and G(y))'", ->
      expression = fol.parse "all y (F(y) & G(y))"
      boundVariable = expression.boundVariable
      expressionMinusQuantifier = expression.left
      whatToReplace = 
        from : boundVariable
        to : TERM_METAVARIABLE_T
      thePattern = substitute.replace expressionMinusQuantifier, whatToReplace
      aCandidateInstance = fol.parse "F(a) & G(b)"
      theMatch = substitute.findMatches aCandidateInstance, thePattern
      expect(theMatch).to.be.false
    
    it "replaces things in the box (as in '[a]F(a)')", ->
      expression = fol.parse "[a]F(a)"
      whatToReplace = 
        from : NAME_A
        to : NAME_B
      result = substitute.replace expression, whatToReplace
      expect(result.box.term.name).to.equal('b')
      expect(result.termlist[0].name).to.equal('b')
      
    it "replaces `term_metavariable`s in the box (as in '[τ]F(a)')", ->
      expression = fol.parse "[τ]F(a)"
      whatToReplace = 
        from : TERM_METAVARIABLE_T
        to : NAME_A
      result = substitute.replace expression, whatToReplace
      expect(result.box.term.name).to.equal('a')

    it "allows us to get from A to B", ->
      expression = fol.parse "A"
      whatToReplace =
        from : fol.parse "A"
        to : fol.parse "B"
      result = substitute.replace expression, whatToReplace
      expect(result.letter).to.equal('B')
      
    it "allows us to get from A[A->B] to B", ->
      expression = fol.parse "A[A->B]"
      whatToReplace =
        from : expression.substitutions[0].from
        to : expression.substitutions[0].to
      # Note : if we don't delete the substitutions, this won't work.
      delete expression.substitutions
      result = substitute.replace expression, whatToReplace
      expect(result.letter).to.equal('B')

    it "allows us to get from (A and B)[A->C] to A and C", ->
      expression = fol.parse "(A and B)[A->C]"
      whatToReplace =
        from : expression.substitutions[0].from
        to : expression.substitutions[0].to
      result = substitute.replace expression, whatToReplace
      expect(result.left.letter).to.equal('C')

    it "allows us to get from (a=b)[a->c] to c=b", ->
      expression = fol.parse "(a=b)[a->c]"
      whatToReplace =
        from : expression.substitutions[0].from
        to : expression.substitutions[0].to
      result = substitute.replace expression, whatToReplace
      expect(result.termlist[0].name).to.equal('c')

    it "allows us to get from (a=b)[a->τ] to τ=b", ->
      expression = fol.parse "(a=b)[a->τ]"
      whatToReplace =
        from : expression.substitutions[0].from
        to : expression.substitutions[0].to
      result = substitute.replace expression, whatToReplace
      expect(result.termlist[0].name).to.equal('τ')
    
    it "doesn't mess with substitutions", ->
      expression = fol.parse "(A and B)[C->D]"
      whatToReplace =
        from : fol.parse "A"
        to : fol.parse "B"
      result = substitute.replace expression, whatToReplace
      expect(expression.substitutions.length).to.equal(1)
      expect(result.substitutions.length).to.equal(1)

  describe '.applyMatches', ->
    it "correctly applies a simple match to a pattern", ->
      pattern = fol.parse 'not not φ'
      matches = 
        φ : fol.parse 'A'
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'not not A'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "correctly applies a simple match to a pattern when the match occurs more than once", ->
      pattern = fol.parse 'not not (φ and (φ or φ))'
      matches = 
        φ : fol.parse 'A'
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'not not (A and (A or A))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "correctly applies a match with multiple `expression_variable`s to a pattern", ->
      pattern = fol.parse 'not (φ and not ψ)'
      matches = 
        φ : fol.parse 'A'
        ψ : fol.parse 'B or C'
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'not (A and not (B or C))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "correctly applies a match a `term_metavariable` to a pattern", ->
      pattern = fol.parse 'Loves(α,b) and not α=b'
      matches = 
        α : fol.parse('F(a)').termlist[0] #i.e. {type='name', name='a', ...}
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'Loves(a,b) and not a=b'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "does not mutate its parameters", ->
      pattern = fol.parse 'not not φ'
      matches = 
        φ : fol.parse 'A'
      prePattern = _.cloneDeep pattern
      preMatches = _.cloneDeep matches
      substitute.applyMatches pattern, matches
      expect(pattern).to.deep.equal(prePattern)
      expect(matches).to.deep.equal(preMatches)

    it "does not remove the box (as in `[a]F(x)`) when applying matches", ->
      pattern = fol.parse '[α]F(x)'
      matches = 
        α : (fol.parse 'F(a)').termlist[0]
      result = substitute.applyMatches pattern, matches
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
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse '[a]F(x)'
      test = util.areIdenticalExpressions result, expectedResult
      if not test
        console.log "result = #{util.expressionToString result}"
        console.log "expectedResult = #{util.expressionToString expectedResult}"
      expect(test).to.be.true

    it "does not remove the box (as in `[a]F(x)`) when applying matches (tricky case)", ->
      pattern = fol.parse '[α]φ[τ->α]'
      matches = 
        φ : fol.parse 'F(x)'
        τ : (fol.parse 'F(x)').termlist[0]
        α : (fol.parse 'F(a)').termlist[0]
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse '[a]F(x)[x->a]'
      test = util.areIdenticalExpressions result, expectedResult
      if not test
        console.log "result = #{util.expressionToString result}"
        console.log "expectedResult = #{util.expressionToString expectedResult}"
      expect(test).to.be.true

    it "applies matches to a term in a box (as in `[α]F(x)`)", ->
      pattern = fol.parse '[α]F(x)'
      matches = 
        α : (fol.parse 'F(a)').termlist[0]
      result = substitute.applyMatches pattern, matches
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
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse '[a]'
      test = util.areIdenticalExpressions result, expectedResult
      if not test
        console.log "result = #{util.expressionToString result}"
        console.log "expectedResult = #{util.expressionToString expectedResult}"
      expect(test).to.be.true

  describe 'applyMatches to expressions with substitutions', ->
    it "applies matches within a substitution (terms, lhs)", ->
      pattern = fol.parse 'Loves(a,b)[α->c]'
      matches = 
        α : fol.parse('F(a)').termlist[0] #i.e. {type='name', name='a', ...}
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'Loves(a,b)[a->c]'
      console.log util.expressionToString(result)
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    it "applies matches within a substitution (terms to variables, lhs)", ->
      pattern = fol.parse 'Loves(a,b)[α->c]'
      matches = 
        α : fol.parse('F(x)').termlist[0]
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'Loves(a,b)[x->c]'
      console.log util.expressionToString(result)
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    it "applies matches within a substitution (terms, rhs)", ->
      pattern = fol.parse 'Loves(a,b)[b->α]'
      matches = 
        α : fol.parse('F(a)').termlist[0] #i.e. {type='name', name='a', ...}
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'Loves(a,b)[b->a]'
      console.log util.expressionToString(result)
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    it "applies matches within a substitution (expressions, lhs)", ->
      pattern = fol.parse '(A and B)[φ->C]'
      matches = 
        φ : fol.parse 'A'
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse '(A and B)[A->C]'
      console.log util.expressionToString(result)
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    it "applies matches within a substitution (expressions, rhs)", ->
      pattern = fol.parse '(A and B)[A->φ]'
      matches = 
        φ : fol.parse 'C'
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse '(A and B)[A->C]'
      console.log util.expressionToString(result)
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "works for φ[τ->α] (tricky case?)", ->
      pattern = fol.parse 'φ[τ->α]'
      matches = 
        φ : fol.parse 'F(x)'
        τ : (fol.parse('F(x)')).termlist[0]
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'F(x)[x->α]'
      console.log "result = #{util.expressionToString result}"
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "leaves things alone when there is no match", ->
      pattern = fol.parse 'φ'
      matches = {}
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'φ'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "leaves things alone when there is no match (including in substitutions)", ->
      pattern = fol.parse 'φ[τ->α]'
      matches = {}
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'φ[τ->α]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    
    it "works for A[τ->α] (tricky case?)", ->
      pattern = fol.parse 'A[τ->α]'
      matches = 
        φ : fol.parse 'F(x)'
        τ : (fol.parse('F(x)')).termlist[0]
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'A[x->α]'
      # In this case the `.to` from `expectedResult.substitutions` is missing
      console.log "result = #{JSON.stringify result,null,4}"
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "does not remove substitutions with terms (as in `α=b[b->c]`)", ->
      pattern = fol.parse 'α=b[b->c]'
      matches = 
        α : fol.parse('F(a)').termlist[0] #i.e. {type='name', name='a', ...}
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'a=b[b->c]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "does not remove substitutions with propositional expressions (as in `φ[A->B] and C`)", ->
      pattern = fol.parse 'φ[A->B] and C'
      matches = 
        φ : fol.parse 'A'
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'A[A->B] and C'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "replaces propositional expressions in substitutions (as in `A[φ->B]`)", ->
      pattern = fol.parse 'A[φ->B]'
      matches = 
        φ : fol.parse 'A'
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'A[A->B]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "replaces term_metavariables in substitutions (as in `F(a)[α->x]`)", ->
      pattern = fol.parse 'F(a)[α->x]'
      matches = 
        α : fol.parse('F(a)').termlist[0] #i.e. {type='name', name='a', ...}
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'F(a)[a->x]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "replaces propositional expressions in the right hand side of substitutions (as in `A[A->φ]`)", ->
      pattern = fol.parse 'A[A->φ]'
      matches = 
        φ : fol.parse 'B'
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'A[A->B]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "replaces term_metavariables in the right hand side of substitutions (as in `F(a)[a->α]`)", ->
      pattern = fol.parse 'F(a)[a->α]'
      matches = 
        α : fol.parse('F(b)').termlist[0] #i.e. {type='name', name='b', ...}
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'F(a)[a->b]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "doesn't die when given null (as in `F(a)[a->null]`)", ->
      pattern = fol.parse 'F(α)[α->null]'
      matches = 
        α : fol.parse('F(b)').termlist[0] #i.e. {type='name', name='b', ...}
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse 'F(b)[b->null]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true


  describe 'applyMatches to expressions with boxes', ->
    it "applies a match to a term_metavariable in a box", ->
      pattern = fol.parse '[α] Loves(α,b)'
      matches = 
        α : fol.parse('F(a)').termlist[0] #i.e. {type='name', name='a', ...}
      result = substitute.applyMatches pattern, matches
      expectedResult = fol.parse '[a] Loves(a,b)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      

  describe 'doSub', ->
    it "does a double-negation substitution", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not not A'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'A'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "is fine when a double-negation substitution can't be done", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not A'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'not A'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "does a deMorgan substitution", ->
      sub = 
        from : fol.parse 'not (φ and ψ)'
        to : fol.parse '(not φ) or (not ψ)'
      expression = fol.parse 'not ((A arrow B) and C)'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse '(not (A arrow B)) or (not C)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it 'does a "φ or true" substitution', ->
      sub = 
        from : fol.parse 'φ or true'
        to : fol.parse 'true'
      expression = fol.parse '((A arrow B) or true)'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'true'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "does not modify `expression` in place ", ->
      sub = 
        from : fol.parse 'φ or true'
        to : fol.parse 'true'
      expression = fol.parse '((A arrow B) or true)'
      pre = util.cloneExpression expression
      substitute.doSub expression, sub
      post = util.cloneExpression expression
      expect(pre).to.deep.equal(post)
    it "does a double-negation substitution", ->


  describe 'doSubRecursive', ->
    it "does a double-negation substitution", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not not A'
      result = substitute.doSubRecursive expression, sub
      expectedResult = fol.parse 'A'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "substitutes into substitutions", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'A[A->not not B]'
      result = substitute.doSubRecursive expression, sub
      expectedResult = fol.parse 'A[A->B]'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "does a double-negation substitution when the double neg is nested", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not (not not A & B)'
      result = substitute.doSubRecursive expression, sub
      # console.log "result #{util.expressionToString result}"
      expectedResult = fol.parse 'not (A and B)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "does not modify `expression` in place ", ->
      sub = 
        from : fol.parse 'not not φ'
        to : fol.parse 'φ'
      expression = fol.parse 'not not A'
      pre = util.cloneExpression expression
      substitute.doSubRecursive expression, sub
      post = util.cloneExpression expression
      expect(pre).to.deep.equal(post)


  describe 'subs, the built-in substitutions', ->
    it "does not_exists substitution", ->
      sub = substitute.subs.not_exists
      expression = fol.parse 'not exists y ( F(y))'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'all y (not F(y))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "does deMorgan1", ->
      expression = fol.parse 'not (not A and not (B or not C))'
      sub = substitute.subs.demorgan1
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'not not A or not not (B or not C)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "converts arrow correctly", ->
      expression = fol.parse 'A arrow B'
      sub = substitute.subs.replace_arrow
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'not A or B'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
        
    it "converts arrow correctly (when antecedent is complex)", ->
      expression = fol.parse '(A and B) arrow (C and D)'
      sub = substitute.subs.replace_arrow
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'not (A and B) or (C and D)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
        
    it "does replace_double_arrow", ->
      expression = fol.parse '(A ↔ B) ↔ (B and (A ↔ (A ↔ C)))'
      doubleArrowSymbol = expression.type
      result = substitute.doSubRecursive expression, substitute.subs.replace_double_arrow
      resultString = util.expressionToString result
      expect(resultString.indexOf(doubleArrowSymbol)).to.equal(-1)
    
    it "does not_all substitution", ->
      sub = substitute.subs.not_all
      expression = fol.parse 'not all z ( Loves(a,z))'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'exists z (not Loves(a,z))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "does all_and_left substitution", ->
      sub = substitute.subs.all_and_left
      expression = fol.parse 'P and all z ( Loves(a,z))'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'all z (P and Loves(a,z))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
      
    it "does all_and_right substitution", ->
      sub = substitute.subs.all_and_right
      expression = fol.parse 'all z ( R(a,z)) and P'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'all z (R(a,z) and P)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

    it "does all_or_left substitution", ->
      sub = substitute.subs.all_or_left
      expression = fol.parse 'exists x F(x) or all z G(z)'
      result = substitute.doSub expression, sub
      expectedResult = fol.parse 'all z (exists x F(x) or G(z))'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true
    
    it "does not alter the truth table of propositional sentences"
    # TODO (can't yet because don't have truth tables)


  describe 'subs_eliminate_redundancy', ->
    it "should transform A or (not a=a or not A)", ->
      e = fol.parse "A or (not a=a or not A)"
      subs = substitute.subs_eliminate_redundancy
      sub = subs.identity
      result = substitute.doSubRecursive e, sub
      expectedResult = fol.parse 'A or (not true or not A)'
      expect(util.areIdenticalExpressions(result, expectedResult)).to.be.true

  describe 'renameVariables', ->
    it "should rename the variables in a single quantifier phrase properly", ->
      expression = fol.parse 'exists(x) F(x)'
      substitute.renameVariables expression
      #console.log "expression #{JSON.stringify expression,null,4}"
      expect(expression.boundVariable.name).to.equal('xx1')
      expect(expression.left.termlist[0].name).to.equal('xx1')
      
    it "should rename the variables in a multiple quantifier phrase properly", ->
      expression = fol.parse 'exists(x) all(y) some(z) R(y,a,x,z)'
      substitute.renameVariables expression
      quantifier1 = expression
      quantifier2 = quantifier1.left
      quantifier3 = quantifier2.left
      predicate =  quantifier3.left
      terms = predicate.termlist
      expect(quantifier1.boundVariable.name).to.equal('xx1')
      expect(quantifier2.boundVariable.name).to.equal('xx2')
      expect(quantifier3.boundVariable.name).to.equal('xx3')
      expect(terms[0].name).to.equal(quantifier2.boundVariable.name)
      expect(terms[1].name).to.equal('a') #i.e. was not renamed
      expect(terms[2].name).to.equal(quantifier1.boundVariable.name)
      expect(terms[3].name).to.equal(quantifier3.boundVariable.name)
      
    it "renames the variables in a tricky quantifier phrase properly", ->
      expression = fol.parse 'exists(x) (F(x) and all(x) G(x))'
      substitute.renameVariables expression
      quantifier1 = expression
      quantifier2 = expression.left.right
      predicate1 = quantifier1.left.left
      predicate2 = quantifier2.left
      # Note: this test is a bit fragile because it depends on the particular 
      # renaming strategy used.
      console.log util.expressionToString(expression)
      expect(quantifier1.boundVariable.name).to.equal('xx1')
      expect(quantifier2.boundVariable.name).to.equal('xx2')
      expect(predicate1.termlist[0].name).to.equal(quantifier1.boundVariable.name)
      expect(predicate2.termlist[0].name).to.equal(quantifier2.boundVariable.name)
      
    it "should rename the variables in expressions involving identity", ->
      expression = fol.parse 'exists(x) x=a'
      substitute.renameVariables expression
      expect(expression.left.termlist[0].name).to.equal('xx1')
    
    it "does not repeat a variable name", ->
      expression = fol.parse '(exists x F(x)) and (exists x G(x))'
      substitute.renameVariables expression
      quantifier1 = expression.left
      quantifier2 = expression.right
      predicate1 = quantifier1.left
      predicate2 = quantifier2.left
      expect(quantifier1.boundVariable.name).to.equal('xx1')
      expect(quantifier2.boundVariable.name).to.equal('xx2')
      
    it "should create patterns if newVariableBaseName is a term metavariable symbol", ->
      expression = fol.parse '(exists x F(x)) and (exists x G(x))'
      substitute.renameVariables expression, 'τ'
      pattern = expression
      expression2 = fol.parse '(exists y F(y)) and (exists x1 G(x1))'
      match = substitute.findMatches expression2, pattern
      expect(match).not.to.be.false
      

  describe "odds and ends", ->
    it "should exhaustively apply substitutions", ->
      expression = fol.parse 'not (not A and not (B or not C))'
      fn = (expression) ->
        result = expression
        result = substitute.doSubRecursive result, substitute.subs.demorgan1
        result = substitute.doSubRecursive result, substitute.subs.demorgan2
        result = substitute.doSubRecursive result, substitute.subs.dbl_neg
        return result
      result = util.exhaust expression, fn
      # console.log "#{util.expressionToString result}"
      expect(result.type).to.not.equal('not')
    
    it "I just want to see this", ->
      theF = [ 
        fol.parse 'exists x (F(x) and all y (F(y) arrow x=y))'
        fol.parse 'exists x all y (F(y) ↔ x=y)'
        fol.parse 'exists x F(x) and exists x all y ( F(y) arrow x=y )'
      ]
      pnf = ( substitute.prenexNormalForm(e) for e in theF )
      for e in pnf
        symmetry.sortPNFExpression(e)
        symmetry.sortIdentityStatements(e)
        e = symmetry.eliminateRedundancyInPNF(e)
        console.log "the F : #{util.expressionToString e} "
      # throw "E"


  describe "isPNF", ->
    it "can tell you something isn't in PNF (quantifier scope wrong)", ->
      expression = fol.parse 'F(a) and exists(x) G(x)'
      expect( substitute.isPNF(expression) ).to.be.false
    it "can tell you something isn't in PNF (disjunction outside conjunction)", ->
      expression = fol.parse 'A and (B or (A and B))'
      expect( substitute.isPNF(expression) ).to.be.false
    it "can tell you something is in PNF", ->
      expression = fol.parse 'exists x all y ( (F(x) or G(x) ) and (F(y) or G(y)) )'
      expect( substitute.isPNF(expression) ).to.be.true
      

  describe "prenexNormalForm", ->
    it "gets rid of arrow", ->
      expression = fol.parse 'A arrow (B arrow C)'
      
      # Later we use util.expressionToString to help in checking whether all instances of 
      # arrow have been removed.  To do this we want to check how an arrow will appear in
      # this function.
      arrowSymbol = expression.type
      
      result = substitute.prenexNormalForm expression
      #console.log "#{util.expressionToString result}"
      expect(result.type).not.to.equal('arrow')
      resultString = util.expressionToString result
      expect(resultString.indexOf(arrowSymbol)).to.equal(-1)
      
    it "gets rid of double arrow", ->
      expression = fol.parse '(A ↔ B) ↔ (B and (A ↔ C))'
      doubleArrowSymbol = expression.type
      result = substitute.prenexNormalForm expression
      resultString = util.expressionToString result
      expect(resultString.indexOf(doubleArrowSymbol)).to.equal(-1)

    it "sorts out conjunction, negation and disjunction", ->
      expression = fol.parse 'not (not ((A and not B) or not (C or (D and not E))))'
      result = substitute.prenexNormalForm expression
      # If it is in PNF then we should have conjunctions of disjunctions of atomic sentences.
      conjuncts = symmetry.listJuncts result, 'and'
      nestedDisjuncts = ( symmetry.listJuncts(junct, 'or') for junct in conjuncts)
      for someDisjuncts in nestedDisjuncts
        for disjunct in someDisjuncts
          if disjunct.type isnt 'not'
            expect(disjunct.type).to.equal('sentence_letter')

    it "puts existential quantifiers outwards of conjuncts", ->
      expression = fol.parse '(exists x F(x)) and (exists x G(x))'
      result = substitute.prenexNormalForm expression
      #console.log "result = #{util.expressionToString result}"
      expectedMatch = fol.parse 'exists τ1 exists τ2 (F(τ2) and G(τ1))'
      test = substitute.findMatches result, expectedMatch
      expect(test).not.to.be.false
    
    it "deals with an example from wikipedia", ->
      expression = fol.parse 'all x ((exists y F(y)) or ((exists z G(z)) arrow H(x)))'
      result = substitute.prenexNormalForm expression
      # console.log "result = #{util.expressionToString result}"
      test = substitute.isPNF result
      expect(test).to.be.true
      

  describe "`.applySubstitutions` (as in `A[A->B]`)", ->
    it "works when there are no substitutions", ->
      expression = fol.parse "A and B"
      util.delExtraneousProperties expression
      result = substitute.applySubstitutions expression
      expect(result).to.deep.equal(expression)
    
    it "applies a simple substitution (to the main expression)", ->
      expression = fol.parse "A[A->B]"
      result = substitute.applySubstitutions expression
      expect(result.letter).to.equal('B')

    it "applies a simple substitution (to a component expression)", ->
      expression = fol.parse "(A and D)[A->B]"
      result = substitute.applySubstitutions expression
      expect(result.left.letter).to.equal('B')

    it "applies a substitution which is not at the root expression", ->
      expression = fol.parse "(A[A->B] and D)"
      result = substitute.applySubstitutions expression
      expect(result.left.letter).to.equal('B')

    it "applies two substitutions in the right order", ->
      # NOTE: This may fail if there is a problem with the awFOL parser.
      expression = fol.parse "((A and D)[A->B])[B->C]"
      console.log "expression = #{util.expressionToString(expression)}"
      result = substitute.applySubstitutions expression
      expect(result.left.letter).to.equal('C')
    
    it "takes `(A[A->B] and C)[B->D]` to `D and C`", ->
      expression = fol.parse "(A[A->B] and C)[B->D]"
      result = substitute.applySubstitutions expression
      expect(result.type).to.equal('and')
      expect(result.left.letter).to.equal('D')
      expect(result.right.letter).to.equal('C')

    it "does not mutate its parameter", ->
      expression = fol.parse "(A[A->B] and C)[B->D]"
      util.delExtraneousProperties expression
      pre = _.cloneDeep expression
      result = substitute.applySubstitutions expression
      post = expression
      expect(pre).not.to.deep.equal(result) # Test the test.
      expect(pre).to.deep.equal(post)
    
    describe "in the special case of `[α->null]` substitutions", ->
      it "is helped by `.replace` throwing a useful error", ->
        e = fol.parse "a=b"
        whatToReplace =
          from : (fol.parse "A[a->null]").substitutions[0].from
          to : (fol.parse "A[a->null]").substitutions[0].to
        expect( -> substitute.replace(e, whatToReplace) ).to.throw()
        try 
          substitute.replace(e, whatToReplace) 
        catch e 
          expect(e.message).to.equal("_internal: replace to null")
        
      it "applying `[a->null]` to an expression not containing `a` makes no difference", ->
        expression = fol.parse "b=c[a->null]"
        util.delExtraneousProperties expression
        pre = _.cloneDeep expression
        result = substitute.applySubstitutions expression
        post = expression
        expect(pre).to.deep.equal(post)
        
      it "applying `[a->null]` to `(b=c and A)` makes no difference", ->
        expression = fol.parse "(b=c and A)[a->null]"
        util.delExtraneousProperties expression
        pre = _.cloneDeep expression
        result = substitute.applySubstitutions expression
        post = expression
        expect(pre).to.deep.equal(post)
        
      it "applying `[a->null]` to `(a=c and A)` gives you null", ->
        expression = fol.parse "(a=c and A)[a->null]"
        util.delExtraneousProperties expression
        result = substitute.applySubstitutions expression
        expect(result).to.equal(null)
        
      it "applying `[a->null]` to `a=c` gives you null", ->
        expression = fol.parse "a=b[a->null]"
        util.delExtraneousProperties expression
        result = substitute.applySubstitutions expression
        expect(result).to.equal(null)
        











