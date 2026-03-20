# Packaging Implementation Plan

## Objective

Implement the packaging design in a way that:

- preserves current runtime behavior
- produces an ESM package for Node and browser consumers
- retains a standalone browser bundle as a secondary artifact
- adds a documented TypeScript interface
- improves testability of the packaged outputs

This plan assumes the accepted design in [packaging-design-proposal.md](/home/steve/Documents/programming/git/love-logic/love-logic_new_project/packaging-design-proposal.md).

## Phase 1: Establish package build inputs

### 1. Fix and normalize package metadata

Update `package.json` so it becomes a valid, maintainable package definition for development and publication.

Work:

- remove the obsolete `main: "index.js"` assumption
- clean up duplicate `scripts` definitions
- define `type: "module"`
- add `exports`
- add `files`
- add `build`, `test:package`, and `test:all` scripts
- keep existing `test`, `test:watch`, `examples`, and `docs:test` semantics

Expected outcome:

- the package has one clear metadata source of truth
- the build outputs are explicitly defined

### 2. Add a dedicated packaging entry layer

Create explicit wrapper entry modules rather than exporting compiled source files directly.

Proposed new files:

- `src-entry/index.js`
- `src-entry/proofs.js`
- `src-entry/browser.js`
- `src-entry/browser-global.js`

Responsibilities:

- import the compiled internal runtime
- re-export the supported public API
- define compatibility aliases such as `parse` and `parseProof`
- attach browser globals only in `browser-global.js`

Expected outcome:

- the public API becomes intentional and stable
- internals stay private

## Phase 2: Compile legacy source to package runtime

### 3. Compile CoffeeScript source into an internal build directory

Introduce an internal build step that compiles `.coffee` files while preserving module behavior.

Suggested output location:

- `build/internal/`

Work:

- compile top-level `.coffee`
- compile `proofs/`
- compile `dialect_manager/`
- include generated parser `.js` files
- include any required runtime assets

Important constraint:

- do not change source semantics during this step

Expected outcome:

- all historical runtime code exists as normal JavaScript files under a predictable internal build directory

### 4. Bridge internal CommonJS-style runtime to ESM entrypoints

Because the historical code is CommonJS-oriented, the wrapper layer should isolate that complexity.

Work:

- decide whether the compiled internal runtime remains CommonJS-shaped or is transformed during build
- make `src-entry/*.js` the only ESM surface exposed publicly

Acceptance criteria:

- `import { fol } from 'love-logic'` works in Node ESM
- browser-bundler imports work through the same entrypoints

## Phase 3: Define the public API explicitly

### 5. Root entry implementation

Implement `src-entry/index.js` with the approved surface:

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

Acceptance criteria:

- root imports cover all common real-world use cases
- consumers do not need deep imports

### 6. Add `fol.getSymbols(name?)`

This is the one intentional API improvement recommended by the design.

Work:

- add `fol.getSymbols(name?)`
- delegate to the dialect manager

Compatibility policy:

- keep `fol._dialectManager` reachable for now
- do not document it as stable API

Acceptance criteria:

- external code can replace `fol._dialectManager.getSymbols()` with `fol.getSymbols()`

### 7. Proof-focused subpath

Implement `src-entry/proofs.js`.

Exports:

- `proof`
- `parseProof`

Acceptance criteria:

- proof-only consumers can import from `love-logic/proofs`

### 8. Browser ESM entry

Implement `src-entry/browser.js` as a clean re-export of the main browser-safe API.

Acceptance criteria:

- browser bundler consumers can import from `love-logic/browser`
- API matches root entry behavior

## Phase 4: Retain the standalone browser build

### 9. Implement global bundle adapter

Implement `src-entry/browser-global.js`.

Responsibilities:

- import the public API from the wrapper layer
- attach:
  - `window.fol`
  - `window.proof`
  - `window.loveLogic`

Acceptance criteria:

- existing global-style integration remains possible
- bundle consumers get the new `window.loveLogic` namespace as well

### 10. Produce standalone browser artifacts

Generate:

- `dist/browser/love-logic.global.js`
- `dist/browser/love-logic.global.min.js`

Acceptance criteria:

- artifact works in a plain browser page without module support
- globals are present and functional

## Phase 5: Add TypeScript declarations

### 11. Create root declaration file

Create:

- `types/index.d.ts`

Cover:

- `fol`
- `proof`
- `symbols`
- top-level named exports
- dialect-related types
- decorated expression interface
- proof interface

Important design rule:

- keep AST typing conservative
- strongly type behavior and method contracts

### 12. Create proof subpath declaration file

Create:

- `types/proofs.d.ts`

This can reuse root proof-related types or re-export them.

### 13. Create browser declaration file

Create:

- `types/browser.d.ts`

This should match the browser ESM exports.

### 14. Add strong JSDoc inside declaration files

Document:

- mutable global dialect state
- difference between `parse` and `parseUsingSystemParser`
- expression decoration behavior
- proof parse return shape
- browser global compatibility

Acceptance criteria:

- TypeScript consumers get a usable interface
- documentation quality is high enough that the declarations act as API reference material

## Phase 6: Modernize test execution around the package

### 15. Preserve existing source-level tests unchanged

Keep:

- current Mocha setup
- current CoffeeScript-based tests
- current docs and examples scripts

No migration of runner or test rewrite in this phase.

### 16. Add package smoke tests

Create a new small test suite for built artifacts.

Suggested location:

- `test-package/`

Coverage:

- import root ESM entry
- import `love-logic/proofs`
- import `love-logic/browser`
- root API shape
- `fol.parse(...)`
- `fol.parseUsingSystemParser(...)`
- `fol.setDialect(...)`
- `fol.getSymbols(...)`
- `proof.parse(...)`
- decorated expression methods
- decorated proof methods

Acceptance criteria:

- package behavior is verified independently of source-layout assumptions

### 17. Add browser global smoke test

Create one focused test for the standalone bundle.

Coverage:

- `window.fol`
- `window.proof`
- `window.loveLogic`
- simple parse operation

Acceptance criteria:

- the legacy browser distribution is protected against accidental breakage

### 18. Add aggregate developer scripts

Add scripts:

- `npm run build`
- `npm run test:package`
- `npm run test:all`

Suggested meaning:

- `build`: compile internal runtime, build ESM wrappers, emit browser bundles, copy declarations
- `test:package`: run package and browser-artifact smoke tests
- `test:all`: run `test`, `docs:test`, `examples`, `build`, `test:package`

## Phase 7: Documentation updates

### 19. Update README for package usage

Revise the top-level README to explain:

- ESM usage in Node
- ESM usage in browser applications
- standalone browser bundle usage
- testing commands
- high-level API overview

### 20. Document public API boundaries

Document:

- supported imports
- supported globals
- deprecated/internal status of `_dialectManager`
- `fol.getSymbols(...)` as the public replacement

Acceptance criteria:

- consumers can adopt the package without reading internal source files

## Phase 8: Verification and release readiness

### 21. Run the full verification matrix

Before considering the work complete, run:

- `npm test`
- `npm run docs:test`
- `npm run examples`
- `npm run build`
- `npm run test:package`
- `npm run test:all`

### 22. Perform manual import checks

Manually verify:

- Node ESM import of root package
- Node ESM import of `love-logic/proofs`
- browser global bundle in a trivial HTML page or equivalent harness

### 23. Compare browser compatibility against current bundle

Specifically confirm:

- `window.fol` still exists
- `window.proof` still exists
- current usage style remains possible

## Implementation order

Recommended execution order:

1. Fix `package.json` and add public entry wrappers
2. Implement the build pipeline for internal runtime plus ESM entry outputs
3. Add `fol.getSymbols(...)`
4. Build the standalone browser bundle from the wrapper layer
5. Add `.d.ts` files
6. Add package smoke tests
7. Update README and packaging docs
8. Run full verification

## Risk notes

### Main technical risks

- bridging historical CommonJS/CoffeeScript runtime into a clean ESM package
- preserving browser global behavior while changing packaging
- ensuring decorated objects behave identically after the build step

### Mitigations

- keep source code changes minimal
- isolate public packaging logic in wrapper modules
- add package-level tests rather than relying only on source tests
- preserve the current browser-global contract explicitly

## Completion criteria

The work is complete when all of the following are true:

- the package can be imported as ESM from Node
- the package can be imported into browser applications via ESM
- the standalone browser bundle is generated and works
- the supported public API is documented and typed
- the existing source tests still pass
- the new package smoke tests pass

## Immediate next coding task

The first implementation step should be:

- normalize `package.json`
- create the wrapper entry modules
- choose and wire the build pipeline that turns the existing CoffeeScript/CommonJS runtime into the internal build consumed by those wrappers

That is the highest-leverage step because it determines how much source churn the rest of the work will require.
