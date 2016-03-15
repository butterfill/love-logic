_ = require 'lodash'

symbols =
  default : 
    'not' : '¬'
    'false' : "⊥"
    'identity' : "="
    'and' : "∧"
    'arrow' : "→"
    'double_arrow' : "↔"
    'or' : "∨"
    'nor' :  "↓"
    'nand' : "↑"
    'universal_quantifier' : "∀"
    'existential_quantifier' : "∃" 

  copi : 
    'not' : '~'
    'false' : "⊥"
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

