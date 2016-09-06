# This serves as test of the tree verification too 
# (since this was the first set of rules for trees
# to be written).

chai = require 'chai' 
expect = chai.expect
should = chai.should()
_ = require 'lodash'

dialectManager = require('../../dialect_manager/dialectManager')
proof = require '../proof'

oldRules = []
oldParser = []
oldSymbols = []
pushRulesAndParser = () ->
  oldRules.push dialectManager.getCurrentRulesName()
  oldParser.push dialectManager.getCurrentParserName()
  oldSymbols.push dialectManager.getSymbolsName()
popRulesAndParser = () ->
  dialectManager.setCurrentRules(oldRules.pop())
  dialectManager.setCurrentParser(oldParser.pop())
  dialectManager.setSymbols(oldSymbols.pop())
setRulesAndParser = () ->
  dialectManager.set('logicbook')
  # TODO: should not be necessary
  # dialectManager.setCurrentRules('logicbook_tree')

testProof = (proofText, expected) ->
  theProof = proof.parse(proofText, {treeProof:true})
  console.log theProof if _.isString(theProof)
  # console.log newPrfTxt
  result = theProof.verifyTree()
  if result isnt expected
    console.log theProof.toString({numberLines:true})
    if expected
      console.log "errorMessages: "
      console.log theProof.listErrorMessages()
  if expected is true
    result.should.be.true
  else
    result.should.be.false
  
describe "logicbook tree rules", ->
  
  before () ->
    pushRulesAndParser()
    setRulesAndParser()
  after () ->
    popRulesAndParser()
    
  describe "basics", ->
    it "verifies a simple tree (includes explicitly closed branch)", ->
      text = '''
        A and not A
        A             and D 1
        not A         and D 1
        X
      '''
      testProof(text, true)
    it "verifies a simple tree with branching", ->
      text = '''
        A or B
        | A             or D 1
      
        | B         or D 1
      '''
      testProof(text, true)
    it "verifies a simple tree with longer branches", ->
      text = '''
        A or B      SM
        C and D     SM
        | A             or D 1
        | C         and D 2
        | D         and D 2
      
        | B         or D 1
        | C         and D 2
        | D         and D 2
      '''
      testProof(text, true)
    it "verifies a tree with a branching rule", ->
      text = '''
        A arrow B     SM
        | not A       arrow D 1
      
        | B     arrow D 1
      '''
      testProof(text, true)
    it "spots an error with branching in a nested case", ->
      text = '''
        1 | A ∨ B    Premise
        2 | C ∨ D    Premise
        3 || A     ∨D 1
        4 ||| C      ∨D 2
          || 
        4 ||| C      ∨D 2
          || 
          | 
        3 || B     ∨D 1
      '''
      testProof(text, false)
    it "does not allow Premise at the start of a branch", ->
      text = '''
        A arrow B     SM
        | not A       SM
      '''
      testProof(text, false)
    it "verifies a tree with nested branching (arrow, arrow)", ->
      text = '''
        A arrow B     SM
        C arrow D        SM
        | not C           arrow D 2
        || not A      arrow D 1
        |
        || B          arrow D 1
      
        | D           arrow D 2
        || not A      arrow D 1
        |
        || B          arrow D 1
      '''
      testProof(text, true)
    it "verifies a tree with nested branching (or, arrow)", ->
      text = '''
        A arrow B     SM
        C or D        SM
        | C           or D 2
        || not A      arrow D 1
        |
        || B          arrow D 1
      
        | D           or D 2
        || not A      arrow D 1
        |
        || B          arrow D 1
      '''
      testProof(text, true)
    it "does not allow a branching rule to be used without branching", ->
      text = '''
        A arrow B
        not A             arrow D 1
        B                 arrow D 1
      '''
      testProof(text, false)
    it "does not allow a branching rule to be used without making the right number of branches", ->
      text = '''
        A arrow B
        | not A             arrow D 1
      '''
      testProof(text, false)
    it "does not allow a branching rule to be used with making the right kind of branches", ->
      text = '''
        A arrow B
        | not A             arrow D 1
      
        | not A     arrow D 1
      '''
      testProof(text, false)
    it "does not allow a non-branching rule to be used with branching", ->
      text = '''
        A and B
        | A             and D 1
      
        | B             and D 1
      '''
      testProof(text, false)
    it "can cope with applying branching rules to sentences like `A or A` where the disjuncts are identical", ->
      # preliminary test:
      text = '''
        A or B    SM
        | A             or D 1
      
        | A             or D 1
      '''
      testProof(text, false)
      text = '''
        A or A    SM
        | A             or D 1
      
        | A             or D 1
      '''
      testProof(text, true)
      
  describe "syntax errors", ->
    it "can cope with a proof in which there are syntax errors", ->
      text = '''
        A and B             SM
        sausages            SM
      '''
      testProof(text, false)
    it "can cope with a proof in which there is missing justification", ->
      text = '''
        A and B             SM
        C and D 
      '''
      testProof(text, false)
    it "can cope with a proof in which there is incorrect justification", ->
      text = '''
        A and B             SM
        C and D         thisisntarule
      '''
      testProof(text, false)
    it "can cope with a proof in which there is missing line numbers", ->
      text = '''
        A and B             SM
        A           and D
      '''
      testProof(text, false)
    it "can cope with a proof in which part of  the justification is missing", ->
      text = '''
        A and B             SM
        A           D 1
      '''
      testProof(text, false)
    it "can cope with a proof in which another part of the justification is missing", ->
      text = '''
        A and B             SM
        A           and 1
      '''
      testProof(text, false)
                                                                                                
  describe "checking tick marks", ->
    it "verifies ticks in a simple case", ->
      text = '''
        A and not A   tick SM
        A             and D 1
        not A         and D 1
      '''
      testProof(text, true)
    it "spots an incorrect tick in a simple case", ->
      text = '''
        A and not A   tick SM
        A             and D 1
      '''
      testProof(text, false)
    it "verifies ticks in a simple branching case", ->
      text = '''
        A arrow B     tick SM
        | not A       arrow D 1
      
        | B     arrow D 1
      '''
      testProof(text, true)
    it "verifies ticks in a nested branching case", ->
      text = '''
        A arrow B     SM tick
        C or D        SM
        | C           or D 2
        || not A      arrow D 1
        |
        || B          arrow D 1
        
        | D           or D 2
        || not A      arrow D 1
        |
        || B          arrow D 1
      '''
      p = proof.parse(text)
      console.log p.getChildren().length
      testProof(text, true)
    it "spots an error with ticks in a simple branching case", ->
      text = '''
        A and B     SM tick
        C or D        SM
        | C           or D 2
        | A      and D 1
        | B      and D 1
      
        | D           or D 2
      '''
      testProof(text, false)
    it "spots an error with ticks in a nested branching case", ->
      text = '''
        A arrow B     SM tick
        C or D        SM
        | C           or D 2
        || not A      arrow D 1
        |
        || B          arrow D 1
      
        | D           or D 2
      '''
      testProof(text, false)

  describe "enforcing structure on tree proofs in sequent form", ->
    it "does not allow further lines after a branch", ->
      # First check that the supposedly correct form of the proof works:
      text = '''
        A and B       SM 
        C or D        SM
        | C           or D 2
      
        | D           or D 2
        | A           and D 1
      '''
      testProof(text, true)
      # Now make the change which should cause it to be incorrect:
      text = '''
        A and B       SM 
        C or D        SM
        | C           or D 2
      
        | D           or D 2
        A             and D 1
      '''
      testProof(text, false)

    it "does not allow further lines after a nested branch", ->
      text = '''
        A and B       SM 
        C or D        SM
        E arrow F     SM
        | C           or D 2
      
        | D           or D 2
        || not E      arrow D 3
        |
        || F          arrow D 3
        || A           and D 1
      '''
      testProof(text, true)
      text = '''
        A and B       SM 
        C or D        SM
        E arrow F     SM
        | C           or D 2
      
        | D           or D 2
        || not E      arrow D 3
        |
        || F          arrow D 3
        | A           and D 1
      '''
      testProof(text, false)

  
  describe "the rule exists D2", ->
    it "verifies a tree proof with exists D2", ->
      text = '''
        (exists x) Gx    SM
        Fa               SM
        Fb               SM
        | Ga                          1 exists D2
      
        | Gb                          1 exists D2
      
        | Gc                          1 exists D2
      '''
      testProof(text, true)
  
    it "identifies a mistake in a tree proof with exists D2 (no branch for a new constant)", ->
      text = '''
        (exists x) Gx    SM
        Fa               SM
        Fb               SM
        | Ga                          1 exists D2
      
        | Gb                          1 exists D2
      '''
      testProof(text, false)
    it "identifies another mistake in a tree proof with exists D2 (no branch for an existing constant)", ->
      text = '''
        (exists x) Gx    SM
        Fa               SM
        Fb               SM
        | Ga                          1 exists D2
      
        | Gc                          1 exists D2
      '''
      testProof(text, false)
  
    it "verifies a more complex tree proof with exists D2", ->
      text = '''
        (all x) (Fx arrow (exists y) Gyx)   SM
        (all x) Fx                        SM
        Fa                              2 universal D
        Fa arrow (exists y) Gya           tick 1 universal D
        | not Fa                        4 -> D
        | X

        | (exists y) Gya                  4 -> D
        || Gaa                          8 existential D2
        |
        || Gba                          8 existential D2
      '''
      testProof(text, true)
    it "verifies a tick  with exists D2", ->
      text = '''
        (exists x) Gx   tick SM
        Fa               SM
        Fb               SM
        | Ga                          1 exists D2
      
        | Gb                          1 exists D2
      
        | Gc                          1 exists D2
      '''
      testProof(text, true)
    it "verifies a tick with exists D2 (another case)", ->
      text = '''
        (exists x) Gx   tick SM
        Fa or Fb         SM
        | Fa          or D 2
        || Ga                          1 exists D2
        |
        || Gb                          1 exists D2
        |
        || Gc                          1 exists D2
      
        | Fb          or D 2
        || Ga                          1 exists D2
        |
        || Gb                          1 exists D2
        |
        || Gc                          1 exists D2
      
      '''
      testProof(text, true)
    it "verifies a tick with exists D2 even where different branches contain different names", ->
      # preliminary test:
      text = '''
        (exists x) Gx   SM
        Fa or Fa         SM
        (all x) Fx       SM
        | Fa          or D 2
        | Fb          all D 3
      
        | Fa          or D 2
        | Fd          all D 3
      '''
      testProof(text, true)
  
      text = '''
        (exists x) Gx   tick SM
        Fa or Fa         SM
        (all x) Fx       SM
        | Fa          or D 2
        | Fb          all D 3
        || Ga                          1 exists D2
        |
        || Gb                          1 exists D2
        |
        || Gc                          1 exists D2
      
        | Fa          or D 2
        | Fd          all D 3
        || Ga                          1 exists D2
        |
        || Gd                          1 exists D2
        |
        || Gc                          1 exists D2
      
      '''
      testProof(text, true)
      
  describe "exists D", ->
    it "verifies `exists D`", ->
      text = '''
        (exists x) Gx   SM
        Fa              SM
        Gb              exists D 1
      '''
      testProof(text, true)
    it "does not allow `exists D` with an old constant", ->
      text = '''
        (exists x) Gx   SM
        Fa              SM
        Ga              exists D 1
      '''
      testProof(text, false)
    it "only requires that the constant used with `exists D` not be on the branch", ->
      text = '''
        A or B          SM
        (exists x) Gx   SM
        (exists x) Fx   SM
        | A             or D 1
        | Ga            exists D 2
        
        | B             or D 1
        | Ga            exists D 2
      '''
      testProof(text, true)
  
  describe "various rules", ->
    it "verifies not not D", ->
      text = '''
        not not A     SM
        A             dn D 1
      '''
      testProof(text, true)
    it "verifies not not D tick", ->
      text = '''
        not not A     tick SM
        A             dn D 1
      '''
      testProof(text, true)
    it "verifies <->D", ->
      text = '''
        A<->B     SM
        |A             <-> D 1
        |B             <-> D 1
        
        |not A             <-> D 1
        |not B             <-> D 1
      '''
      testProof(text, true)
    it "spots a mistake with <->D", ->
      text = '''
        A<->B     SM
        A             <-> D 1
      '''
      testProof(text, false)
    it "spots another mistake with <->D", ->
      text = '''
        A<->B     SM
        B             <-> D 1
      '''
      testProof(text, false)
    it "verifies <->D tick", ->
      text = '''
        A<->B     tick SM
        |A             <-> D 1
        |B             <-> D 1
        
        |not A             <-> D 1
        |not B             <-> D 1
      '''
      testProof(text, true)      
    it "allows partial use of <->D ", ->
      text = '''
        A<->B         SM
        |A             <-> D 1
        |B             <-> D 1
        
        |not A             <-> D 1
      '''
      testProof(text, true)      
    it "spots a mistake with <->D tick", ->
      text = '''
        A<->B     tick SM
        |A             <-> D 1
        |B             <-> D 1
        
        |not A             <-> D 1
      '''
      testProof(text, false)      
    it "verifies not<->D", ->
      text = '''
        not (A<->B)     SM
        |A             ~<-> D 1
        |not B             not <-> D 1
        
        |not A             negated biconditional D 1
        |B             ~ <-> D 1
      '''
      testProof(text, true)
    it "verifies not<->D ticked", ->
      text = '''
        not (A<->B)     tick SM
        |A             ~<-> D 1
        |not B             not <-> D 1
        
        |not A             negated biconditional D 1
        |B             ~ <-> D 1
      '''
      testProof(text, true)
    
  describe "the simple not... rules", ->
    it "verifies ~&D", ->
      text = '''
        not (A & B)      SM
        |not A             ~& D 1
        
        |not B           ~ & D 1
      '''
      testProof(text, true)
    it "verifies ~&D ticked", ->
      text = '''
        not (A & B)     tick SM
        |not A             ~& D 1
        
        |not B           ~ & D 1
      '''
      testProof(text, true)
    it "verifies ~ or D ticked", ->
      text = '''
        not (A or B)     tick SM
        not A             ~ or D 1
        not B           ~ or D 1
      '''
      testProof(text, true)
    it "verifies ~ arrow D ticked", ->
      text = '''
        not (A arrow B)     tick SM
        A             ~ arrow D 1
        not B                 ~ arrow D 1
      '''
      testProof(text, true)
    it "verifies ~ all D ticked", ->
      text = '''
        not (all x) Fx     tick SM
        (exists x) not Fx    not all D 1
      '''
      testProof(text, true)
            
    it "verifies ~ exists D ticked", ->
      text = '''
        not (exists x) Fx     tick SM
        (all x) not Fx    not exists D 1
      '''
      testProof(text, true)
            
  describe "identity decomposition", ->
    it "verifies =D", ->
      text = '''
        Fa      SM
        a=b     SM
        Fb      = D 1,2 
      '''
      testProof(text, true)

  describe "longer proofs", ->
    # The incorrect line is the final closed branch thing (branch does not close!)
    it "verifies a longish incorrect proof", ->
      text = '''
        not (A<->B)   SM
        A or B        SM
        C and D       SM
        |A            ~<-> D 1
        |not B        not <-> D 1
        ||A         or D 2
        |
        || B        or D 2
  
        |not A             negated biconditional D 1
        |B             ~ <-> D 1
        | C     & D 3
        | D       & D 3
        ||A         or D 2
        |
        || B        or D 2
        || X
      '''
      testProof(text, false)
      

  describe "closing branches", ->
    it "verifies a closed tree with a branching rule", ->
      text = '''
        A arrow B   SM
        A           SM
        not B       SM
        | not A             arrow D 1
        | X
      
        | B     arrow D 1
        | X
      '''
      testProof(text, true)
    it "allows closing a with not a=a", ->
      text = '''
        A and not a=a
        A             and D 1
        not a=a       and D 1
        X
      '''
      testProof(text, true)
    it "verifies a simple tree (includes explicitly open branch)", ->
      text = '''
        A and not B
        A             and D 1
        not B         and D 1
        O
      '''
      testProof(text, true)
    it "does not allow closing a branch incorrectly", ->
      text = '''
        A and B
        A          and D 1
        B          and D 1
        X
      '''
      theProof = proof.parse text
      # console.log theProof.getLine(4).justification
      # console.log theProof.getLine(4).verify()
      # console.log theProof.getLine(4).getErrorMessage()
      testProof(text, false)
    it "does not allow more lines after closing a branch", ->
      text = '''
        A and not A
        A             and D 1
        not A         and D 1
        X
        A             and D 1
      '''
      testProof(text, false)
    it "does not allow a branch after closing a branch", ->
      text = '''
        A and not A   SM
        A arrow B     SM
        A             and D 1
        not A         and D 1
        X
        | not A             arrow D 2
      
        | B             arrow D 2
      '''
      testProof(text, false)

  describe "marking branches open", ->
    it "verifies an open tree with a branching rule", ->
      text = '''
        A arrow B   SM
        not B       SM
        | not A             arrow D 1
        | O
      
        | B     arrow D 1
        | X
      '''
      testProof(text, true)

    it "does not allow incorrectly marking a branch as open", ->
      text = '''
        A and not A
        A             and D 1
        not A         and D 1
        O
      '''
      testProof(text, false)
    it "does not allow incorrectly marking a branch as open (not a=a version)", ->
      text = '''
        A and not a=a
        A             and D 1
        A             and D 1
        not a=a       and D 1
        O
      '''
      testProof(text, false)

    it "the .canLineBeTicked function works (from `add_verification`)", ->
      p = proof.parse '''
        A and B       SM
        A             and D 1
        O
      '''
      # must verify before doing `.canLineBeTicked`
      # p.verifyTree()
      line = p.getLine(1)
      test = line.canLineBeTicked()
      test.should.be.false

    it "the .canLineBeTicked function works, correct case (from `add_verification`)", ->
      p = proof.parse '''
        A and B       SM
        A             and D 1
        B             and D 1
        O
      '''
      test = p.getLine(1).canLineBeTicked()
      test.should.be.true

    it "the .canLineBeTicked function works, not applicable case (a=b) (from `add_verification`)", ->
      p = proof.parse '''
        a=b       SM
        O
      '''
      test = p.getLine(1).canLineBeTicked()
      test.should.be.true

    it "the .canLineBeTicked function works for `not A`", ->
      p = proof.parse '''
        not A       SM
        O
      '''
      test = p.getLine(1).canLineBeTicked()
      test.should.be.true

    it "does not allow marking a branch as open if a conjunction has not been fully decomposed", ->
      text = '''
        A and B       SM
        A             and D 1
        O
      '''
      testProof(text, false)

    it "does allow marking a branch as open if a conjunction has been fully decomposed", ->
      text = '''
        A and B       SM
        A             and D 1
        B             and D 1
        O
      '''
      testProof(text, true)

    it "does not allow marking a branch as open if a disjunction has not been fully decomposed", ->
      text = '''
        A and B       SM
        C or D        SM
        A             and D 1
        B             and D 1
        O
      '''
      testProof(text, false)

    it "does allow marking a branch as open if a disjunction has been fully decomposed", ->
      text = '''
        A and B       SM
        C or D        SM
        A             and D 1
        B             and D 1
        | C       or D 2
        
        | D       or D 2
        | O
      '''
      testProof(text, true)

    it "does not allow marking a branch as open if a disjunction has not been fully decomposed", ->
      text = '''
        Fa                SM
        Fb                SM
        (exists x) Fx       SM
        O
      '''
      testProof(text, false)

    it "does  allow marking a branch as open if a disjunction has  been fully decomposed", ->
      text = '''
        Fa                SM
        Fb                SM
        (exists x) Fx       SM
        | Fa          exists D 2
        
        | Fb          exists D 2
        | O
        
        | Fc          exists D 2
        | O
      '''
      testProof(text, false)

    it "does not allow marking a branch as open if an identity statement has not been fully decomposed", ->
      text = '''
        Fa                SM
        Gb                SM
        a=b           SM
        Fb            = D 1,3
        O
      '''
      testProof(text, false)
    it "does not allow marking a branch as open if an identity statement has not been fully decomposed (further test)", ->
      text = '''
        a=b               SM
        Faa                SM
        Fbb                = D 1,2
        Fab                = D 1,2
        O
      '''
      testProof(text, false)
    it "does allow marking a branch as open if an identity statement has  been fully decomposed", ->
      text = '''
        Fa                SM
        Gb                SM
        a=b               SM
        Fb                = D 1,3
        Ga                = D 2,3
        a=a               = D 3,3
        b=b               = D 3,3
        O
      '''
      testProof(text, true)
    it "does allow marking a branch as open if an identity statement has  been fully decomposed even without requiring sentences like a=a", ->
      text = '''
        Fa                SM
        Gb                SM
        a=b               SM
        Fb                = D 1,3
        Ga                = D 2,3
        O
      '''
      testProof(text, true)
    it "does allow marking a branch as open if an identity statement has  been fully decomposed, further test", ->
      text = '''
        a=b               SM
        Faa                SM
        Fbb                = D 1,2
        Fab                = D 1,2
        Fba                = D 1,2
        O
      '''
      testProof(text, true)

  describe "misc problems", ->
    it "spots a mistake with not not D tick", ->
      text = '''
        not not A     tick SM
        not not B     tick SM
        A             dn D 1
      '''
      testProof(text, false)
    it "the .canLineBeTicked function works with not not D tick (from `add_verification`)", ->
      p = proof.parse '''
        not not A     SM
      '''
      line = p.getLine(1)
      test = line.canLineBeTicked()
      test.should.be.false
    it "the .canLineBeTicked function works with not not D tick, harder case (from `add_verification`)", ->
      p = proof.parse '''
        not not A     tick SM
        not not B     tick SM
        A             dn D 1
      '''
      line = p.getLine(2)
      test = line.canLineBeTicked()
      test.should.be.false

    it "marking branches open with -> D works", ->
      text = '''
          | A arrow B        SM
        2 || not A        arrow D 1
        3 || O
          | 
        2 || B        arrow D 1
        3 || O
      '''
      testProof(text, true)
    
    it "marking branches open with `and D` works (nested case, complete tree)", ->
      text = '''
        1 | A arrow B
        2 | C and B        SM
        3 || not A   -> D  1
        4 || C   and D 2
        5 || B   and D 2
        6 || O
          | 
        3 || B    -> D 1
        4 || C   and D 2
        5 || B   and D 2
        6 || O
      '''
      testProof(text, true)
    
    it "marking branches open with `and D` works (nested case, incomplete tree)", ->
      text = '''
        1 | A arrow B
        2 | C and B        SM
        3 || not A   -> D  1
        4 || C   and D 2
        5 || B   and D 2
        6 || O
          | 
        3 || B    -> D 1
      '''
      testProof(text, true)
    
    it "marking branches open with `-> D` works (nested case, complete tree)", ->
      text = '''
        1 | A → B    ✓ SM
        2 | C → D    tick SM
        3 || ¬A     →D 1
        4 ||| ¬C      →D 2
        5 ||| O
          || 
        4 ||| D      →D 2
        5 ||| O
          || 
          | 
        3 || B     →D 1
        4 ||| ¬C      →D 2
        5 ||| O
          || 
        4 ||| D      →D 2
        5 ||| O
      '''
      testProof(text, true)
    
    it "marking branches open with `-> D` works (nested case, not complete tree)", ->
      text = '''
        1 | A → B    SM
        2 | C → D    SM
        3 || ¬A     →D 1
        5 ||| ¬C      →D 2
        6 ||| O
          || 
        5 ||| D      →D 2
        6 ||| O
          || 
          | 
        3 || B     →D 1
      '''
      testProof(text, true)
      
    it "verifies a tree that it should verify", ->
      text = '''
        1 | A ∨ B     SM
        2 | A → ¬B    SM
        3 | B → ¬A    SM
        4 || A     ∨D 1
        5 ||| ¬A      →D 2
        6 ||| X
          || 
        5 ||| ¬B      →D 2
        7 |||| ¬B       →D 3
        8 |||| O
          ||| 
        7 |||| ¬A       →D 3
        8 |||| X
          ||| 
          || 
          | 
        4 || B     ∨D 1
        5 ||| ¬B      →D 3
        6 ||| X
          || 
        5 ||| ¬A      →D 3
        7 |||| ¬A       →D 2
          ||| 
        7 |||| ¬B       →D 2
        8 |||| X
      '''
      testProof(text, true)
    
    it "recognizes as open a branch that is open", ->
      text = '''
        1 | A ∧ B    SM
        2 | C → D    SM
        3 | C        SM
        4 || ¬C     →D 2
        5 || X
          | 
        4 || D     →D 2
        5 || A      ∧D 1
        6 || B      ∧D 1
        7 || O
      '''
      testProof(text, true)
      
    it "copes with full decomposition split between branches", ->
      text = '''
        A and B       SM tick
        C or D        SM
        A      and D 1
        | C           or D 2
        | B      and D 1
        | O
    
        | D           or D 2
        | B      and D 1
        | O
      '''
      testProof(text, true)

    it "spots an error involving incomplete decomposition split between branches", ->
      text = '''
        A and B       SM tick
        C or D        SM
        A      and D 1
        | C           or D 2
        | B      and D 1
        | O
    
        | D           or D 2
        | O
      '''
      testProof(text, false)
    it "spots another error involving incomplete decomposition split between branches", ->
      text = '''
        A and B       SM tick
        C or D        SM
        A      and D 1
        | C           or D 2
        | B      and D 1
        | O
    
        | D           or D 2
        | A      and D 1
        | O
      '''
      testProof(text, false)
    
    it "can spot an error in an incomplete proof (branching rule not fully written)", ->
      text = '''
        1 | A ∨ B    Premise
        2 | ¬B       Premise
        3 | ¬A       Premise
        4 || A     ∨D 1
        5 || X
          | 
        4 || 
      '''
      testProof(text, false)

    it "can identify a mistake in not fully decompsing all D (not decomposed at all)", ->
      text = '''
        1 | (∀x) Fx    SM
        2 | (∃x) ¬Gx    SM
        3 || not Ga   exists D2 2
        4 || O
      '''
      testProof(text, false)
    it "can identify a mistake in not fully decompsing all D (no decomposition)", ->
      text = '''
        1 | (∀x) Fx    SM
        5 | O
      '''
      testProof(text, false)
    it "can confirm fully decompsing all D (simple case)", ->
      text = '''
        1 | (∀x) Fx    SM
        2 | Fa      all D 1
        5 | O
      '''
      testProof(text, true)
    it "can confirm fully decompsing all D (old constants used only)", ->
      text = '''
        1 | (∀x) Fx    SM
        2 | (∃x) ¬Gx    SM
        3 || not Ga   exists D2 2
        4 || Fa       all D 1
        5 || O
      '''
      testProof(text, true)
    it "can identify a mistake in not fully decompsing all D (only new constant decomposed)", ->
      text = '''
        1 | (∀x) Fx    SM
        2 | (∃x) ¬Gx    SM
        3 || not Ga   exists D2 2
        4 || Fb       all D 1
        5 || O
      '''
      testProof(text, false)
    it "can verify proof involving fully decompsing all D", ->
      text = '''
        1 | (∀x) Fx    SM
        2 | (∃x) ¬Gx    SM
        3 || not Ga   exists D2 2
        4 || Fa       all D 1
        5 || Fb       all D 1
        6 || O
      '''
      testProof(text, true)
    it "can identify a mistake in not fully decompsing all D  with an identity statement", ->
      text = '''
        1 | (∀x) Fx    SM
        2 | a=b         SM
        3 | Fa       all D 1
        5 | Fc       all D 1
        6 | O
      '''
      testProof(text, false)
    it "can verify proof involving fully decompsing all D with an identity statement", ->
      text = '''
        1 | (∀x) Fx    SM
        2 | a=b         SM
        3 | Fa       all D 1
        4 | Fb       all D 1
        5 | Fc       all D 1
        6 | O
      '''
      testProof(text, true)
    it "can verify a simple open proof", ->
      text = '''
        1 | A → B    Premise
        2 | ¬A       Premise
        3 || ¬A     ∨D 1
        4 || O
          | 
        3 || B     ∨D 1
        4 || O
      '''
      testProof(text, false)

    it "can verify an open proof with a single universal quantifier premise", ->
      text = '''
        1 | (∀x)(Fx ⊃ Gx)    Assumption
        2 | Ga               Assumption
        3 | ~~Fa             Assumption
        4 | Fa ⊃ Ga          ∀D 1
        5 || ~Fa     ⊃D 4
        6 || X
          | 
        5 || Ga          ⊃D 4
        6 || Fa          ~ ~ D 3
        7 || Fb ⊃ Gb     ∀D 1
        8 ||| ~Fb      ⊃D 7
        9 ||| O
          || 
        8 ||| Gb      ⊃D 7
        9 ||| O
      '''
      testProof(text, true)
      