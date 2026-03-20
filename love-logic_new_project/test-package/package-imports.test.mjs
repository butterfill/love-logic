import assert from 'node:assert/strict';
import test from 'node:test';

test('root package self-reference exposes the ESM API', async () => {
  const pkg = await import('love-logic');
  assert.equal(typeof pkg.fol.parse, 'function');
  assert.equal(typeof pkg.proof.parse, 'function');
  assert.equal(typeof pkg.parse, 'function');
  assert.equal(typeof pkg.parseProof, 'function');
  assert.equal(typeof pkg.symbols.default.and, 'string');
});

test('proof and browser subpath self-references resolve', async () => {
  const proofsPkg = await import('love-logic/proofs');
  const browserPkg = await import('love-logic/browser');
  assert.equal(typeof proofsPkg.proof.parse, 'function');
  assert.equal(typeof proofsPkg.parseProof, 'function');
  assert.equal(typeof browserPkg.fol.parse, 'function');
});

test('built package keeps the main fol and proof behavior', async () => {
  const pkg = await import('love-logic');
  pkg.setDialect('lpl');

  const expr = pkg.parse('A and B');
  assert.equal(expr.toString({ replaceSymbols: false }), 'A and B');
  assert.deepEqual(expr.getSentenceLetters(), ['A', 'B']);
  assert.equal(pkg.fol.getSymbols().and, '∧');

  const parsedProof = pkg.parseProof('1. A\n2. A and A');
  assert.equal(typeof parsedProof, 'object');
  assert.equal(typeof parsedProof.verify, 'function');
});
