fol = require '../fol'

# Ensure the default dialect is set (awFOL is the system parser)
# Default dialect is 'lpl'; change if needed
# fol.setDialect 'lpl'

# Parse a simple existential predicate sentence
expr = fol.parse 'exists x P(x)'

# Define a simple world for evaluation
world =
  domain: [1,2]
  names: {}
  predicates:
    P: [[1]]  # Extension of P contains the object 1

result = expr.evaluate world
console.log result  # expected: true
