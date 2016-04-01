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
    'existential_quantifier' : "∃" 

module.exports = symbols

