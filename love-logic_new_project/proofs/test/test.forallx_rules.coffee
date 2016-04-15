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
  


