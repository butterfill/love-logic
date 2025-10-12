#!/usr/bin/env node
/*
Run all CoffeeScript example scripts under examples/ with coffeescript/register.
*/

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const EX_DIR = path.join(__dirname, '..', 'examples');

function findCoffeeFiles(dir) {
  return fs
    .readdirSync(dir)
    .filter((f) => f.endsWith('.coffee'))
    .map((f) => path.join(dir, f));
}

function run(file) {
  console.log(`\n--- Running example: ${path.basename(file)} ---`);
  const result = spawnSync(process.execPath, ['-r', 'coffeescript/register', file], {
    stdio: 'inherit',
    env: process.env,
  });
  if (result.status !== 0) {
    throw new Error(`Example failed: ${file}`);
  }
}

function main() {
  if (!fs.existsSync(EX_DIR)) {
    console.log('No examples directory found.');
    return;
  }
  const files = findCoffeeFiles(EX_DIR);
  files.forEach(run);
  console.log(`\nAll ${files.length} example(s) completed.`);
}

main();
