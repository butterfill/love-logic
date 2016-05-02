chai = require 'chai' 
expect = chai.expect
should = chai.should()
_ = require 'lodash'

tree = require('../tree')
fol = require('../../../love-logic_new_project/fol')
proof = require('../../../love-logic_new_project/proofs/proof')
dialectManager = require('../../../love-logic_new_project/dialect_manager/dialectManager')

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


testTreeProof = tree.makeTreeProof("""
    not (A<->B)   SM
    A or B        SM
    C and D       SM
  """)
leftChild = testTreeProof.addChild("""
      A     ~ ≡ D 1
      ~B    ~ ≡ D 1
      """)
rightChild = leftChild.addSib("""
        ~A    ~ ≡ D 1
        B     ~ ≡ D 1
        C     &D 3
        D     &D 3
      """)
leftChild.addChild("A     ∨D 2").addSib("B     ∨D 2")
rightChild.addChild('A    or D 2').addSib("B   or D 2")

   
describe "tree ui component", ->
  
  before () ->
    pushRulesAndParser()
    setRulesAndParser()
  after () ->
    popRulesAndParser()
    
  describe "basics", ->
    it "the test tree can be verified", ->
      testTreeProof.verify().isCorrect.should.be.true
      
    it ".toSequent creates proof text that can be parsed", ->
      prf3 = proof.parse(testTreeProof.toSequent(), {treeProof:true})
      # console.log prf3.toString()
      prf3.verifyTree().should.be.true
      # console.log prf3.listErrorMessages()

    it ".convertToSymbols doesn’t throw", ->
      newTree =  testTreeProof.convertToSymbols()

    it ".convertToSymbols ", ->
      newTree =  testTreeProof.convertToSymbols()
      console.log newTree.toSequent()
      console.log newTree.verify().errorMessages
      newTree.verify().isCorrect.should.be.true
      
    
    