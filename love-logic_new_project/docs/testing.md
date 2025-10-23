# Testing

We rely on two complementary test suites: doctests embedded in the documentation and a Mocha-based unit suite for the CoffeeScript modules.

## Doctests

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

Coverage + quality snapshot
- Doctests are great at preventing drift in walkthrough-style documentation, but they only cover the scenarios we showcase. They do not exercise error paths or the full API surface.

## Mocha unit tests

We have a conventional Mocha + Chai suite in `test/*.coffee`. It is wired to the default `npm test` script and can be run in watch mode.

Run locally
- Full suite: `npm test`
- Watch mode: `npm run test:watch`

Scope today
- Files cover the core modules: evaluation (`test/test.evaluate.coffee`), first-order logic helpers (`test/test.fol.coffee`), pattern matching, normal-form transformations, operator metadata, substitution helpers, and assorted utilities.
- Assertions are mostly happy-path examples with a handful of sanity checks on dialect handling. Explicit regression tests for error handling, parser failures, or example end-to-end flows are still light.
- We do not collect code coverage metrics yet, so gaps are spotted manually. Adding nyc/istanbul would help quantify what remains untested.

Extending the suite
- Follow the existing pattern of requiring the CoffeeScript sources and using `chai.assert`/`expect`.
- Prefer focused unit tests that exercise one responsibility per example. When adding new modules, create a corresponding `test.<module>.coffee`.
- Add regression tests for bug fixes—especially around edge cases—to raise our confidence in the growing parser and dialect surface.
