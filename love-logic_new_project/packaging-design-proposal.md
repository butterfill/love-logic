# Packaging Design Proposal

## Goals

- Publish a modern ESM package for Node.js and browser applications.
- Retain a standalone browser build as a secondary artifact for direct inclusion in web pages.
- Minimize changes to existing source code and preserve current behavior.
- Add a documented TypeScript interface for the supported public API.
- Modernize how tests are run without rewriting the test suite or adding CI.
- Maximize regression assurance.

## Constraints and non-goals

- ESM package only. No published CommonJS package interface.
- No CI work in this phase.
- No major source rewrite to JavaScript or TypeScript.
- No broad internal API cleanup unless required to support packaging safely.

## What current usage tells us

The existing `love-logic-server` application uses a relatively small and coherent subset of the library:

- `fol.parse(...)`
- `fol.parseUsingSystemParser(...)`
- expression instance methods added by decoration, especially:
  - `.toString(...)`
  - `.evaluate(...)`
  - `.getNames()`
  - `.getPredicates()`
  - `.getFreeVariableNames()`
  - `.convertToPNFsimplifyAndSort()`
- dialect functions:
  - `fol.setDialect(...)`
  - `fol.getCurrentDialectNameAndVersion()`
  - `fol.getAllDialectNamesAndDescriptions()`
  - `fol.getTextbookForDialect(...)`
  - `fol.getPredLanguageName()`
- symbol access:
  - `fol.symbols.default`
  - one usage of `fol._dialectManager.getSymbols()`
- proof entrypoint:
  - `proof.parse(...)`
- proof instance methods:
  - `.verify()`
  - `.listErrorMessages()`
  - `.getLine(...)`
  - `.toString(...)`

This is the right basis for the new public API. The proposal below treats those capabilities as first-class and avoids exposing the entire internal module graph.

## Recommendation summary

Package the existing library around three supported entry points:

- root package entry for the main API
- `love-logic/proofs`
- `love-logic/browser`

The root package entry should expose a stable `fol`-centric API plus named exports for the most common entrypoints. The proof parser should be available both from the root entry and from a focused `proofs` subpath. The standalone browser build should remain available as a generated artifact and continue to attach globals for legacy usage.

Internally, keep the existing CoffeeScript/CommonJS sources and introduce a build layer that compiles to ESM. The public API should be defined explicitly by thin ESM wrapper modules rather than by exposing source files directly.

## Proposed package shape

### Published outputs

The published package should contain:

- `dist/index.js`
- `dist/proofs.js`
- `dist/browser.js`
- `dist/browser/love-logic.global.js`
- `dist/browser/love-logic.global.min.js`
- `dist/index.d.ts`
- `dist/proofs.d.ts`
- `dist/browser.d.ts`

Optional if useful during build/debug:

- `dist/internal/...`

These internal files should not be exported publicly.

### Package exports

Proposed `package.json` exports shape:

```json
{
  "type": "module",
  "main": "./dist/index.js",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js"
    },
    "./proofs": {
      "types": "./dist/proofs.d.ts",
      "import": "./dist/proofs.js"
    },
    "./browser": {
      "types": "./dist/browser.d.ts",
      "import": "./dist/browser.js"
    },
    "./browser/love-logic.global.js": "./dist/browser/love-logic.global.js",
    "./browser/love-logic.global.min.js": "./dist/browser/love-logic.global.min.js",
    "./package.json": "./package.json"
  }
}
```

Notes:

- `main` is included mainly for ecosystem compatibility, but `exports` is the real contract.
- No CommonJS export path is provided.
- The browser global bundle is explicitly exported as a file artifact, not as the main package entry.

## Proposed public API

## 1. Root entry: `love-logic`

Primary import style:

```js
import { fol, proof, symbols } from 'love-logic';
```

Also support:

```js
import { parse, parseUsingSystemParser, setDialect } from 'love-logic';
```

### Root exports

Recommended root exports:

- `fol`
- `proof`
- `symbols`
- `parse`
- `parseUsingSystemParser`
- `setDialect`
- `getCurrentDialectNameAndVersion`
- `getAllDialectNamesAndDescriptions`
- `getTextbookForDialect`
- `getLanguageNames`
- `getPredLanguageName`
- `parseProof`

Mapping:

- `parse` delegates to `fol.parse`
- `parseUsingSystemParser` delegates to `fol.parseUsingSystemParser`
- `parseProof` delegates to `proof.parse`

Rationale:

- This preserves the existing mental model for users of the old bundle: `fol` and `proof` remain central.
- It also gives modern ESM consumers a flatter import option for common tasks.

## 2. Proof-focused entry: `love-logic/proofs`

Primary import style:

```js
import { proof, parseProof } from 'love-logic/proofs';
```

Recommended exports:

- `proof`
- `parseProof`

This is mainly organizational. It gives a clean path for consumers who only need proof parsing and verification.

## 3. Browser helper entry: `love-logic/browser`

Primary import style:

```js
import { fol, proof, symbols } from 'love-logic/browser';
```

This should re-export the same ESM API as the root entry. Its main purpose is documentation clarity: browser users can import the same module API, while legacy users can use the standalone global bundle.

## Browser standalone artifact

This must be retained.

### Output

Generate a standalone browser bundle that:

- contains the same runtime behavior as the current browserified artifact
- exposes globals on `window`
- does not require a bundler

Proposed globals:

- `window.fol`
- `window.proof`
- `window.loveLogic`

Where:

- `window.fol` matches the current style and should be preserved
- `window.proof` matches the current style and should be preserved
- `window.loveLogic` is a new convenience namespace containing `{ fol, proof, symbols }`

### Compatibility position

The existing app appears to rely on the current global-style browser bundle. For that reason:

- `window.fol` and `window.proof` should be considered compatibility globals and preserved
- documentation should present `window.loveLogic` as the preferred new global namespace

### Secondary artifact, not primary contract

The global bundle should be documented as a compatibility/browser-convenience distribution, not the canonical API surface. The canonical API surface is the ESM package.

## API design details

## `fol`

The `fol` object should remain the primary namespace for sentence parsing and dialect management.

Supported members:

- `parse(text, parser?)`
- `parseUsingSystemParser(text)`
- `setDialect(name, version?)`
- `getCurrentDialectNameAndVersion()`
- `getAllDialectNamesAndDescriptions()`
- `getTextbookForDialect(name?)`
- `getLanguageNames()`
- `getPredLanguageName()`
- `symbols`

### New addition recommended: `getSymbols(name?)`

Current consuming code reaches into `fol._dialectManager.getSymbols()` once. That is an internal leak. To avoid endorsing `_dialectManager` publicly, add:

- `fol.getSymbols(name?)`

This should delegate to the existing dialect manager.

Recommendation:

- document `fol.getSymbols(name?)` as public
- retain `fol._dialectManager` temporarily for backward compatibility
- document `fol._dialectManager` as internal and deprecated, not part of the stable API

This is a small source change with high design value and low regression risk.

## Decorated expression objects

The decorated expression returned by `fol.parse(...)` is one of the most important parts of the public API and should be treated as such in the TypeScript definitions and docs.

Supported methods to document:

- `toString(options?)`
- `clone()`
- `walk(fn)`
- `delExtraneousProperties()`
- `isIdenticalTo(other)`
- `listMetaVariableNames()`
- `listMetaVariableNamesAsList()`
- `findMatches(pattern, matches?, options?)`
- `applyMatches(matches)`
- `applySubstitutions()`
- `containsSubstitutions()`
- `getAllSubstitutionInstances()`
- `getNames()`
- `getPredicates()`
- `getSentenceLetters()`
- `getFreeVariableNames()`
- `negate()`
- `convertToPNFsimplifyAndSort()`
- `isPNFExpressionEquivalent(other)`
- `evaluate(world)`

Design position:

- These methods are already relied on in practice.
- They should be documented as supported on parsed expressions.
- The raw AST shape should be typed conservatively. The method-bearing decorated expression is the public abstraction.

## `proof`

The proof namespace should remain narrow and explicit.

Supported members:

- `parse(text, options?)`

The parsed proof result should support:

- `verify()`
- `listErrorMessages()`
- `getLine(lineNumber)`
- `toString(options?)`
- `clone(options?)`
- `detachChildren()`

Individual lines accessed via `getLine(...)` should be typed loosely but document:

- `verify()`
- `status`
- `sentence`
- `number`

## `symbols`

Export the current symbol table object as a public constant:

- `symbols.default`
- `symbols.teller`
- `symbols.forallx`
- `symbols.logicbook`
- `symbols.copi`

This is already used by `love-logic-server` and is a reasonable stable public surface.

## What should stay internal

The following should not be part of the documented public API:

- individual source modules like `util`, `match`, `normal_form`, `op`
- parser implementation files under `parser/*.js`
- dialect manager internals
- rule internals

They may still exist in the built package, but they should not be exported through `package.json`.

## TypeScript interface design

## Strategy

Use handwritten `.d.ts` files for the public API.

This is the right tradeoff here because:

- the source is CoffeeScript, not TypeScript
- the runtime API is dynamic and decoration-based
- a public type layer should describe intended usage, not mirror every implementation detail

## Type design principles

- Type the supported public surface only.
- Prefer stable interfaces over deep structural AST exactness.
- Be explicit about nullable or error-returning behavior where it exists today.
- Document semantics thoroughly in JSDoc comments within the `.d.ts` files.

## Recommended public types

### Root-level types

- `DialectName`
- `DialectVersion`
- `DialectInfo`
- `Symbols`
- `ExpressionStringifyOptions`
- `World`
- `PredicateRef`
- `ParseOptions`
- `ProofParseOptions`

### Expression types

- `Expression`
- `DecoratedExpression`
- `MatchMap`

Important design choice:

- `DecoratedExpression` should be the primary public type returned by `parse(...)`
- `Expression` can be the underlying structural type, likely defined loosely

### Proof types

- `Proof`
- `ProofLine`
- `ProofStatus`

### Return behavior

Current proof parsing returns either a proof object or an error string. That should remain as-is for minimal change:

- `parseProof(text): Proof | string`
- `proof.parse(text): Proof | string`

For `fol.parse(...)`, the current behavior is to throw on parse errors. Keep that behavior and document it.

## Documentation expectations for the type layer

The `.d.ts` files should be heavily documented for:

- dialect behavior
- global mutable dialect state
- difference between `parse(...)` and `parseUsingSystemParser(...)`
- decorated expression methods
- proof parsing return shape
- browser-global compatibility

That documentation is important because the library’s design is richer than a small parse/evaluate helper.

## Build design

## Source preservation

Keep source files largely unchanged:

- retain `.coffee` source
- retain generated parser `.js` files
- retain current tests

## Build pipeline

Recommended build stages:

1. Compile CoffeeScript source to intermediate JavaScript.
2. Convert or wrap the compiled output into ESM entry modules.
3. Generate the standalone browser bundle from the same public entry layer.
4. Emit `.d.ts` files.

The important architectural point is that packaging should be driven by explicit ESM wrapper entry modules, not by exposing compiled source files directly.

That gives:

- a stable public contract
- freedom to keep internals unchanged
- a clean location to add small compatibility helpers like `fol.getSymbols(...)`

## Browser bundle generation

The standalone browser bundle should be built from the same public wrapper layer, not from a separate ad hoc shim if possible.

That reduces divergence between:

- package ESM usage
- browser global usage

If there is one exception, it is acceptable to keep a small browser-only adapter whose only job is to attach globals:

```js
window.fol = fol;
window.proof = proof;
window.loveLogic = { fol, proof, symbols };
```

## Regression assurance plan

This is the most important part of the work.

## Test commands to support

Recommended scripts:

- `npm test`
- `npm run test:watch`
- `npm run docs:test`
- `npm run examples`
- `npm run build`
- `npm run test:package`
- `npm run test:all`

Where:

- `npm test` runs the existing source-level Mocha suite
- `npm run test:package` runs smoke and behavior tests against built ESM outputs and the standalone browser artifact
- `npm run test:all` runs source tests, docs tests, examples, build, and package tests

## Package-level tests to add

These should be new and focused. They should not duplicate the entire existing suite.

### ESM smoke tests

Verify that Node can import:

- `love-logic`
- `love-logic/proofs`
- `love-logic/browser`

### API contract tests

Verify:

- `fol.parse(...)` works from the built package
- `fol.parseUsingSystemParser(...)` works
- `fol.setDialect(...)` and `fol.getCurrentDialectNameAndVersion()` work
- `fol.getSymbols(...)` works if added
- `symbols.default` exists
- `proof.parse(...)` works
- parsed expressions retain decorated methods
- parsed proofs retain verification methods

### Browser global tests

Run a small browser-focused test against the generated standalone bundle and verify:

- `window.fol` exists
- `window.proof` exists
- `window.loveLogic` exists
- `window.fol.parse(...)` works

This can be done with a lightweight browser runner or a DOM-like harness, but the exact tool choice is secondary to coverage.

## Backward compatibility policy for this phase

The proposal assumes the following compatibility guarantees:

- existing expression behavior is preserved
- existing proof behavior is preserved
- dialect names and symbol tables are preserved
- standalone browser global usage is preserved

The proposal also recommends one compatibility bridge:

- keep `fol._dialectManager` available in this release if it is currently reachable

But with a clear documentation stance:

- public replacement: `fol.getSymbols(name?)`
- `_dialectManager` remains unsupported and may be removed in a later major version

## Proposed file/module organization

One reasonable layout:

- `src-entry/index.js`
- `src-entry/proofs.js`
- `src-entry/browser.js`
- `src-entry/browser-global.js`
- `types/index.d.ts`
- `types/proofs.d.ts`
- `types/browser.d.ts`

These wrapper modules would import from compiled internal code and define the public contract explicitly.

This keeps the packaging layer separate from the historical source layout.

## Migration/documentation examples

### Node ESM

```js
import { fol, proof } from 'love-logic';

fol.setDialect('lpl');
const expr = fol.parse('A and B');
console.log(expr.toString({ replaceSymbols: true }));

const parsedProof = proof.parse(`
1. A
2. A and A
`);
```

### Browser ESM

```js
import { fol } from 'love-logic/browser';

fol.setDialect('forallx');
const expr = fol.parse('Fa');
```

### Browser global bundle

```html
<script src="/path/to/love-logic.global.min.js"></script>
<script>
  fol.setDialect('lpl');
  const expr = fol.parse('A and B');
  console.log(expr.toString({ replaceSymbols: true }));
</script>
```

## Decisions recommended before implementation

These are the implementation decisions I recommend taking as settled unless new constraints appear:

1. The stable public contract is wrapper-based, not source-file-based.
2. The root API centers on `fol`, `proof`, and `symbols`.
3. `fol.getSymbols(name?)` should be added as a public method.
4. `fol._dialectManager` should remain temporarily reachable but undocumented.
5. The standalone browser global bundle is retained and shipped as a secondary artifact.
6. Handwritten `.d.ts` files define the supported interface.
7. Existing Mocha tests remain the source-of-truth regression suite.
8. Additional package tests validate built artifacts rather than replacing source tests.

## Final recommendation

Implement a thin, explicit packaging layer over the current codebase rather than changing the core library design. The public API should formalize what existing consumers actually use: `fol`, `proof`, decorated expressions, dialect management, and symbol tables. The standalone browser bundle should stay, but as a compatibility artifact generated from the same public entry layer as the ESM package.

This approach gives the best balance of maintainability, clarity, and regression safety.
