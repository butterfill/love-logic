# Substitutions and Matching

Work with metavariables, substitutions, and pattern matching.

Below, we find a pattern and apply matches. This doctest should print two lines: the match object keys and the instantiated formula.

```coffee doctest
fol = require './fol'
util = require './util'
pattern = fol.parse 'exists x P(x)'
expr = fol.parse 'exists x P(x) and Q(x)'
matches = expr.findMatches pattern
console.log Array.isArray(Object.keys(matches))  #=> true
inst = expr.applyMatches matches
console.log inst.toString()
```

Notes:
- For robust tests, write specific patterns as in the unit tests using `match` utilities.
- See `test/test.match.coffee` for more detailed examples.
