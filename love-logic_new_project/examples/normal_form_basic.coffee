fol = require '../fol'

# Example: convert a sentence to Prenex Normal Form (PNF)
# Start with a sentence mixing quantifiers and connectives
# Default dialect is 'lpl' (already set).
expr = fol.parse 'not (exists x P(x)) or (all x Q(x))'

# Convert to PNF + simplification/sorting
pnf = expr.convertToPNFsimplifyAndSort()

console.log pnf.toString()
