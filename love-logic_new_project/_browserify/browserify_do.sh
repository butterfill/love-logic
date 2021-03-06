#!/bin/sh
# browserify -t coffeeify  --extension=".coffee" awfol.browserifyme.coffee -o  /Users/stephenbutterfill/Documents/programming/love-logic-server/love-logic-server/client/lib/awfol/awfol.bundle.js

nvm use v0.10.40

browserify -t coffeeify  --extension=".coffee" awfol.browserifyme.coffee -o awfol.bundle.to.compile.js
java -jar compiler.jar --js awfol.bundle.to.compile.js --js_output_file /Users/arcadia/Documents/programming/git/love-logic-server/love-logic-server/client/lib/awfol/awfol.bundle.js

# TO compile with closure compiler:
# java -jar compiler.jar --js awfol.bundle.js --js_output_file awfol.bundle.compiled.js