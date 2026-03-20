Parsers for a first-order language and for Fitch-style proofs. Includes:

- evaluation of FOL sentences against possible worlds
- conversion to prenex normal form
- pattern matching and substitution on logical forms
- declarative specification of Fitch rules

```coffee
universal :
    elim : rule.from('all τ φ').to('φ[τ->α]')
    intro : rule.from( rule.subproof('[α]', 'φ') ).to('all τ φ[α->τ]')
```

This code has been used for more than 10 years by thousands of students in over a million exercises.

## Prerequisites

- Node.js 22.x
- npm 10+

## Install

- `npm ci`
- or `npm install`

## Build outputs

Build the package and browser artifacts:

- `npm run build`

This produces:

- `dist/index.mjs`
- `dist/proofs.mjs`
- `dist/browser.mjs`
- `dist/browser/love-logic.global.js`
- `dist/browser/love-logic.global.min.js`
- bundled `.d.ts` files in `dist/`

## ESM usage

Node or browser-bundler usage:

```js
import { fol, proof } from 'love-logic';

fol.setDialect('lpl');

const expr = fol.parse('A and B');
console.log(expr.toString({ replaceSymbols: true }));

const parsedProof = proof.parse('1. A\n2. A and A');
```

Subpath imports:

```js
import { proof, parseProof } from 'love-logic/proofs';
import { fol } from 'love-logic/browser';
```

## Standalone browser bundle

The standalone browser build is retained as a secondary artifact.

```html
<script src="/path/to/love-logic.global.min.js"></script>
<script>
  fol.setDialect('lpl');
  const expr = fol.parse('A and B');
  console.log(expr.toString({ replaceSymbols: true }));
</script>
```

The global bundle provides:

- `window.fol`
- `window.proof`
- `window.symbols`
- `window.loveLogic`

## Public API

The intended public API centers on:

- `fol`
- `proof`
- `symbols`

Common `fol` methods:

- `parse(text, parser?)`
- `parseUsingSystemParser(text)`
- `setDialect(name, version?)`
- `getCurrentDialectNameAndVersion()`
- `getAllDialectNamesAndDescriptions()`
- `getTextbookForDialect(name?)`
- `getPredLanguageName()`
- `getSymbols(name?)`

Common decorated expression methods:

- `toString(options?)`
- `evaluate(world)`
- `getNames()`
- `getPredicates()`
- `getFreeVariableNames()`
- `convertToPNFsimplifyAndSort()`

Proof entrypoint:

- `proof.parse(text)`

Common parsed proof methods:

- `verify()`
- `listErrorMessages()`
- `getLine(lineNumber)`
- `toString(options?)`

## Tests

Source-level tests:

- `npm test`
- `npm run test:watch`

Documentation and examples:

- `npm run docs:test`
- `npm run examples`

Packaged-output tests:

- `npm run test:package`

Run the full verification matrix:

- `npm run test:all`

`npm run test:all` runs:

- the historical Mocha/CoffeeScript test suite
- docs doctests
- example programs
- the package build
- smoke tests against the built ESM package and browser global bundle

## Parser regeneration

- Parser grammars live in `parser/*.jison`.
- Generated parsers are checked in.
- If you edit a grammar, regenerate it with `jison`, for example:
  - `npx jison parser/awFOL.jison -o parser/awFOL.js`

## Documentation

- entry point: `docs/README.md`
- docs live in `docs/`
- examples live in `examples/`

## Notes

- The source code remains CoffeeScript-based and the existing runtime behavior is intentionally preserved.
- The package now ships a documented ESM interface and handwritten TypeScript declarations for the supported public API.
- `_browserify/` is retained as historical context, but the supported browser artifact is now produced by `npm run build`.

## Project status and license

- (c) Stephen A. Butterfill 2015.
- License headers exist in various files. If you plan to publish or redistribute, confirm the intended licensing terms first.
