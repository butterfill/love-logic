
rule = require './rule'

rules = 
  _description : '''
    Rules of proof for classical first-order logic.  The rules assume that
    there is no possible situation with an empty domain.
  '''
  
  premise : rule.premise()

  reit : rule.from('φ').to('φ')

  'and' :
    elim : 
      left : rule.from('φ and ψ').to('φ')
      right : rule.from('φ and ψ').to('ψ')
    intro : rule.from('φ').and('ψ').to('φ and ψ')

  'or' :
    elim  : rule.from('φ or ψ').and(rule.subproof('φ', 'χ')).and(rule.subproof('ψ', 'χ') ).to('χ' )
    intro : 
      left  : rule.from('φ').to('φ or ψ')
      right : rule.from('φ').to('ψ or φ')

  'not' : 
    elim : rule.from('not not φ').to('φ') 
    intro : rule.from( rule.subproof('φ','contradiction') ).to('not φ') 

  contradiction :
    elim : rule.from('contradiction').to('φ') 
    intro : rule.from('not φ').and('φ').to('contradiction')
    
  arrow :
    elim : rule.from('φ arrow ψ').and('φ').to('ψ')
    intro : rule.from( rule.subproof('φ','ψ') ).to('φ arrow ψ')
    
  double_arrow :
    elim : 
      left : rule.from('φ↔ψ').and('φ').to('ψ')
      right : rule.from('φ↔ψ').and('ψ').to('φ')
    intro : rule.from( rule.subproof('φ','ψ') ).and( rule.subproof('ψ','φ') ).to('φ↔ψ')

  identity :
    intro : rule.to('α=α')
    elim : 
      # Note: this rule will fail as things stand because `α=β` might match
      # what φ should match when =elim is applied to an identity statement.
      left : rule.from('α=β').and('φ').to('φ[α->β]')
      right : rule.from('α=β').and('φ').to('φ[β->α]')
        
  existential :
    elim : rule.from('exists τ φ').and( rule.subproof('[α]φ[τ->α]', 'ψ') ).to('ψ[α->null]')

    intro : rule.from('φ[τ->α]').to('exists τ φ')

  universal :
    elim : rule.from('all τ φ').to('φ[τ->α]')
    intro : rule.from( rule.subproof('[α]', 'φ') ).to('all τ φ[α->τ]')

exports.rules = rules