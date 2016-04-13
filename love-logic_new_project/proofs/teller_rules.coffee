dialectManager = require('../dialect_manager/dialectManager')

rule = require './rule'
# We need `tellerFOL` because the hat notation (used for all intro)
# isn’t part of `awFOL`.
rule.setParser( dialectManager.getParser('teller') )
rules = 
  _description : '''
    Rules of proof for classical first-order logic as presented in Paul Teller,
    A Modern Formal Logic Primer (1998).
  '''
  
  premise : rule.premise()

  reit : rule.from('φ').to('φ')

  'and' :
    elim :
      left : rule.from('φ and ψ').to('φ')
      right : rule.from('φ and ψ').to('ψ')
    intro : rule.from('φ').and('ψ').to('φ and ψ')

  'or' :
    elim : 
      left : [
        rule.from('φ or ψ').and('not φ').to('ψ')
        rule.from('not φ or ψ').and('φ').to('ψ')
      ]
      right : [
        rule.from('φ or ψ').and('not ψ').to('φ')
        rule.from('φ or not ψ').and('ψ').to('φ')
      ]
    intro :
      left  : rule.from('φ').to('φ or ψ')
      right : rule.from('φ').to('ψ or φ')

  'not' :
    elim : rule.from('not not φ').to('φ')
    intro : [
      rule.from( rule.subproof('φ','ψ and not ψ') ).to('not φ')
      rule.from( rule.subproof('φ', 'φ2').contains(['ψ', 'not ψ']) ).to('not φ')
    ]

  # contradiction :
  #   elim : rule.from('contradiction').to('φ')
  #   intro : rule.from('not φ').and('φ').to('contradiction')
    
  arrow :
    elim : rule.from('φ arrow ψ').and('φ').to('ψ')
    intro : rule.from( rule.subproof('φ','ψ') ).to('φ arrow ψ')
    
  double_arrow :
    elim :
      left : [
        rule.from('φ↔ψ').to('φ arrow ψ')
        rule.from('φ↔ψ').and('φ').to('ψ')
      ]
      right : [
        rule.from('φ↔ψ').to('ψ arrow φ')
        rule.from('φ↔ψ').and('ψ').to('φ')
      ]
    intro : rule.from('φ arrow ψ').and('ψ arrow φ').to('φ↔ψ')
      

  identity :
    intro : rule.to('α=α')
    elim :
      left : rule.from('α=β').and('φ').to('φ[α-->β]')
      right : rule.from('α=β').and('φ').to('φ[β-->α]')

  existential :
    elim : rule.from('(exists τ) φ').and( rule.subproof('[α]φ[τ-->α]', 'ψ') ).to('ψ[α-->null]')
    intro : rule.from('φ[τ-->α]').to('(exists τ) φ')

  universal :
    elim : rule.from('(all τ) φ').to('φ[τ-->α]')
    intro : rule.from('φ[τ-->α^]').to('(all τ) φ')
  
  # derived rules (some derived rules appear above where
  # they have the same names as non-derived rules).
  
  weakening : rule.from('φ').to('ψ arrow φ')
  cases : [
    rule.from('φ or ψ').and('φ arrow χ').and('ψ arrow χ').to('χ')
    rule.from('φ or ψ').and(rule.subproof('φ', 'χ')).and(rule.subproof('ψ', 'χ')).to('χ')
  ]
  DC : [
    rule.from('φ arrow ψ').and('not ψ').to('not φ')
    rule.from('φ arrow not ψ').and('ψ').to('not φ')
    rule.from('not φ arrow ψ').and('not ψ').to('φ')
  ]
  reductio : [
    rule.from( rule.subproof('not φ','ψ and not ψ') ).to('φ')
    rule.from( rule.subproof('not φ', 'φ2').contains(['ψ', 'not ψ']) ).to('φ')
  ]
  DM : [
    rule.from('not (φ or ψ)').to('not φ and not ψ')
    rule.from('not φ and not ψ').to('not (φ or ψ)')
    rule.from('not (φ and ψ)').to('not φ or not ψ')
    rule.from('not φ or not ψ').to('not (φ and ψ)')
  ]
  contraposition : [
    rule.from('φ arrow ψ').to('not ψ arrow not φ')
    rule.from('not ψ arrow not φ').to('φ arrow ψ')
    rule.from('not φ arrow ψ').to('not ψ arrow φ')
    rule.from('not ψ arrow φ').to('not φ arrow ψ')
    rule.from('φ arrow not ψ').to('ψ arrow not φ')
    rule.from('ψ arrow not φ').to('φ arrow not ψ')
  ]
  C : [
    rule.from('φ arrow ψ').to('not φ or ψ')
    rule.from('not φ or ψ').to('φ arrow ψ')
    rule.from('not (φ arrow ψ)').to('φ and not ψ')
    rule.from('φ and not ψ').to('not (φ arrow ψ)')
  ]
  CD : rule.from('φ').and('not φ').to('ψ')
  'not-all' : rule.from('not (all τ) φ').to('(exists τ) not φ')
  'all-not' : rule.from('(all τ) not  φ').to('not (exists τ) φ')
  'not-exists' : rule.from('not (exists τ) φ').to('(all τ) not φ')
  'exists-not' : rule.from('(exists τ) not φ').to('not (all τ) φ')

    
  

exports.rules = rules
dialectManager.registerRuleSet('teller', rules)