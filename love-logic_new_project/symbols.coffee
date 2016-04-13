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

module.exports = symbols

