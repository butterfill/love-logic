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
  dialectManager.set('lpl')
   
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
  
describe "fitch_rules", ->
  
  before () ->
    pushRulesAndParser()
    setRulesAndParser()
  after () ->
    popRulesAndParser()
    
  

  it "spots a mistake in universal intro", ->
    text = '''
      |          
      |---       
      || [a]     Premise 
      ||---      
      || a=a     = Intro 
      | ∀x x=a   ∀ Intro 3-5
    '''
    testProof(text, false)
  it "allows a correct universal intro proof", ->
    text = '''
      |          
      |---       
      || [a]     Premise 
      ||---      
      || a=a     = Intro 
      | ∀x x=x   ∀ Intro 3-5
    '''
    testProof(text, true)


  it "spots a mistake in conditional universal intro", ->
    text = '''
      |                  
      |---               
      || [a]F(a)         Premise 
      ||---              
      || a=a             = Intro 
      | ∀x(F(x) → a=x)   ∀ Intro 3-5
    '''
    testProof(text, false)
  it "allows a correct conditional universal intro", ->
    text = '''
      |                  
      |---               
      || [a]F(a)         Premise 
      ||---              
      || a=a             = Intro 
      | ∀x(F(x) → x=x)   ∀ Intro 3-5
    '''
    testProof(text, true)


  it "does not allow an incorrect proof with variables", ->
    text = '''
      |            
      |---         
      || [y]       Premise 
      ||---        
      ||| [y]      Premise 
      |||---       
      ||| y=y      = Intro 
      || ∀x x=y    ∀ Intro 5-7
      | ∀y∀x x=y   ∀ Intro 3-8
    '''
    testProof(text, false)
  