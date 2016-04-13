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
setTellerRulesAndParser = () ->
  dialectManager.set('teller')
   
testProof = (proofText, expected) ->
  pushRulesAndParser()
  setTellerRulesAndParser()
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
  popRulesAndParser()
  
describe "teller_rules", ->
  it "verifies a simple proof with teller_rules", ->
    text = '''
      | A                   premise
      |---
      | B arrow A						weakening 1
    '''
    testProof(text, true)
  
  it "verifies a universal intro proof with teller_rules", ->
    text = '''
      | 
      |---
      | a^=a^         = intro
      | (all x) x=x   all intro 3
    '''
    testProof(text, true)
  
  it "spots a universal intro error (no hat) with teller_rules", ->
    text = '''
      | 
      |---
      | a=a         = intro
      | (all x) x=x   all intro 3
    '''
    testProof(text, false)
  
  it "verifies a universal elim hat proof with teller_rules", ->
    text = '''
      | (all x) (Fx and Gx)
      |---
      | Fa^ and Ga^   all elim 1
      | Fa^           and elim 3
      | (all x) Fx    all intro 4
    '''
    testProof(text, true)

  it "verifies or elim left, 1st variant", ->
    text = '''
      | A or B
      | not A
      |---
      | B       or E 1,2
    '''
    testProof(text, true)
  it "verifies or elim right, 1st variant", ->
    text = '''
      | A or B
      | not B
      |---
      | A       or E 1,2
    '''
    testProof(text, true)
  it "verifies or elim left, 2nd variant", ->
    text = '''
      | not A or B
      | A
      |---
      | B       or E 1,2
    '''
    testProof(text, true)
  it "verifies or elim right, 2nd variant", ->
    text = '''
      | A or not B
      | B
      |---
      | A       or E 1,2
    '''
    testProof(text, true)

  it "verifies not intro, 1st variant", ->
    text = '''
      | 
      |---
      || A and not A       
      ||---
      || A              and E 3
      || not A          and E 3
      || A and not A    and I 5,6
      | not (A and not A)   not I 3-7
    '''
    testProof(text, true)
  it "verifies not intro, 2nd variant", ->
    text = '''
      | 
      |---
      || A and not A       
      ||---
      || A              and E 3
      || not A          and E 3
      | not (A and not A)   not I 3-6
    '''
    testProof(text, true)
  it "verifies not intro, 2nd variant, tricky-a", ->
    text = '''
      | not not B
      | not B
      |---
      || A
      ||---
      || not not B      reit 1
      || not B          reit 2
      | not A           not I 4-7
    '''
    testProof(text, true)
  it "verifies not intro, 2nd variant, tricky-b", ->
    text = '''
      | not not B
      | not B
      |---
      || A
      ||---
      || not B          reit 2
      || not not B      reit 1
      | not A           not I 4-7
    '''
    testProof(text, true)
  it "does not allow incorrect use of not intro, 2nd variant", ->
    text = '''
      | not B
      |---
      || A and not A       
      ||---
      || A              and E 3
      || not B          reit 1
      | not (A and not A)   not I 3-6
    '''
    testProof(text, false)
  it "does not allow incorrect use of not intro, 2nd variant, tricky case", ->
    text = '''
      | 
      |---
      || A 
      ||---
      ||| B              
      |||---
      ||| B             reit 5
      ||
      ||| not B
      |||---
      ||| not B         reit 9
      | not A   not I 3-6
    '''
    testProof(text, false)

  it "verifies double_arrow elim, 1st variant", ->
    text = '''
      | A <-> B
      |---
      | A -> B      <-> elim 1
    '''
    testProof(text, true)
  it "verifies double_arrow intro", ->
    text = '''
      | A -> B
      | B -> A
      |---
      | A <-> B      <-> intro 1,2
    '''
    testProof(text, true)
        
  it "verifies cases, 1st variant", ->
    text = '''
      | B or A
      | A -> C
      | B -> C
      |---
      | C      AC 1,2,3
    '''
    testProof(text, true)
    
  it "verifies cases, 2nd variant", ->
    text = '''
      | A or B
      | C
      |---
      || A
      ||---
      || C      reit 2
      |
      || B
      ||---
      || C     reit 2
      |
      | C      AC 1,4-6,8-10
    '''
    testProof(text, true)
  it "verifies cases, 1st variant", ->
    text = '''
      | B or A
      | A -> C
      | B -> C
      |---
      | C      AC 1,2,3
    '''
    testProof(text, true)
        
  it "verifies DC, 1st variant", ->
    text = '''
      | A arrow B
      | not B
      |---
      | not A      DC 1,2
    '''
    testProof(text, true)
  it "verifies DC, 2nd variant", ->
    text = '''
      | A arrow not B
      | B
      |---
      | not A      DC 1,2
    '''
    testProof(text, true)
  it "verifies DC, 3rd variant", ->
    text = '''
      | not A arrow B
      | not B
      |---
      | A      DC 1,2
    '''
    testProof(text, true)

  it "verifies reductio, 1st variant", ->
    text = '''
      | B
      | not B
      |---
      || not A      
      ||---
      || B          reit 1
      || not B      reit 2
      | A           reductio 4-7
    '''
    testProof(text, true)

  it "verifies reductio, 2nd variant", ->
    text = '''
      | B
      | not B
      |---
      || not A      
      ||---
      || B          reit 1
      || not B      reit 2
      || B and not B    and intro 6,7
      | A           reductio 4-8
    '''
    testProof(text, true)

  it "verifies DM, 1st variant", ->
    text = '''
      | not (A or B)
      |---
      | not A and not B      deMorgan 1
    '''
    testProof(text, true)
  it "verifies DM, 2nd variant", ->
    text = '''
      | not A and not B
      |---
      | not (A or B)      de morgan 1
    '''
    testProof(text, true)
  it "verifies DM, 3rd variant", ->
    text = '''
      | not (A and B)
      |---
      | not A or not B      DM 1
    '''
    testProof(text, true)
  it "verifies DM, 4th variant", ->
    text = '''
      | not A or not B
      |---
      | not (A and B)      de morgan 1
    '''
    testProof(text, true)

# TODO:
#
# contraposition : [
#   rule.from('φ arrow ψ').to('not ψ arrow not φ')
#   rule.from('not ψ arrow not φ').to('φ arrow ψ')
#   rule.from('not φ arrow ψ').to('not ψ arrow φ')
#   rule.from('not ψ arrow φ').to('not φ arrow ψ')
#   rule.from('φ arrow not ψ').to('ψ arrow not φ')
#   rule.from('ψ arrow not φ').to('φ arrow not ψ')
# ]
# C : [
#   rule.from('φ arrow ψ').to('not φ or ψ')
#   rule.from('not φ or ψ').to('φ arrow ψ')
#   rule.from('not (φ arrow ψ)').to('φ and not ψ')
#   rule.from('φ and not ψ').to('not (φ arrow ψ)')
# ]
# CD : rule.from('φ').and('not φ').to('ψ')

  it "verifies not-all", ->
    text = '''
      | not (all x) Fx
      |---
      | (exists x) not Fx     not all 1
    '''
    testProof(text, true)
  it "verifies all-not", ->
    text = '''
      |  (all x) not Fx
      |---
      | not (exists x)  Fx      all not 1
    '''
    testProof(text, true)
  it "verifies not-exists", ->
    text = '''
      | not (exists x) Fx
      |---
      | (all x) not Fx     not exists 1
    '''
    testProof(text, true)
  it "verifies exists-not", ->
    text = '''
      |  (exists x) not Fx
      |---
      | not (all x)  Fx      exists not 1
    '''
    testProof(text, true)
