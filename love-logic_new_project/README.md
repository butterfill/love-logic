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

## Package name

The package is published as:

- `@butterfill/awfol`

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

For local testing without publishing, you can continue to work directly from `dist/`.

## ESM usage

Node or browser-bundler usage:

```js
import { fol, proof } from '@butterfill/awfol';

fol.setDialect('lpl');

const expr = fol.parse('A and B');
console.log(expr.toString({ replaceSymbols: true }));

const parsedProof = proof.parse('1. A\n2. A and A');
```

Subpath imports:

```js
import { proof, parseProof } from '@butterfill/awfol/proofs';
import { fol } from '@butterfill/awfol/browser';
```

Local `dist/` testing remains available:

```js
import { fol, proof } from './dist/index.mjs';
```

## Publishing to GitHub Packages

This package is configured for the GitHub npm registry:

- registry: `https://npm.pkg.github.com`
- scope: `@butterfill`

The `package.json` includes:

- scoped package name: `@butterfill/awfol`
- `publishConfig.registry`
- a `repository` field pointing at the GitHub repository

### Authentication

GitHub’s npm registry currently requires a personal access token (classic) for CLI authentication, and private package access requires package permissions appropriate to the operation.

For local CLI use, add this to `~/.npmrc`:

```ini
//npm.pkg.github.com/:_authToken=YOUR_GITHUB_PAT
@butterfill:registry=https://npm.pkg.github.com
```

Or log in with npm:

```bash
npm login --scope=@butterfill --auth-type=legacy --registry=https://npm.pkg.github.com
```

### Publish

From `love-logic_new_project/`:

```bash
npm run test:all
npm publish
```

`prepack` already runs `npm run build`, so publishing will include fresh `dist/` artifacts.

### Install from the private registry

In a consuming project, add the same scope mapping to `.npmrc`:

```ini
@butterfill:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=YOUR_GITHUB_PAT
```

Then install:

```bash
npm install @butterfill/awfol
```

Example:

```js
import { fol } from '@butterfill/awfol';
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
