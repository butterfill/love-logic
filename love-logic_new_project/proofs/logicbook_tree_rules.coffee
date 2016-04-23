dialectManager = require('../dialect_manager/dialectManager')

# Rules of proof for natural deduction as presented in 
# Bergman et al, ‘The Logic Book’ (2014).  


rule = require './rule'
rule.setParser( dialectManager.getParser('awFOL') )
rules = 
  _description : '''
    Rules of proof for the system of proof specified in forallx. 
  '''
  
  premise : rule.from().to( rule.premise() )
  
  'close-branch' : rule.from().to( rule.closeBranch() )
  'open-branch' : rule.from().to( rule.openBranch() )
  
  'and' : 
    'decomposition' : [
      rule.from('φ and ψ').to('φ') #.noBranch()
      rule.from('φ and ψ').to('ψ') #.noBranch()
    ]
  
  'arrow' : 
    'decomposition' : [
      rule.from('φ arrow ψ').to( rule.branch('not φ') )
      rule.from('φ arrow ψ').to( rule.branch('ψ') )
    ]
  
  
  'universal' :
    'decomposition' : rule.from('all τ φ').to('φ[τ-->α]')
  
  'existential' :
    # TODO : this is not correct!
    'decomposition2' : rule.from('exists τ φ').to('φ[τ-->α]')
  
  
exports.rules = rules
dialectManager.registerRuleSet('logicbook_tree', rules)