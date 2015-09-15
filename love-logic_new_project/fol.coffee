# This module ties together a parser (e.g. `parser/awFOL`) with
# methods for performing substitutions and other actions on expressions
# and their components.
#
# The aim is to include everything needed for parsing and verifying proofs,
# for evaluating sentences in worlds and verifying counterexamples, and for
# building truth tables.

_ = require 'lodash'

awFOL = require './parser/awFOL'

util = require './util'
match = require './match'
substitute = require './substitute'

parse = (text) ->
  e = awFOL.parse text
  return _decorate(e)
exports.parse = parse

# Add some useful functions to an expression and every part of it.
_decorate = (expression) ->
  walker = (e) ->
    return if e is null # (Because `null` can occur in substitutions.)
    return if _.isArray(e) or _.isString(e) or _.isBoolean(e) or _.isNumber(e)
    
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
    e.toString = (o) ->
      return util.expressionToString e, o
    e.listMetaVariableNames = () ->
      return util.listMetaVariableNames e
      
    e.findMatches = (pattern, _matches, o) ->
      result = match.find e, pattern, _matches, o
      _decorate(result)
      return result
    e.applyMatches = (matches) ->
      result =  match.apply e, matches
      _decorate(result)
      return result
    e.applySubstitutions = () ->
      result =  substitute.applySubstitutions(e)
      _decorate(result)
      return result
    e.containsSubstitutions = () ->
      _subsFound = false
      subFinder = (expression) ->
        _subsFound = true if expression?.substitutions?
        return undefined
      e.walk subFinder
      return _subsFound
    
    e.getNames = () ->
      _names = []
      nameFinder = (expression) ->
        return undefined unless expression?.type is 'name'
        _names.push expression.name
        return undefined 
      e.walk nameFinder
      return _names

    e.getSentenceLetters = () ->
      _letters = []
      letterFinder = (expression) ->
        return undefined unless expression?.type is 'sentence_letter'
        _letters.push expression.letter
        return undefined 
      e.walk letterFinder
      return _letters.sort()
      
  util.walk expression, walker
  return expression
exports._decorate = _decorate