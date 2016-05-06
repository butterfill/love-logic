_ = require 'lodash'

symbols =
  default : 
    'not' : '¬'
    'false' : "⊥"
    'contradiction' : "⊥" # for proof parser
    'identity' : "="
    'and' : "∧"
    'arrow' : "→"
    'double_arrow' : "↔"
    'or' : "∨"
    'nor' :  "↓"
    'nand' : "↑"
    'universal_quantifier' : "∀"
    'universal' : "∀" # for proof parser
    'existential_quantifier' : "∃" 
    'existential' : "∃" # for proof parser
    propLanguageName : 'FOL'
    predLanguageName : 'FOL'
    elim : ' Elim'
    intro : ' Intro'
    decomposition: 'D'
    decomposition2: 'D2'
    

  copi : 
    'not' : '~'
    'false' : "⊥"
    'contradiction' : "⊥"
    'identity' : "="
    'and' : "•"
    'arrow' : "⊃"
    'double_arrow' : "≡"
    'or' : "∨"
    'nor' :  "↓"
    'nand' : "↑"
    'universal_quantifier' : ""
    'universal' : "all" # for proof parser TODO:check
    'existential_quantifier' : "∃" 
    'existential' : "∃" # for proof parser
    quantifiersInBrackets : true
    predicationBracketsAndCommas : false
    singleLetterPredicates : true

  teller : 
    'not' : '~'
    'false' : "⊥"
    'contradiction' : "⊥" # for proof parser
    'identity' : "="
    'and' : "&"
    'arrow' : "⊃"
    'double_arrow' : "≡"
    'or' : "∨"
    'nor' :  "↓"
    'nand' : "↑"
    'universal_quantifier' : "∀"
    'universal' : "∀" # for proof parser
    'existential_quantifier' : "∃" 
    'existential' : "∃" # for proof parser
    quantifiersInBrackets : true
    predicationBracketsAndCommas : false
    singleLetterPredicates : true
    # for justification in proofs:
    'not-all' : '~∀'
    'all-not' : '∀~'
    'exists-not' : '∃~'
    'not-exists' : '~∃'
    propLanguageName : 'sentence logic'
    predLanguageName : 'predicate logic'
    
    
  forallx : 
    'not' : '¬'
    'false' : "⊥"
    'contradiction' : "⊥" # for proof parser
    'identity' : "="
    'and' : "&"
    'arrow' : "→"
    'double_arrow' : "↔"
    'or' : "∨"
    'nor' :  "↓"
    'nand' : "↑"
    'universal_quantifier' : "∀"
    'universal' : "∀" # for proof parser
    'existential_quantifier' : "∃" 
    'existential' : "∃" # for proof parser
    quantifiersInBrackets : false
    predicationBracketsAndCommas : false
    # TODO: predicates can have number subscripts 
    # (requires updates to parser and toString):
    singleLetterPredicates : true
    propLanguageName : 'SL'
    predLanguageName : 'QL'


  logicbook : 
    'not' : '~'
    'false' : "⊥"
    'contradiction' : "⊥" # for proof parser
    'identity' : "="
    'and' : "&"
    'arrow' : "⊃"
    'double_arrow' : "≡"
    'or' : "∨"
    'nor' :  "↓"
    'nand' : "↑"
    'universal_quantifier' : "∀"
    'universal' : "∀" # for proof parser
    'existential_quantifier' : "∃" 
    'existential' : "∃" # for proof parser
    quantifiersInBrackets : true
    predicationBracketsAndCommas : false
    singleLetterPredicates : true
    propLanguageName : 'SL'
    predLanguageName : 'PL'
    # for justification in proofs:
    association : 'Assoc'
    premise : 'Assumption'
    DM : 'DeM'
    decomposition: 'D'
    decomposition2: 'D2'
    tick : '✓'
    'double-negation' : '~ ~'
    not_double_arrow : '~ ≡'
    not_and : '~ &'
    not_or : "~ ∨"
    not_arrow : "~ ⊃"
    


module.exports = symbols

