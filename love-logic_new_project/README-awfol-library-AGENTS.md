# README awfol Library for Agents

This document is for coding agents that need to use `@butterfill/awfol` correctly and efficiently.

It describes the supported package surface, the runtime model, the main gotchas, and the shortest path to solving common tasks.

## What this library is

`@butterfill/awfol` is a logic library for:

- parsing first-order logic sentences
- evaluating sentences against worlds
- converting expressions to prenex normal form
- matching and substituting logical forms
- parsing and verifying Fitch-style proofs

The package exposes:

- a main `fol` API
- a main `proof` API
- static symbol tables via `symbols`

## Package names and entrypoints

Primary package:

- `@butterfill/awfol`

Subpaths:

- `@butterfill/awfol/proofs`
- `@butterfill/awfol/browser`

Standalone browser artifact:

- `dist/browser/love-logic.global.js`
- `dist/browser/love-logic.global.min.js`

## How to import it

Normal ESM use:

```js
import { fol, proof, symbols } from '@butterfill/awfol';
```

Convenience named exports:

```js
import {
  parse,
  parseUsingSystemParser,
  setDialect,
  parseProof
} from '@butterfill/awfol';
```

Proof-focused import:

```js
import { proof, parseProof } from '@butterfill/awfol/proofs';
```

For local package testing before publishing:

```js
import { fol, proof } from './dist/index.mjs';
```

## Mental model

The library has two important entrypoints:

- `fol` for expressions and dialect management
- `proof` for proof parsing and proof verification

The crucial runtime fact is that `fol.parse(...)` returns a decorated expression object, not just a plain AST. Those decorated expressions have methods like:

- `.toString()`
- `.evaluate()`
- `.getNames()`
- `.getPredicates()`
- `.getFreeVariableNames()`
- `.convertToPNFsimplifyAndSort()`

Similarly, `proof.parse(...)` returns either:

- a decorated proof object on success
- a string error message on parse failure

## Global dialect state

The dialect is global mutable state.

This affects:

- how parsing works
- how expressions stringify
- which proof rules are active

Set it explicitly before doing work that depends on syntax or proof rules:

```js
fol.setDialect('lpl');
```

If you do not set the dialect, the default is `lpl`.

### Consequence for agents

Do not assume calls are independent if your code changes the dialect midway through a task. If a workflow mixes dialect-sensitive operations, set the dialect immediately before the operation that needs it.

Good pattern:

```js
fol.setDialect('forallx');
const expr = fol.parse('Fa');
```

## The supported public API

## `fol`

Main methods:

- `fol.parse(text, parser?)`
- `fol.parseUsingSystemParser(text)`
- `fol.setDialect(name, version?)`
- `fol.getCurrentDialectNameAndVersion()`
- `fol.getAllDialectNamesAndDescriptions()`
- `fol.getTextbookForDialect(name?)`
- `fol.getLanguageNames()`
- `fol.getPredLanguageName()`
- `fol.getSymbols(name?)`
- `fol.symbols`

### `fol.parse(text, parser?)`

Use when you want parsing under the current dialect.

Behavior:

- returns a decorated expression object
- throws on parse failure

### `fol.parseUsingSystemParser(text)`

Use when you need to parse using the built-in system parser regardless of the current dialect.

Behavior:

- returns a decorated expression object
- throws on parse failure

This is useful when converting canonical exercise data into the currently selected dialect.

### `fol.getSymbols(name?)`

Use this instead of reaching into dialect manager internals.

This is public:

- `fol.getSymbols()`
- `fol.getSymbols('default')`

Avoid using:

- `fol._dialectManager`

`_dialectManager` still exists for compatibility, but it is internal and should not be the first choice in new code.

## Decorated expressions returned by `fol.parse(...)`

Methods agents are most likely to need:

- `expr.toString(options?)`
- `expr.evaluate(world)`
- `expr.getNames()`
- `expr.getPredicates()`
- `expr.getSentenceLetters()`
- `expr.getFreeVariableNames()`
- `expr.clone()`
- `expr.negate()`
- `expr.convertToPNFsimplifyAndSort()`
- `expr.findMatches(pattern, matches?, options?)`
- `expr.applyMatches(matches)`
- `expr.applySubstitutions()`
- `expr.getAllSubstitutionInstances()`

### `expr.toString(options?)`

Common usage:

```js
expr.toString({ replaceSymbols: true });
expr.toString({ replaceSymbols: false });
expr.toString({ replaceSymbols: true, symbols: fol.symbols.default });
```

### `expr.evaluate(world)`

Evaluates an expression against a world object.

Expected world shape:

```js
const world = {
  domain: ['a', 'b'],
  names: { a: 'a', b: 'b' },
  predicates: {
    F: [['a']],
    R: [['a', 'b']]
  }
};
```

Notes:

- the library expects `names` and `predicates`
- predicate extensions are arrays of tuples
- it throws for undefined names or unbound variables

### `expr.getPredicates()`

Returns objects like:

```js
[{ name: 'F', arity: 1 }]
```

### `expr.convertToPNFsimplifyAndSort()`

This is the main public way to canonicalize expressions for comparison-style workflows.

Typical pattern:

```js
const normalized = expr.convertToPNFsimplifyAndSort().toString({ replaceSymbols: true });
```

## `proof`

Main method:

- `proof.parse(text, options?)`

Behavior:

- returns a proof object on success
- returns a string error message if parsing fails

This is different from `fol.parse(...)`, which throws on failure.

### Proof objects

Common methods:

- `theProof.verify()`
- `theProof.listErrorMessages()`
- `theProof.getLine(lineNumber)`
- `theProof.toString(options?)`
- `theProof.clone(options?)`
- `theProof.detachChildren()`

Typical safe pattern:

```js
const parsed = proof.parse(proofText);
if (typeof parsed === 'string') {
  // parse error
} else {
  const ok = parsed.verify();
  const errors = ok ? '' : parsed.listErrorMessages();
}
```

### `theProof.getLine(lineNumber)`

Returns a line object with methods like:

- `line.verify()`

And status-like data:

- `line.status`
- `line.number`
- `line.sentence`

## `symbols`

`symbols` is a collection of symbol tables:

- `symbols.default`
- `symbols.teller`
- `symbols.forallx`
- `symbols.logicbook`
- `symbols.copi`

Useful when you need deterministic stringification independent of current dialect:

```js
expr.toString({ replaceSymbols: true, symbols: symbols.default });
```

## Error behavior summary

This matters because the library is not uniform across modules.

### `fol.parse(...)`

- throws on parse error

### `fol.parseUsingSystemParser(...)`

- throws on parse error

### `proof.parse(...)`

- returns a string on parse error
- does not throw for ordinary proof-parse failure

### `expr.evaluate(world)`

- may throw if the world is malformed for the expression

## Best practices for agents

## 1. Set the dialect explicitly

Especially before:

- parsing user input
- parsing proofs
- stringifying for user display

## 2. Normalize only when you actually need normalization

If you just need display, use:

- `expr.toString(...)`

If you need canonicalized logical comparison, use:

- `expr.convertToPNFsimplifyAndSort()`

## 3. Treat decorated expressions as the API

Do not build new code around deep AST internals unless there is no public method that does the job.

Good:

- `expr.getNames()`
- `expr.getPredicates()`
- `expr.evaluate(world)`

Avoid if possible:

- direct structural assumptions about every AST node type

## 4. Handle proof parse failures differently from sentence parse failures

Use `try/catch` for `fol.parse(...)`.

Use `typeof result === 'string'` for `proof.parse(...)`.

## 5. Do not rely on undocumented internals

Avoid:

- `fol._dialectManager`
- deep imports into source files
- internal modules like `util`, `match`, `normal_form`, `op`

The supported surface is the package exports.

## Common tasks

## Parse and display a sentence

```js
import { fol } from '@butterfill/awfol';

fol.setDialect('lpl');
const expr = fol.parse('A and B');
console.log(expr.toString({ replaceSymbols: true }));
```

## Parse canonical syntax and display in current dialect

```js
import { fol } from '@butterfill/awfol';

const expr = fol.parseUsingSystemParser('all x F(x)');
fol.setDialect('forallx');
console.log(expr.toString({ replaceSymbols: true }));
```

## Evaluate a sentence in a world

```js
import { fol } from '@butterfill/awfol';

const expr = fol.parse('F(a)');
const world = {
  domain: ['obj1'],
  names: { a: 'obj1' },
  predicates: { F: [['obj1']] }
};
console.log(expr.evaluate(world));
```

## Check for free variables

```js
const expr = fol.parse('F(x) and G(a)');
const free = expr.getFreeVariableNames();
```

## Canonicalize an answer

```js
const normalized = fol
  .parse(answer)
  .convertToPNFsimplifyAndSort()
  .toString({ replaceSymbols: true });
```

## Parse and verify a proof

```js
import { fol, proof } from '@butterfill/awfol';

fol.setDialect('lpl');
const parsed = proof.parse(proofText);

if (typeof parsed === 'string') {
  console.log('Parse error:', parsed);
} else {
  const ok = parsed.verify();
  console.log(ok ? 'valid' : parsed.listErrorMessages());
}
```

## Browser use

ESM in browser app:

```js
import { fol } from '@butterfill/awfol/browser';
```

Legacy browser global bundle:

```html
<script src="/path/to/love-logic.global.min.js"></script>
<script>
  fol.setDialect('lpl');
  const expr = fol.parse('A and B');
</script>
```

Globals provided:

- `window.fol`
- `window.proof`
- `window.symbols`
- `window.loveLogic`

## Install and publish notes

Private GitHub Packages registry:

- package name: `@butterfill/awfol`
- registry: `https://npm.pkg.github.com`

Typical install setup in `.npmrc`:

```ini
@butterfill:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=YOUR_GITHUB_PAT
```

Install:

```bash
npm install @butterfill/awfol
```

Publish from this repo:

```bash
npm run test:all
npm publish
```

## Development and verification commands

From `love-logic_new_project/`:

- `npm test`
- `npm run docs:test`
- `npm run examples`
- `npm run build`
- `npm run test:package`
- `npm run test:all`

If an agent changes packaging, entrypoints, or browser outputs, it should run at least:

- `npm run test:package`

If an agent changes runtime behavior, it should run:

- `npm run test:all`

## Important limitations

- The source remains CoffeeScript-based internally.
- The public package API is ESM.
- The browser global bundle is supported, but it is a secondary artifact.
- Some internal modules exist for historical reasons; they are not the preferred integration surface.
- License terms should be checked before wider redistribution.

## Short checklist for agents

Before writing code that uses this library:

1. Import from `@butterfill/awfol`, not deep source files.
2. Set the dialect explicitly if syntax or proof rules matter.
3. Use `try/catch` for `fol.parse(...)`.
4. Use string-check handling for `proof.parse(...)`.
5. Prefer decorated-expression methods over AST internals.
6. Use `fol.getSymbols(...)`, not `fol._dialectManager`.
7. Keep `dist/` usage in mind for local package testing.
