fol = require('../fol')
proof = require('../proofs/proof')
tree = require('../../ui_components/tree_proof/tree')

global.fol = fol
global.proof = proof
global.tree = tree

# browserify auto exports _ to window._ in browser contexts
# (see https://github.com/lodash/lodash/issues/1798).
# We need to prevent that to avoid errors.
# UPDATE : actually it seems that the love-logic-server depends on lodash being exported here
# TODO : investigate further!
# _?.noConflict()
