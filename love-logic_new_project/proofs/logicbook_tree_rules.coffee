dialectManager = require('../dialect_manager/dialectManager')

# Rules of proof for natural deduction as presented in 
# Bergman et al, ‘The Logic Book’ (2014).  


rule = require './rule'
rule.setParser( dialectManager.getParser('awFOL') )
rules = 
  _description : '''
    Rules of proof for the system of proof specified in forallx. 
  '''
  
  premise : rule.premise()
  
  'conjunction' : 
    'decomposition' : [
      rule.from('φ and ψ').to('φ')
      rule.from('φ and ψ').to('ψ')
    ]
  
  'arrow' : 
    'decomposition' : [
      rule.from('φ arrow ψ').to( rule.match('not φ') )
      rule.from('φ arrow ψ').to( rule.match('ψ') )
    ]
  
  
  'universal' :
    'decomposition' : rule.from('all τ φ').to('φ[τ-->α]')
  
  
  
exports.rules = rules
dialectManager.registerRuleSet('logicbook_tree', rules)