#!/usr/bin/env node
/*
 Simple docs validator: executes fenced code blocks labeled as
 ```coffee doctest
 ...
 ```
 in all Markdown files under the docs directory, using CoffeeScript via Node's loader.

 Validation rule: blocks must execute without throwing.
*/

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const DOCS_DIR = path.join(__dirname, '..', 'docs');
const TMP_PREFIX = 'tmp_rovodev_doctest_';

function findMarkdownFiles(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const files = [];
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) files.push(...findMarkdownFiles(full));
    else if (e.isFile() && e.name.endsWith('.md')) files.push(full);
  }
  return files;
}

function extractDoctestBlocks(md) {
  // Supports optional inline assertions using lines ending with: #=> expected text
  // We treat comments as expectation markers and compare to actual console output.

  const blocks = [];
  const fence = /```coffee\s+doctest\n([\s\S]*?)\n```/g;
  let m;
  while ((m = fence.exec(md)) !== null) {
    blocks.push(m[1]);
  }
  return blocks;
}

function runBlock(code, idx, contextLabel) {
  // Split out expected assertions (#=> ...).
  const lines = code.split(/\r?\n/);
  const expected = [];
  const actualLines = [];
  for (const line of lines) {
    const m = line.match(/^(.*)\s+#=>\s*(.*)$/);
    if (m) {
      // m[1] is code (ignored), m[2] is expected text to appear in output
      expected.push(m[2].trim());
      // do not include assertion comment in executed code
      actualLines.push(m[1]);
    } else {
      actualLines.push(line);
    }
  }
  const adjustedCode = actualLines.join('\n');

  const tmpFile = path.join(__dirname, '..', `${TMP_PREFIX}${idx}.coffee`);
  fs.writeFileSync(tmpFile, adjustedCode, 'utf8');
  const result = spawnSync(process.execPath, ['-r', 'coffeescript/register', tmpFile], {
    stdio: ['ignore', 'pipe', 'pipe'],
    env: process.env,
    encoding: 'utf8'
  });
  const stdout = result.stdout || '';
  const stderr = result.stderr || '';
  try { fs.unlinkSync(tmpFile); } catch (_) {}
  if (result.status !== 0) {
    process.stderr.write(stdout + stderr);
    throw new Error(`Doctest failed (exit ${result.status}).`);
  }
  // Validate expected substrings in output if provided
  for (const exp of expected) {
    if (!stdout.includes(exp)) {
      throw new Error(`Expected output not found: ${exp}\nIn: ${contextLabel}\nActual:\n${stdout}`);
    }
  }
}

function main() {
  const files = findMarkdownFiles(DOCS_DIR);
  let count = 0;
  for (const file of files) {
    const md = fs.readFileSync(file, 'utf8');
    const blocks = extractDoctestBlocks(md);
    blocks.forEach((code, i) => {
      runBlock(code, `${path.basename(file)}_${i}`, file);
      count += 1;
    });
  }
  console.log(`Docs validation passed. Executed ${count} doctest block(s).`);
}

main();
