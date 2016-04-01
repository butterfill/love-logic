# This module ties together a parser (e.g. `parser/awFOL`) with
# methods for performing substitutions and other actions on expressions
# and their components.
#
# The aim is to include everything needed for parsing and verifying proofs,
# for evaluating sentences in worlds and verifying counterexamples, and for
# building truth tables.

_ = require 'lodash'

util = require './util'
match = require './match'
substitute = require './substitute'
normalForm = require './normal_form'
evaluate = require('./evaluate')
symbols = require('./symbols')
dialectManager = require('./dialect_manager/dialectManager')
  
parse = (text, parser) ->
  parser ?= dialectManager.getCurrentParser()
  e = parser.parse text
  return _decorate(e)
exports.parse = parse

exports.symbols = symbols



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
      return util.areIdenticalExpressions(e, otherExpression)
    e.clone = () ->
      theClone = util.cloneExpression e
      _decorate theClone
      return theClone
    e.toString = (o) ->
      o ?= {}
      unless o.replaceSymbols is false
        o.symbols ?= dialectManager.getSymbols()
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
    
    # Get all names in the expression
    e.getNames = () ->
      _names = []
      nameFinder = (expression) ->
        return undefined unless expression?.type is 'name'
        _names.push expression.name
        return undefined 
      e.walk nameFinder
      return _names

    e.getPredicates = () ->
      _predicates = []
      predicateFinder = (expression) ->
        return undefined unless expression?.type is 'predicate'
        _predicates.push {name:expression.name, arity:expression.termlist.length}
        return undefined 
      e.walk predicateFinder
      eq = (p1) -> "#{p1.name}*&!#{p1.arity}"
      return _.uniq( _predicates, eq )
        

    # Get all sentence letters in the expression
    e.getSentenceLetters = () ->
      _letters = []
      letterFinder = (expression) ->
        return undefined unless expression?.type is 'sentence_letter'
        _letters.push expression.letter
        return undefined 
      e.walk letterFinder
      return _letters.sort()
    
    # Return the names of any variables not bound by a quantifier
    e.getFreeVariableNames = () ->
      allTerms = util.listTerms(e)
      allVariableNames = _.uniq( (t.name for t in allTerms when t.type is 'variable') )
      unboundVariables = (v for v in allVariableNames when normalForm.isVariableFree(v, expression))
      return unboundVariables

      
    e.convertToPNFsimplifyAndSort = () ->
      newE = normalForm.convertToPNFsimplifyAndSort(expression)
      _decorate(newE)
      return newE
    
    e.isPNFExpressionEquivalent = (other) ->
      return normalForm.arePNFExpressionsEquivalent(e, other)
    
    e.evaluate = (world) ->
      return evaluate.evaluate(e, world)
      
    
  util.walk expression, walker
  return expression
exports._decorate = _decorate