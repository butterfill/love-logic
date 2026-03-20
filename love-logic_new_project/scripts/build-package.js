const fs = require('fs');
const path = require('path');
const CoffeeScript = require('coffeescript');
const esbuild = require('esbuild');

const rootDir = path.resolve(__dirname, '..');
const buildDir = path.join(rootDir, '.build');
const buildCjsDir = path.join(buildDir, 'cjs');
const distDir = path.join(rootDir, 'dist');

const excludedDirs = new Set([
  '.build',
  'dist',
  'docs',
  'examples',
  'node_modules',
  'scripts',
  'test',
  'test-package',
  '_browserify'
]);

function cleanDir(dirPath) {
  fs.rmSync(dirPath, { recursive: true, force: true });
  fs.mkdirSync(dirPath, { recursive: true });
}

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function walk(dirPath, visitor) {
  for (const entry of fs.readdirSync(dirPath, { withFileTypes: true })) {
    const fullPath = path.join(dirPath, entry.name);
    const relPath = path.relative(rootDir, fullPath);
    if (entry.isDirectory()) {
      if (
        excludedDirs.has(entry.name) ||
        relPath === 'parser/test' ||
        relPath === 'proofs/test'
      ) {
        continue;
      }
      walk(fullPath, visitor);
      continue;
    }
    visitor(fullPath, relPath);
  }
}

function compileCoffeeFile(srcPath, relPath) {
  const source = fs.readFileSync(srcPath, 'utf8');
  const compiled = CoffeeScript.compile(source, {
    bare: true,
    filename: srcPath
  });
  const outRelPath = relPath.replace(/\.coffee$/, '.js');
  const outPath = path.join(buildCjsDir, outRelPath);
  ensureDir(path.dirname(outPath));
  fs.writeFileSync(outPath, compiled);
}

function sanitizeGeneratedParser(source) {
  return source.replace(
    /exports\.main = function commonjsMain\(args\) \{[\s\S]*?if \(typeof module !== 'undefined' && require\.main === module\) \{\s*exports\.main\(process\.argv\.slice\(1\)\);\s*\}\s*/m,
    ''
  );
}

function copyFile(srcPath, relPath, options = {}) {
  const outPath = path.join(buildCjsDir, relPath);
  ensureDir(path.dirname(outPath));
  if (options.sanitizeGeneratedParser) {
    const source = fs.readFileSync(srcPath, 'utf8');
    fs.writeFileSync(outPath, sanitizeGeneratedParser(source));
    return;
  }
  fs.copyFileSync(srcPath, outPath);
}

function buildRuntimeTree() {
  walk(rootDir, (fullPath, relPath) => {
    if (relPath.startsWith('parser' + path.sep) && relPath.endsWith('.js')) {
      copyFile(fullPath, relPath, { sanitizeGeneratedParser: true });
      return;
    }
    if (relPath === path.join('proofs', 'justification_parser.js')) {
      copyFile(fullPath, relPath, { sanitizeGeneratedParser: true });
      return;
    }
    if (relPath.endsWith('.coffee')) {
      compileCoffeeFile(fullPath, relPath);
    }
  });
}

async function bundleEntry(entryPoint, outfile, options = {}) {
  await esbuild.build({
    entryPoints: [entryPoint],
    outfile,
    bundle: true,
    format: options.format || 'esm',
    platform: options.platform || 'neutral',
    target: options.target || ['es2020'],
    minify: options.minify || false,
    sourcemap: false,
    logLevel: 'info'
  });
}

function copyTypes() {
  const typeFiles = [
    'index.d.ts',
    'proofs.d.ts',
    'browser.d.ts'
  ];
  for (const filename of typeFiles) {
    const srcPath = path.join(rootDir, 'types', filename);
    const outPath = path.join(distDir, filename);
    ensureDir(path.dirname(outPath));
    fs.copyFileSync(srcPath, outPath);
  }
}

async function main() {
  cleanDir(buildDir);
  cleanDir(distDir);
  buildRuntimeTree();

  ensureDir(path.join(distDir, 'browser'));

  await bundleEntry(
    path.join(rootDir, 'src-entry', 'index.js'),
    path.join(distDir, 'index.mjs')
  );
  await bundleEntry(
    path.join(rootDir, 'src-entry', 'proofs.js'),
    path.join(distDir, 'proofs.mjs')
  );
  await bundleEntry(
    path.join(rootDir, 'src-entry', 'browser.js'),
    path.join(distDir, 'browser.mjs')
  );
  await bundleEntry(
    path.join(rootDir, 'src-entry', 'browser-global.js'),
    path.join(distDir, 'browser', 'love-logic.global.js'),
    {
      format: 'iife',
      platform: 'browser',
      target: ['es2018']
    }
  );
  await bundleEntry(
    path.join(rootDir, 'src-entry', 'browser-global.js'),
    path.join(distDir, 'browser', 'love-logic.global.min.js'),
    {
      format: 'iife',
      platform: 'browser',
      target: ['es2018'],
      minify: true
    }
  );

  copyTypes();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
