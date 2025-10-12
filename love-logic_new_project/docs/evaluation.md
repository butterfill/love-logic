# Evaluation

Evaluate FOL sentences against a world. Worlds specify a domain, name-to-object mapping, and predicate extensions.

The example below should run without errors (doctested). It prints `true`.

```coffee doctest
fol = require './fol'
# Default dialect is 'lpl' (already set).
expr = fol.parse 'exists x P(x)'
world =
  domain: [1,2]
  names: {}
  predicates:
    P: [[1]]
console.log expr.evaluate world
```

World shape:
- `domain`: list of objects in the world
- `names`: map from constant names to domain objects (e.g., `{a: 1}`)
- `predicates`: predicate name to a list of tuples in its extension (e.g., `P: [[1],[2]]`, `R: [[1,2]]`)
