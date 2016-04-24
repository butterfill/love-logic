dialectManager = require('../dialect_manager/dialectManager')

_ = require('lodash')

rule = require './rule'
rule.setParser( dialectManager.getParser('awFOL') )
rules = 
  _description : '''
    Rules of proof for tree proofs as presented in Bergman et al, ‘The Logic Book’ (2014).  
  '''
  
  premise : rule.from().to( rule.premise() )
  
  'close-branch' : rule.from().to( rule.closeBranch() )
  'open-branch' : rule.from().to( rule.openBranch() )
  
  'and' : 
    decomposition : [
      rule.from('φ and ψ').to( rule.matches('φ').and.doesntBranch() )
      rule.from('φ and ψ').to( rule.matches('ψ').and.doesntBranch() )
    ]
  
  arrow : 
    decomposition : [
      rule.from('φ arrow ψ').to( rule.matches('not φ').and.branches() )
      rule.from('φ arrow ψ').to( rule.matches('ψ').and.branches() )
    ]
  
  
  universal :
    decomposition : rule.from('all τ φ').to( rule.matches('φ[τ-->α]').and.doesntBranch() ) 
    #.tickIfUsedWithAllConstantsAndAtLeastOneConstant()
  
  existential :
    decomposition2 : rule.from('exists τ φ').to( rule.matches('φ[τ-->α]').and.branches() )
    #.tickIfUsedWithAllConstantsAndANewConstant()
  

rules.tickCheckers = 
  'and' : rule#.tickIfAllRulesAppliedInEveryBranch( rules.and.decomposition )
  'arrow' : rule#.tickIfAny



# Add the `.ruleSet` property to each rule.
# This makes it easy to see which rules must all be 
# applied in order to tick a line of the tree proof.
_decorateRulesForTrees = (rules) ->
  for key of rules
    if rules[key].type is 'rule'
      rule = rules[key]
      rule.ruleSet ?= [rule] 
      continue
    if _.isArray(rules[key])
      listOfRules = rules[key]
      for rule in listOfRules
        rule.ruleSet = listOfRules
    if _.isObject(rules[key])
      _decorateRulesForTrees(rules[key])

_decorateRulesForTrees( rules )

exports.rules = rules
dialectManager.registerRuleSet('logicbook_tree', rules)