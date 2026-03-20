import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import vm from 'node:vm';

const rootDir = path.resolve(process.cwd());

test('browser global bundle attaches love-logic globals', () => {
  const bundlePath = path.join(rootDir, 'dist', 'browser', 'love-logic.global.js');
  const source = fs.readFileSync(bundlePath, 'utf8');
  const sandbox = {
    console
  };
  sandbox.window = sandbox;
  sandbox.globalThis = sandbox;
  vm.runInNewContext(source, sandbox, { filename: bundlePath });

  assert.equal(typeof sandbox.window.fol.parse, 'function');
  assert.equal(typeof sandbox.window.proof.parse, 'function');
  assert.equal(typeof sandbox.window.loveLogic.parse, 'function');

  const expr = sandbox.window.fol.parse('A and B');
  assert.equal(expr.toString({ replaceSymbols: false }), 'A and B');
});
