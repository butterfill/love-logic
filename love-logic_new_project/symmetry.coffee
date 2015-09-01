# TODO Should this be called 'prenex normal form'?

util = require './util'

# Sort the conjuncts and disjuncts in an expression in PNF.
sortPNFExpression = (expression) ->
  theQuantifiers = getPrefixedQuantifiers expression
  core = removeQuantifiers expression
  conjuncts = listJuncts core, 'and'
  nestedDisjuncts = ( listJuncts(junct, 'or') for junct in conjuncts)
  for junctList in nestedDisjuncts
    sortJuncts junctList
  sortListOfJuncts nestedDisjuncts
  rebuiltConjuncts = []
  for junctList in nestedDisjuncts
    rebuiltConjuncts.push rebuildExpression(junctList, 'or')
  rebuiltCore = rebuildExpression rebuiltConjuncts, 'and'
  return attachExpressionToQuantifiers rebuiltCore, theQuantifiers
exports.sortPNFExpression = sortPNFExpression


# Find the sub-expression of `expression` which starts after any leading quantifiers.
# (Does not modify or clone `expression`.)
removeQuantifiers = (expression) ->
  if expression.boundVariable?
    return removeQuantifiers expression.left
  return expression
exports.removeQuantifiers = removeQuantifiers
  


# Given an `expression` like "P and (Q and (R or (P1 and P2)))" and `type` "and",
# returns ["P", "Q", "(R or (P1 and P2)"], i.e. a list of juncts.
# Parameter `type` can be 'and', 'or' or any type which has `.left` and `.right` properties
# (but it only makes sense for symmetric things, so wouldn't make sense for 'arrow').
# If `expression.type` isnt `type`, it will return a list containing just `expression`.
listJuncts = (expression, type) ->
  if expression.type? and expression.type isnt type
    return [expression]
  if expression.type? and expression.type is type
    _juncts = []
    # note: push takes multiple arguments and the '...' operator turns a list into arguments
    _juncts.push listJuncts(expression.left, type)...
    _juncts.push listJuncts(expression.right, type)...
    return _juncts
  throw new Error "listJuncts called with type = #{type} and unrecognized expression = #{JSON.stringify expression,null,4}"
  
exports.listJuncts = listJuncts


# Sort a list of juncts into a standard order.
# This only works where the juncts are atomic expressions.
# (It's used in comparing expressions in PNF.)
sortJuncts = (listOfJuncts) ->
  return listOfJuncts.sort(util.atomicExpressionComparator)
exports.sortJuncts = sortJuncts

# Sort a list of lists of juncts into a standard order.
# This only works where the juncts are atomic expressions.
# (It's used in comparing expressions in PNF.)
sortListOfJuncts = (listOfListOfJuncts) ->
  return listOfListOfJuncts.sort(util.listOfAtomicExpressionsComparator)
exports.sortListOfJuncts = sortListOfJuncts


# Takes a list of juncts and rebuilds them into a 
# conjunction or whatever is specified by `type` (e.g. 'or' for building a disjunction).
rebuildExpression = (listOfJuncts, type) ->
  if listOfJuncts.length is 1
    return listOfJuncts[0]
  head = listOfJuncts.shift()
  tail = listOfJuncts
  right = rebuildExpression(tail)
  return {type:type, left:head, right:right}
exports.rebuildExpression = rebuildExpression


# `expression` starts with zero or more quantifiers of type `type` (e.g. 'existential_quantifier').
# This function returns an object containing (i) `quantifiedExpression`, the expression after 
# the initial quantifiers of `type`, and (ii) `boundVariables`, a list of variables bound by
# those quantifiers.
# TODO: Why is this useful?
listQuants = (expression, type) ->
  if expression.type? and expression.type isnt type
    return {quantifiedExpression: expression}
  if expression.type? and expression.type is type
    result = listQuants expression.left, type
    result.boundVariables ?=  []
    result.boundVariables.push expression.boundVariable
    return result
  throw new Error "listQuants called with type = #{type} and unrecognized expression = #{JSON.stringify expression,null,4}"
exports.listQuants = listQuants


# Returns a new expression containing just a clone of the sequence of quantifiers
# which occur at the start of expression (if any), or `null` if there are none.
# (Does not modify `expression`.)
getPrefixedQuantifiers = (expression) ->
  theRest = null
  if expression.boundVariable?
    quantifier = expression
    theRest = getPrefixedQuantifiers quantifier.left
    # build a fake quantifier
    return  {type:quantifier.type, symbol:quantifier.symbol, location:quantifier.location, boundVariable:quantifier.boundVariable, left:theRest, right:null}; 
  else
    return null
exports.getPrefixedQuantifiers = getPrefixedQuantifiers  


# `quantifiers` is a pseudo-expression containing some quantifiers.
# `expression` is a yaFOL expression.
# It modifies `quantifiers` in place, attaching expression the end of them.
attachExpressionToQuantifiers = (expression, quantifiers) ->
  if quantifiers.left isnt null
    attachExpressionToQuantifiers(expression, quantifiers.left) 
  else
    quantifiers.left = expression
  return quantifiers
exports.attachExpressionToQuantifiers = attachExpressionToQuantifiers






