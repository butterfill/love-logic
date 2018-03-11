chai = require 'chai' 
expect = chai.expect
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
  dialectManager.set('forallx')
   
testProof = (proofText, expected) ->
  theProof = proof.parse proofText
  console.log theProof if _.isString(theProof)
  newPrfTxt = theProof.toString({numberLines:true})
  console.log newPrfTxt
  theProof = proof.parse newPrfTxt
  result = theProof.verify()
  if expected
    if result isnt expected
      console.log theProof.listErrorMessages()
    expect(result).to.be.true
  else
    expect(result).to.be.false
  
describe "forallx_rules", ->
  
  before () ->
    pushRulesAndParser()
    setRulesAndParser()
  after () ->
    popRulesAndParser()
    
  
  it "verifies a simple proof", ->
    text = '''
      | A                   premise
      |---
      | B or A						or I 1
    '''
    testProof(text, true)
  
  it "verifies a universal intro proof", ->
    text = '''
      | 
      |---
      | a=a         = intro
      | all x x=x   all intro 3
    '''
    testProof(text, true)
  
  it "spots a universal intro error", ->
    text = '''
      | Fa
      |---
      | all x Fx   all intro 1
    '''
    testProof(text, false)
  
  it "spots another universal intro error", ->
    text = '''
      | all x Fax
      |---
      | Faa        all elim  1
      | all x Fxx   all intro 3
    '''
    testProof(text, false)

  it "verifies an exists elim proof", ->
    text = '''
      | exists x Fx
      | all x (Fx -> Gx)
      |---
      || Fa
      ||---
      || Fa arrow Ga    all elim 2
      || Ga             arrow elim 4,6
      || exists x Gx    exists intro 7
      | exists x Gx     exists elim 1, 4-8
    '''
    testProof(text, true)
  
  it "spots an exists elim error", ->
    text = '''
      | exists x Fx
      | Ga
      |---
      || Fa
      ||---
      || Fa             r 4
      || Ga             r 2
      || exists x Gx    exists intro 7
      | exists x Gx     exists elim 1, 4-8
    '''
    testProof(text, false)

  it "verifies a simple modus-tollens proof", ->
    text = '''
      | A arrow B
      | not B
      |---
      | not A						MT 1,2 
    '''
    testProof(text, true)

  it "verifies a simple dilemma proof", ->
    text = '''
      | A arrow C                   
      | B arrow C
      | A or B
      |---
      | C						DIL 1,2,3 
    '''
    testProof(text, true)

  it "verifies a simple hypothetical-syllogism proof", ->
    text = '''
      | A arrow B                   
      | B arrow C
      |---
      | A arrow C						hypothetical syllogism 1,2 
    '''
    testProof(text, true)

  
  # ---
  # rules of replacement
  
  it "supports rules of replacement (simplest case)", ->
    text = '''
      | A and B      premise
      |---
      | B and A						comm 1
    '''
    testProof(text, true)
  it "supports rules of replacement (one of one subformula)", ->
    text = '''
      | (A and B) or C
      |---
      | (B and A) or C						comm 1
    '''
    testProof(text, true)
  it "supports rules of replacement (all of two subformulae)", ->
    text = '''
      | (A and B) or (C and D)
      |---
      | (B and A) or (D and C)						comm 1
    '''
    testProof(text, true)
  it "supports rules of replacement (one of two subformulae)", ->
    text = '''
      | (A and B) or (C and D)
      |---
      | (B and A) or (C and D)						comm 1
    '''
    testProof(text, true)
  it "supports rules of replacement (all of two subformulae, other side)", ->
    text = '''
      | (A and B) or (C and D)
      |---
      | (A and B) or (D and C)						comm 1
    '''
    testProof(text, true)
  it "supports rules of replacement (both of two nested instances)", ->
    text = '''
      | (A and B) and C
      |---
      | C and (B and A)						comm 1
    '''
    testProof(text, true)
  it "supports rules of replacement (outer only of two nested instances)", ->
    text = '''
      | (A and B) and C
      |---
      | C and (A and B)						comm 1
    '''
    testProof(text, true)
  it "supports rules of replacement (inner only of two nested instances)", ->
    text = '''
      | (A and B) and C
      |---
      | (B and A) and C						comm 1
    '''
    testProof(text, true)
  it "identifies an error using rules of replacement (connective swapped)", ->
    text = '''
      | (A and B) and C
      |---
      | (B or A) and C						comm 1
    '''
    testProof(text, false)
  it "identifies an error using rules of replacement (another connective swapped)", ->
    text = '''
      | (A and B) and C
      |---
      | (B and A) or C						comm 1
    '''
    testProof(text, false)
  it "allows rules of replacement inside quantifiers", ->
    text = '''
      | all x (Fx and Gx) and C
      |---
      | all x (Gx and Fx) and C						comm 1
    '''
    testProof(text, true)
  it "identifies an error using rules of replacement (quantifier variable swapped)", ->
    text = '''
      | all x (Fx and Gx) and C
      |---
      | all y (Gx and Fx) and C						comm 1
    '''
    testProof(text, false)
  it "supports double-negation of replacement, simple", ->
    text = '''
      | ~~A
      |---
      | A						DN 1
    '''
    testProof(text, true)

  it "supports double-negation of replacement, subformula", ->
    text = '''
      | ~~A and B
      |---
      | A and B						double negation 1
    '''
    testProof(text, true)
  it "supports double-negation of replacement, one of two subformulae", ->
    text = '''
      | ~~A and ~~B
      |---
      | A and ~~B						double negation 1
    '''
    testProof(text, true)
  it "supports double-negation of replacement, two of two subformulae", ->
    text = '''
      | ~~A and ~~B
      |---
      | A and B						double negation 1
    '''
    testProof(text, true)
  it "verifies a quantification-replacement proof", ->
    text = '''
      | (not all x Fx) and (not all x Gx)
      |---
      | (exists x not Fx)  and (not all x Gx)     qn 1
    '''
    testProof(text, true)
  it "spots a mistake in a quantification-replacement rule application", ->
    text = '''
      | (not all x Fx) and (not all x Gx)
      |---
      | (all x not Fx)  and (not all x Gx)     qn 1
    '''
    testProof(text, false)
