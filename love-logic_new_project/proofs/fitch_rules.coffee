dialectManager = require('../dialect_manager/dialectManager')

rule = require './rule'
rule.setParser( dialectManager.getParser('awFOL') )
# keys are the names of rules defined in the `justification_parser.l` lexer:
rules = 
  _description : '''
    Rules of proof for classical first-order logic.  The rules assume that
    there is no possible situation with an empty domain.
  '''
  
  generalRequirements : 
    noFreeVariables : true
    boxAllowedInPremiseOnly : true
    boxMustBeNewName : true
  
  premise : rule.from().to( rule.premise() )

  reit : rule.from('φ').to('φ')

  'and' :
    elim : 
      left : rule.from('φ and ψ').to('φ')
      right : rule.from('φ and ψ').to('ψ')
    intro : rule.from('φ').and('ψ').to('φ and ψ')

  'or' :
    elim  : rule.from('φ or ψ').and(rule.subproof('φ', 'χ')).and(rule.subproof('ψ', 'χ')).to('χ' )
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
      left : rule.from('α=β').and('φ').to('φ[α-->β]')
      right : rule.from('α=β').and('φ').to('φ[β-->α]')
        
  existential :
    elim : rule.from('exists τ φ').and( rule.subproof('[α]φ[τ-->α]', 'ψ') ).to('ψ[α-->null]')

    intro : rule.from('φ[τ-->α]').to('exists τ φ')

  universal :
    elim : rule.from('all τ φ').to( rule.matches('φ[τ-->α]').and.isName('α') )
    intro : 
      # This is the standard rule (not really `left`):
      left : rule.from( rule.subproof( rule.matches('[α]').and.isName('α'), rule.matches('φ[τ-->α]').and.doesNotContainName('α') ) ).to( rule.matches('all τ φ') )
      #
      # This is what LPL calls `general conditional proof`: 
      right : rule.from( rule.subproof( rule.matches('[α]φ[τ-->α]').and.doesNotContainName('α').and.isName('α'), rule.matches('ψ[τ-->α]').and.doesNotContainName('α') ) ).to('all τ (φ arrow ψ)')

exports.rules = rules
dialectManager.registerRuleSet('fitch', rules)