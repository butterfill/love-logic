# This module ties together a parser (e.g. `parser/awFOL`) with
# methods for performing substitutions and other actions on expressions
# and their components.

awFOL = require './parser/awFOL'

util = require './util'
substitute = require './substitute'

parse = (text) ->
  e = awFOL.parse text
  return _decorate(e)
exports.parse = parse

# Add some useful functions to an expression.
_decorate = (expression) ->
  util.walk expression, (e) ->
    e.walk = (fn) ->
      util.walk e, fn
    e.delExtraneousProperties = () ->
      util.delExtraneousProperties e
    e.isIdenticalTo = (otherExpression) ->
      return util.areIdenticalExpressions e, otherExpression
    e.clone = () ->
      util.cloneExpression e
    e.toString = () ->
      util.expressionToString e
    e.matches = (pattern, _matches, o) ->
      return substitute.findMatches e, pattern, _matches, o
    
  return expression
