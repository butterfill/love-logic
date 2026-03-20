const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '..');

for (const dirName of ['.build', 'dist']) {
  fs.rmSync(path.join(rootDir, dirName), { recursive: true, force: true });
}
