# Testing docs with doctests

We validate runnable examples embedded in Markdown using fenced code blocks labeled `coffee doctest`.

How it works
- The validator scans all `docs/**/*.md` for blocks like:

```coffee doctest
fol = require './fol'
expr = fol.parse 'A and B'
console.log expr.toString()  #=> A ∧ B
```

- Each block is executed as a CoffeeScript file with `node -r coffeescript/register`.
- Lines ending with `#=> ...` are treated as expected substrings in stdout. The validator checks that stdout contains those substrings.
- Relative imports to `./fol` are automatically adjusted by the validator to resolve from the repository root during execution.

Guidelines
- Keep doctests minimal and deterministic. Prefer small, self-contained examples.
- Use `#=>` to assert important output. You can include multiple `#=>` lines to check several outputs.
- If an example depends on a specific dialect (e.g., logicbook, teller, forallx), set it explicitly within the block:

```coffee doctest
fol = require './fol'
fol.setDialect 'logicbook'
# ...
```

Run locally
- Validate docs: `npm run docs:test`
- Run examples: `npm run examples`

Extending assertions
- Currently, assertions check for expected substrings. If needed, we can upgrade to structured assertions by printing JSON and matching exact objects.
