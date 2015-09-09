# This module ties together a parser (e.g. `parser/awFOL`) with
# methods for performing substitutions and other actions on expressions
# and their components.

_ = require 'lodash'

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
    return if e is null # (Because `null` can occur in substitutions.)
    return if _.isArray e
    
    e.walk = (fn) ->
      util.walk e, fn
      return e
    e.delExtraneousProperties = () ->
      # Note: this will remove all `_decoration`s and break the chain.
      util.delExtraneousProperties e
    e.isIdenticalTo = (otherExpression) ->
      return util.areIdenticalExpressions e, otherExpression
    e.clone = () ->
      theClone = util.cloneExpression e
      _decorate theClone
      return theClone
    e.toString = () ->
      return util.expressionToString e
    e.listMetaVariableNames = () ->
      return util.listMetaVariableNames e
      
    e.findMatches = (pattern, _matches, o) ->
      result = substitute.findMatches e, pattern, _matches, o
      _decorate(result)
      return result
    e.applyMatches = (matches) ->
      result =  substitute.applyMatches e, matches
      _decorate(result)
      return result
    e.applySubstitutions = () ->
      result =  substitute.applySubstitutions(e)
      _decorate(result)
      return result
    
    e.getNames = () ->
      _names = []
      nameFinder = (expression) ->
        return undefined unless expression?.type is 'name'
        _names.push expression.name
        return undefined 
      e.walk nameFinder
      return _names
  return expression
exports._decorate = _decorate