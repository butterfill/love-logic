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
  dialectManager.set('logicbook')
  dialectManager.setCurrentRules('logicbook_tree')
   
testProof = (proofText, expected) ->
  theProof = proof.parse proofText
  console.log theProof if _.isString(theProof)
  newPrfTxt = theProof.toString({numberLines:true})
  console.log newPrfTxt
  theProof = proof.parse newPrfTxt
  result = theProof.verifyTree()
  if expected
    if result isnt expected
      console.log theProof.listErrorMessages()
    expect(result).to.be.true
  else
    expect(result).to.be.false
  
describe "logicbook tree rules", ->
  
  before () ->
    pushRulesAndParser()
    setRulesAndParser()
  after () ->
    popRulesAndParser()
    
  it "verifies a simple tree (includes explicitly closed branch)", ->
    text = '''
      A and not A
      A             and D 1
      not A         and D 1
      X
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

  it "verifies a tree with a branching rule", ->
    text = '''
      A arrow B     SM
      | not A       arrow D 1
      
      | B     arrow D 1
    '''
    testProof(text, true)
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
  it "does not allow a branching rule to be used without branching", ->
    text = '''
      A arrow B
      not A             arrow D 1
      B                 arrow D 1
    '''
    testProof(text, false)
  it "does not allow a branching rule to be used with making the right number of branches", ->
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
    
  it "verifies a tree proof with exists D2", ->
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
  