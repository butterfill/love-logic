global._ = require 'lodash'


tree = require('../tree')
fol = require('../../../love-logic_new_project/fol')
global.fol = fol
proof = require('../../../love-logic_new_project/proofs/proof')
global.proof = proof
dialectManager = require('../../../love-logic_new_project/dialect_manager/dialectManager')
global.tree = tree

dialectManager.set('logicbook')
dialectManager.setCurrentRules('logicbook_tree')

# TODO
# 1. relax requirement on line numbers for tree proofs (must only be unique 
# within a branch)
# 2. .verify includes `.isClosed`, `.isOpen`, and `.isComplete`



# testTreeProof = {
#   proofText : """
#     not (A<->B)   SM
#     A or B        SM
#     C and D       SM
#   """
#   children : [
#     {
#       proofText : """
#       A     ~ ≡ D 1
#       ~B    ~ ≡ D 1
#       """
#       children : [
#         {
#           proofText : """
#             A     ∨D 2
#           """
#           children : []
#         }
#         {
#           proofText : """
#              B     ∨D 2
#           """
#           children : []
#         }
#       ]
#     }
#     {
#       proofText : """
#         ~A    ~ ≡ D 1
#         B     ~ ≡ D 1
#         C     &D 3
#         D     &D 3
#       """
#       children : []
#     }
#   ]}

global.testTreeProof = tree.makeTreeProof("""
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
#console.log testTreeProof
#console.log testTreeProof.toSequent()
prf3 = proof.parse(testTreeProof.toSequent())
# console.log prf3.toString()
# console.log prf3.verifyTree()
# console.log prf3.listErrorMessages()

global.treeTxt = """1 | Fa or Ga   SM
2 | a=b     SM
3 | not Fb    SM
4 || Fa    1 or D
5 || not Fa   2,3 = D
6 || X
  | 
4 || Ga     1 or D
5 || not Fa    2,3 =D
6 || a=a       2,2 =D
  |"""
global.testTreeProof2 = tree.convertProofToTreeProof( proof.parse(treeTxt, {treeProof:true}) )
global.treeEditable2 = testTreeProof2.displayEditable( '#displayEditable2')

newTree =  testTreeProof.convertToSymbols()
global.treeStatic2 = newTree.displayStatic( '#displayStatic2')

txt2 =  '''
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
# prf2 = proof.parse txt2
# check = prf2.verifyTree()
#console.log prf2.toString()
# $('#message').text("prf2.verifyTree() yielded #{prf2.verifyTree()}; error messages: #{prf2.listErrorMessages()}")
# global.prf2 = prf2


