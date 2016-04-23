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

  reit : rule.from('φ').to('φ')

  'and' :
    elim : 
      left : rule.from('φ and ψ').to('φ')
      right : rule.from('φ and ψ').to('ψ')
    intro : rule.from('φ').and('ψ').to('φ and ψ')

  arrow :
    elim : rule.from('φ arrow ψ').and('φ').to('ψ')
    intro : rule.from( rule.subproof('φ','ψ') ).to('φ arrow ψ')

  'not' : 
    elim : rule.from( rule.subproof('not φ', 'φ2').contains('ψ', 'not ψ') ).to('φ')
    intro : rule.from( rule.subproof('φ', 'φ2').contains('ψ', 'not ψ') ).to('not φ')

  'or' :
    elim  : rule.from('φ or ψ').and(rule.subproof('φ', 'χ')).and(rule.subproof('ψ', 'χ')).to('χ' )
    intro : 
      left  : rule.from('φ').to('φ or ψ')
      right : rule.from('φ').to('ψ or φ')

  double_arrow :
    elim : 
      left : rule.from('φ↔ψ').and('φ').to('ψ')
      right : rule.from('φ↔ψ').and('ψ').to('φ')
    intro : rule.from( rule.subproof('φ','ψ') ).and( rule.subproof('ψ','φ') ).to('φ↔ψ')
    

  'modus-tollens' : rule.from('φ arrow ψ').and('not ψ').to('not φ')
  
  'hypothetical-syllogism' : rule.from('φ arrow ψ').and('ψ arrow χ').to('φ arrow χ')
  
  'disjunctive-syllogism' : [
    rule.from('φ or ψ').and('not φ').to('ψ')
    rule.from('φ or ψ').and('not ψ').to('φ')
  ]
  
  commutivity : [
    rule.from('φ').to( rule.replace('φ', {from:'ψ or χ', to:'χ or ψ'}) )
    rule.from('φ').to( rule.replace('φ', {to:'ψ or χ', from:'χ or ψ'}) )
    rule.from('φ').to( rule.replace('φ', {from:'ψ and χ', to:'χ and ψ'}) )
    rule.from('φ').to( rule.replace('φ', {to:'ψ and χ', from:'χ and ψ'}) )
    # They don’t include these:
    # rule.from('φ').to( rule.replace('φ', {from:'ψ <-> χ', to:'χ <-> ψ'}) )
    # rule.from('φ').to( rule.replace('φ', {to:'ψ <-> χ', from:'χ <-> ψ'}) )
  ]
      
  'implication' : [
    rule.from('φ').to( rule.replace('φ', {from:'ψ arrow χ', to:'not ψ or χ'}) )
    rule.from('φ').to( rule.replace('φ', {to:'ψ arrow χ', from:'not ψ or χ'}) )
  ]
  
  DM : [
    rule.from('φ').to( rule.replace('φ', {from:'not (ψ or χ)', to:'not ψ and not χ'}) )
    rule.from('φ').to( rule.replace('φ', {to:'not (ψ or χ)', from:'not ψ and not χ'}) )
    rule.from('φ').to( rule.replace('φ', {from:'not (ψ and χ)', to:'not ψ or not χ'}) )
    rule.from('φ').to( rule.replace('φ', {to:'not (ψ and χ)', from:'not ψ or not χ'}) )
  ]
  
  transposition : [
    rule.from('φ').to( rule.replace('φ', {from:'ψ arrow χ', to:'not χ arrow not ψ'}) )
    rule.from('φ').to( rule.replace('φ', {to:'ψ arrow χ', from:'not χ arrow not ψ'}) )
  ]
  
  distribution : [
    rule.from('φ').to( rule.replace('φ', {from:'ψ1 and (ψ2 or ψ3)', to:'(ψ1 and ψ2) or (ψ1 and ψ3)'}) )
    rule.from('φ').to( rule.replace('φ', {to:'ψ1 and (ψ2 or ψ3)', from:'(ψ1 and ψ2) or (ψ1 and ψ3)'}) )
    rule.from('φ').to( rule.replace('φ', {from:'ψ1 or (ψ2 and ψ3)', to:'(ψ1 or ψ2) and (ψ1 or ψ3)'}) )
    rule.from('φ').to( rule.replace('φ', {to:'ψ1 or (ψ2 and ψ3)', from:'(ψ1 or ψ2) and (ψ1 or ψ3)'}) )
  ]
  
  association : [
    rule.from('φ').to( rule.replace('φ', {from:'ψ1 and (ψ2 and ψ3)', to:'(ψ1 and ψ2) and ψ3'}) )
    rule.from('φ').to( rule.replace('φ', {to:'ψ1 and (ψ2 and ψ3)', from:'(ψ1 and ψ2) and ψ3'}) )
    rule.from('φ').to( rule.replace('φ', {from:'ψ1 or (ψ2 or ψ3)', to:'(ψ1 or ψ2) or ψ3'}) )
    rule.from('φ').to( rule.replace('φ', {to:'ψ1 or (ψ2 or ψ3)', from:'(ψ1 or ψ2) or ψ3'}) )
  ]
  
  'double-negation' : [
    rule.from('φ').to( rule.replace('φ', {from:'not not ψ', to:'ψ'}) )
    rule.from('φ').to( rule.replace('φ', {to:'not not ψ', from:'ψ'}) )
  ]

  idempotence : [
    rule.from('φ').to( rule.replace('φ', {from:'ψ', to:'ψ and ψ'}) )
    rule.from('φ').to( rule.replace('φ', {to:'ψ', from:'ψ and ψ'}) )
    rule.from('φ').to( rule.replace('φ', {from:'ψ', to:'ψ or ψ'}) )
    rule.from('φ').to( rule.replace('φ', {to:'ψ', from:'ψ or ψ'}) )
  ]
  
  exportation : [
    rule.from('φ').to( rule.replace('φ', {from:'ψ1 -> (ψ2 -> ψ3)', to:'(ψ1 and ψ2) -> ψ3'}) )
    rule.from('φ').to( rule.replace('φ', {to:'ψ1 -> (ψ2 -> ψ3)', from:'(ψ1 and ψ2) -> ψ3'}) )
  ]
  
  equivalence : [
    rule.from('φ').to( rule.replace('φ', {from:'(ψ -> χ) and (χ -> ψ)', to:'ψ <-> χ'}) )
    rule.from('φ').to( rule.replace('φ', {to:'(ψ -> χ) and (χ -> ψ)', from:'ψ <-> χ'}) )
    rule.from('φ').to( rule.replace('φ', {from:'(ψ and χ) or (not ψ and not χ)', to:'ψ <-> χ'}) )
    rule.from('φ').to( rule.replace('φ', {to:'(ψ and χ) or (not ψ and not χ)', from:'ψ <-> χ'}) )
  ]
  
  universal :
    elim : rule.from('all τ φ').to('φ[τ-->α]')
    # TODO: ensure a does not occur in the conclusion.  Maybe like this?
    # intro: rule.from('φ[τ-->null]').isNotInUndischargedPremises('α').to('all τ φ[α-->τ]')
    # If this doesn’t work, allow there to be multiple `.to` clauses (all of
    # which must be satisfied).
    intro: rule.from( rule.match('φ[τ-->α]').isNotInAnyUndischargedPremise('α') ).to('all τ φ')
  
  existential :
    elim : rule.from('exists τ φ').and( rule.subproof( rule.match('φ[τ-->α]').isNewName('α'), 'ψ') ).to('ψ[α-->null]')
    intro : rule.from('φ[τ-->α]').to('exists τ φ')
  
  'quantifier-negation' : [
    rule.from('φ').to( rule.replace('φ', {from:'not (all x) ψ', to:'(exists x) not ψ'}) )
    rule.from('φ').to( rule.replace('φ', {to:'not (all x) ψ', from:'(exists x) not ψ'}) )
    rule.from('φ').to( rule.replace('φ', {from:'not (exists x) ψ', to:'(all x) not ψ'}) )
    rule.from('φ').to( rule.replace('φ', {to:'not (exists x) ψ', from:'(all x) not ψ'}) )
  ]
  
  identity :
    intro : rule.to('all τ τ=τ')
    elim :
      left : rule.from('α=β').and('φ').to('φ[α-->β]')
      right : rule.from('α=β').and('φ').to('φ[β-->α]')

  
  
exports.rules = rules
dialectManager.registerRuleSet('logicbook', rules)