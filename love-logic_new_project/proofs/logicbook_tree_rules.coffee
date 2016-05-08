dialectManager = require('../dialect_manager/dialectManager')

_ = require('lodash')

rule = require './rule'
rule.setParser( dialectManager.getParser('awFOL') )
# keys are the names of rules defined in the `justification_parser.l` lexer:
rules = 
  _description : '''
    Rules of proof for tree proofs as presented in Bergman et al, ‘The Logic Book’ (2014).  
  '''
  
  premise : rule.from().to( rule.premiseInTreeProof() )
  
  'close-branch' : rule.from().to( rule.closeBranch() )
  
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
  
  not_and :
    decomposition : [
      rule.from('not (φ and ψ)').to( rule.matches('not φ').and.branches() )
      rule.from('not (φ and ψ)').to( rule.matches('not ψ').and.branches() )
      rule.from('φ').to( rule.matches('ψ') )
    ]  
  
  not_or :
    decomposition : [
      rule.from('not (φ or ψ)').to( rule.matches('not φ').and.doesntBranch() )
      rule.from('not (φ or ψ)').to( rule.matches('not ψ').and.doesntBranch() )
    ]  
  
  not_arrow :
    decomposition : [
      rule.from('not (φ arrow ψ)').to( rule.matches('φ').and.doesntBranch() )
      rule.from('not (φ arrow ψ)').to( rule.matches('not ψ').and.doesntBranch() )
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
    decomposition : rule.from('exists τ φ').to( rule.matches('φ[τ-->α]').and.isNewName('α').and.doesntBranch() )
    decomposition2 : rule.from('exists τ φ').to( rule.matches('φ[τ-->α]').and.branches() ).where( rule.ruleIsAppliedToEveryExistingConstantAndANewConstant('α') )
  
  'not-all' : 
    decomposition : rule.from('not all τ φ').to( rule.matches('exists τ not φ').and.doesntBranch() )
    
  'not-exists' : 
    decomposition : rule.from('not exists τ φ').to( rule.matches('all τ not φ').and.doesntBranch() )
  
  identity : 
    decomposition : [
      rule.from('α=β').and('φ').to( rule.matches('φ[α-->β]').and.doesntBranch() )
      rule.from('β=α').and('φ').to( rule.matches('φ[α-->β]').and.doesntBranch() )
    ]

# `.openBranch` is a special rule: it needs to know which rule set it is in.
rules['open-branch'] = rule.from().to( rule.openBranch(rules) )


# Keys are awFOL `.type` properties (unlike the keys of `rules` which
# are the names of rules defined in the `justification_parser.l` lexer).
rule.makeTickCheckers rules, 
  'and' : rule.tickIf.allRulesAppliedInEveryBranch( rules.and.decomposition )
  'or' : rule.tickIf.someRuleAppliedInEveryBranch( rules.or.decomposition )
  arrow : rule.tickIf.someRuleAppliedInEveryBranch( rules.arrow.decomposition )
  double_arrow : rule.tickIf.someRuleAppliedInEveryBranch( [rules.double_arrow.decomposition[1], rules.double_arrow.decomposition[3]] )
  universal_quantifier : rule.tickIf.ruleAppliedAtLeastOnceAndAppliedToEveryExistingConstant( rules.universal.decomposition )
  existential_quantifier : rule.tickIf.someRuleAppliedInEveryBranch( [rules.existential.decomposition2] )
  # identity : there is no `tickif` rule because identity statements cannot 
  # be ticked; but the .openBranch rule checks that no further 
  # information could be extracted from an identity statement.
  'not' :
    'not' : rule.tickIf.allRulesAppliedInEveryBranch( [rules['double-negation'].decomposition] )
    'and' : rule.tickIf.someRuleAppliedInEveryBranch( rules.not_and.decomposition )
    'or' : rule.tickIf.allRulesAppliedInEveryBranch( rules.not_or.decomposition )
    arrow : rule.tickIf.allRulesAppliedInEveryBranch( rules.not_arrow.decomposition )
    double_arrow : rule.tickIf.someRuleAppliedInEveryBranch( [rules.not_double_arrow.decomposition[1], rules.not_double_arrow.decomposition[3]] )
    universal_quantifier : rule.tickIf.allRulesAppliedInEveryBranch( rules['not-all'].decomposition )
    existential_quantifier : rule.tickIf.allRulesAppliedInEveryBranch( rules['not-exists'].decomposition )
  


exports.rules = rules
dialectManager.registerRuleSet('logicbook_tree', rules)