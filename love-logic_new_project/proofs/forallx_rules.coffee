dialectManager = require('../dialect_manager/dialectManager')

# Rules of proof for natural deduction as presented in 
# Magnus’ forallx (2014).  


rule = require './rule'
rule.setParser( dialectManager.getParser('awFOL') )
rules = 
  _description : '''
    Rules of proof for the system of proof specified in forallx. 
  '''
  
  premise : rule.premise()

  reit : rule.from('φ').to('φ')

  'and' :
    elim : 
      left : rule.from('φ and ψ').to('φ')
      right : rule.from('φ and ψ').to('ψ')
    intro : rule.from('φ').and('ψ').to('φ and ψ')

  'or' :
    elim  : 
      left : rule.from('φ or ψ').and('not φ').to('ψ')
      right : rule.from('φ or ψ').and('not ψ').to('φ')
    intro : 
      left  : rule.from('φ').to('φ or ψ')
      right : rule.from('φ').to('ψ or φ')

  arrow :
    elim : rule.from('φ arrow ψ').and('φ').to('ψ')
    intro : rule.from( rule.subproof('φ','ψ') ).to('φ arrow ψ')

  double_arrow :
    elim : 
      left : rule.from('φ↔ψ').and('φ').to('ψ')
      right : rule.from('φ↔ψ').and('ψ').to('φ')
    intro : rule.from( rule.subproof('φ','ψ') ).and( rule.subproof('ψ','φ') ).to('φ↔ψ')
    
  'not' : 
    elim : rule.from( rule.subproof('not φ', 'φ2').contains('ψ', 'not ψ') ).to('φ')
    intro : rule.from( rule.subproof('φ', 'φ2').contains('ψ', 'not ψ') ).to('not φ')

  # Progress so far: got to p.117, derived rules.
  
  identity :
    intro : rule.to('α=α')
    elim :
      left : rule.from('α=β').and('φ').to('φ[α-->β]')
      right : rule.from('α=β').and('φ').to('φ[β-->α]')

  existential :
    elim : rule.from('exists τ φ').and( rule.subproof( rule.match('φ[τ-->α]').isNewName('α'), 'ψ') ).to('ψ[α-->null]')
    intro : rule.from('φ[τ-->α]').to('exists τ φ')

  universal :
    elim : rule.from('all τ φ').to('φ[τ-->α]')
    # for Magnus and Button:
    # intro: rule.from('φ[τ-->null]').isNotInUndischargedPremises('α').to('all τ φ[α-->τ]')
    intro: rule.from( rule.match('φ[τ-->α]').isNotInAnyUndischargedPremise('α') ).to('all τ φ')

exports.rules = rules
dialectManager.registerRuleSet('forallx', rules)