# Parsers and Dialects

Multiple FOL dialects are supported through grammar files in `parser/` and selected via the dialect manager.

- Dialects (examples): `lpl`, `forallx`, `teller`, `logicbook`
- Symbols for each dialect are in `symbols.coffee`.
- Generated parser JS files are checked in (e.g., `parser/awFOL.js`).

Regenerate a parser after changing a `.jison` file:

```bash
npx jison parser/awFOL.jison -o parser/awFOL.js
```

Quick parse doctest (system parser `awFOL` via `fol`):

```coffee doctest
fol = require './fol'
expr = fol.parse 'A and B'
console.log expr.toString()  #=> A ∧ B
```
