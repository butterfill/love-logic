dialectManager = require('../dialect_manager/dialectManager')

_ = require('lodash')

rule = require './rule'
rule.setParser( dialectManager.getParser('awFOL') )
# keys are the names of rules defined in the `justification_parser.l` lexer:
rules = 
  _description : '''
    Rules of proof for tree proofs as presented in Bergman et al, ‘The Logic Book’ (2014).  
  '''
  
  premise : rule.from().to( rule.premise() )
  
  'close-branch' : rule.from().to( rule.closeBranch() )
  'open-branch' : rule.from().to( rule.openBranch() )
  
  'double-negation' : 
    decomposition : rule.from('not not φ').to( rule.matches('φ').and.doesntBranch() )
  
  'and' : 
    decomposition : [
      rule.from('φ and ψ').to( rule.matches('φ').and.doesntBranch() )
      rule.from('φ and ψ').to( rule.matches('ψ').and.doesntBranch() )
    ]
  
  'or' : 
    decomposition : [
      rule.from('φ or ψ').to( rule.matches('φ').and.branches() )
      rule.from('φ or ψ').to( rule.matches('ψ').and.branches() )
    ]
    
  arrow : 
    decomposition : [
      rule.from('φ arrow ψ').to( rule.matches('not φ').and.branches() )
      rule.from('φ arrow ψ').to( rule.matches('ψ').and.branches() )
    ]
  
  double_arrow :
    decomposition : [
      # NB: order matters for the tick checkers!
      rule.from('φ <-> ψ').to( rule.matches('φ').and.branches() )
      rule.from('φ <-> ψ').to( rule.matches('ψ').and.doesntBranch() ).where( rule.previousLineMatches('φ') ).andAlso.where( rule.previousLineCitesSameLines() )
      rule.from('φ <-> ψ').to( rule.matches('not φ').and.branches() )
      rule.from('φ <-> ψ').to( rule.matches('not ψ').and.doesntBranch() ).where( rule.previousLineMatches('not φ') ).andAlso.where( rule.previousLineCitesSameLines() )
    ]
  
  
  
  not_double_arrow :
    decomposition : [
      # NB: order matters for the tick checkers!
      rule.from('not (φ <-> ψ)').to( rule.matches('φ').and.branches() )
      rule.from('not (φ <-> ψ)').to( rule.matches('not ψ').and.doesntBranch() ).where( rule.previousLineMatches('φ') ).andAlso.where( rule.previousLineCitesSameLines() )
      rule.from('not (φ <-> ψ)').to( rule.matches('not φ').and.branches() )
      rule.from('not (φ <-> ψ)').to( rule.matches('ψ').and.doesntBranch() ).where( rule.previousLineMatches('not φ') ).andAlso.where( rule.previousLineCitesSameLines() )
    ]
  
  universal :
    decomposition : rule.from('all τ φ').to( rule.matches('φ[τ-->α]').and.doesntBranch() ) 
  
  existential :
    decomposition2 : rule.from('exists τ φ').to( rule.matches('φ[τ-->α]').and.branches() ).where( rule.ruleIsAppliedToEveryExistingConstantAndANewConstant('α') )
  
  identity : 
    decomposition : rule.from('α=β').and('φ').to( rule.matches('φ[α-->β]').and.doesntBranch() )
  
# Keys are awFOL `.type` properties (unlike the keys of `rules` which
# are the names of rules defined in the `justification_parser.l` lexer).
rules.tickCheckers = 
  'and' : rule.tickIf.allRulesAppliedInEveryBranch( rules.and.decomposition )
  'or' : rule.tickIf.someRuleAppliedInEveryBranch( rules.or.decomposition )
  arrow : rule.tickIf.someRuleAppliedInEveryBranch( rules.arrow.decomposition )
  double_arrow : rule.tickIf.someRuleAppliedInEveryBranch( [rules.double_arrow.decomposition[1], rules.double_arrow.decomposition[3]] )
  # universal_quantifier : rule.tickIf.ruleAppliedToEveryExistingConstant
  existential_quantifier : rule.tickIf.someRuleAppliedInEveryBranch( [rules.existential.decomposition2] )
  # identity : rule.tickIf.ruleAppliedToEverySentenceInEveryBranch( rule.identity.decomposition )
  'not' :
    'not' : rule.tickIf.allRulesAppliedInEveryBranch( [rules['double-negation'].decomposition] )
    double_arrow : rule.tickIf.someRuleAppliedInEveryBranch( [rules.not_double_arrow.decomposition[1], rules.not_double_arrow.decomposition[3]] )
  

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