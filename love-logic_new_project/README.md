Parsers for a first-order language and for Fitch-style proofs. Includes:
- Evaluate FOL sentences against possible worlds
- Convert sentences to prenex normal form
- Pattern-match logical forms with substitutions (e.g., `φ[τ->α]`)
- Express Fitch rules declaratively, e.g.

```
universal :
    elim : rule.from('all τ φ').to('φ[τ->α]')
    intro : rule.from( rule.subproof('[α]', 'φ') ).to('all τ φ[α->τ]')
```

This code has been used for 10+ years by thousands of students in over a million exercises.

Quick start (2025, Node.js v22)

Prerequisites
- Node.js 22.x
- npm 10+

Install
- npm ci (preferred if using the committed lockfile) or npm install

Run the tests
- npm test
  - Uses Mocha with CoffeeScript 2 via `.mocharc.json`
  - Test suites live in `test/`, `parser/test/`, and `proofs/test/`
- For watch mode: npm run test:watch

Notes on CoffeeScript and Mocha
- The project now uses `coffeescript` (v2) instead of the legacy `coffee-script` package.
- Mocha is configured via `.mocharc.json` to require `coffeescript/register` and pick up `.coffee` specs.
- The old `--compilers coffee:coffee-script/register` flag is deprecated and no longer used.

Compiling parsers
- Parser grammars are in `parser/*.jison`.
- Generated parsers (JavaScript) are already checked in (e.g., `parser/awFOL.js`).
- If you edit a `.jison` file, regenerate with jison (example):
  - npx jison parser/awFOL.jison -o parser/awFOL.js
  - Repeat for the other grammars as needed.

Browser bundle (optional)
- See `_browserify/` for scripts and artifacts to generate a browser bundle.
- Example (from that folder): `bash browserify_do.sh` (may require Java and browserify installed globally or via npx).

Documentation and examples
- Docs live in `docs/` and include runnable doctest blocks (coffeescript). Current pages: overview, evaluation, normal_form, proofs, parsers, substitutions, testing.
- Validate docs: `npm run docs:test` (executes `coffee doctest` blocks and checks `#=>` expectations)
- Run examples: `npm run examples` (runs `examples/*.coffee`)

Project status and license
- (c) Stephen A. Butterfill 2015.
- Historically shared for teaching; license headers exist in various files. If you plan to publish/redistribute, confirm licensing terms or update to an explicit OSS license.

Status of docs and what’s next
- Implemented: a Markdown doc set in `docs/` with runnable CoffeeScript doctests, an examples/ folder, and a validator (`npm run docs:test`) that executes doctests and checks `#=>` output.
- Added: pages for overview, evaluation, normal_form, proofs (with subproofs, dialect example, and quantified rules), parsers, substitutions, and testing.
- Near-term tasks:
  - Expand proofs coverage (∀-elim/∃-elim with subproofs; more dialects: forallx, teller).
  - Add more end-to-end examples mirroring typical student workflows.
  - Add CONTRIBUTING.md (grammar regeneration, dialects, testing conventions) and CHANGELOG.md.
  - Consider CI (Node 20/22) to run unit tests and doctests; optionally add coverage via c8.
- Longer-term (optional):
  - Upgrade lodash to v4 with test coverage.
  - Consider a generated docs site (Docsify or Docusaurus) if the doc set grows or needs versioning.
