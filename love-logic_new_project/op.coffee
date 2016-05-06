# operations : e.g. negate a sentence

_ = require 'lodash'

dialectManager = require('./dialect_manager/dialectManager')
parser = dialectManager.getParser('awFOL')
  
negate = (e) ->
  res = parser.parse 'not A'
  res.left = e
  return res
exports.negate = negate

conjoin = (left, right) ->
  res = parser.parse 'A and B'
  res.left = left
  res.right = right
  return res
exports.conjoin = conjoin