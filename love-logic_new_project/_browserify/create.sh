#!/bin/sh
browserify -t coffeeify  --extension=".coffee" proof.browserifyme.coffee -o  proof.bundle.js