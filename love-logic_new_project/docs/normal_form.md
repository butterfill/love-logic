# Prenex Normal Form

Convert parsed expressions to Prenex Normal Form (PNF), simplify, and sort.

The example below should run without errors (doctested). It prints a string representation of the PNF.

```coffee doctest
fol = require './fol'
# Default dialect is 'lpl' (already set).
expr = fol.parse 'not (exists x P(x)) or (all x Q(x))'
pnf = expr.convertToPNFsimplifyAndSort()
console.log pnf.toString()
```

Notes:
- If you work directly with ASTs, ensure you convert to PNF before applying PNF-only operations.
- Use `expression.toString()` to view expressions with symbols for the current dialect.
