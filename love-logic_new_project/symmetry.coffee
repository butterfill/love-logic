# TODO Should this be called 'normal form' or something?

_ = require 'lodash'

util = require './util'
substitute = require './substitute'

areExpressionsEquivalent = (left, right) ->
  left = substitute.prenexNormalForm left
  right = substitute.prenexNormalForm right
  return arePNFExpressionsEquivalent left, right
exports.areExpressionsEquivalent = areExpressionsEquivalent


arePNFExpressionsEquivalent = (left, right) ->
  left =  eliminateRedundancyInPNF(left)
  # Strictly speaking, we don't need to sort as `eliminateRedundancyInPNF` currently does so anyway.
  # But it's essential that we are sorted, so I'll do it anyway.
  left = sortPNFExpression(left)
  sortIdentityStatements(left)
  right = eliminateRedundancyInPNF(right)
  right = sortPNFExpression(right)
  # console.log "left = #{util.expressionToString left}"
  # console.log "right = #{util.expressionToString right}"
  sortIdentityStatements(right)
  pattern = substitute.renameVariables left, 'τ'
  patternCore = removeQuantifiers pattern
  rightCore = removeQuantifiers right

  # Note: the commented-out parameters in the call to `substitute.findMatches`
  # enables matches to be found irrespective of the order of terms in identity statements.
  # This is now necessary because we sort identity statements (using `sortIdentityStatements`).
  matches = substitute.findMatches rightCore, patternCore #, null, {symmetricIdentity:true}
  return false if matches is false
  
  # From this point on, we know that the cores (expressions minus quantifiers)
  # match.  The question is just whether the quantifiers match.
  modifiedLeft = substitute.applyMatches pattern, matches
  
  # There's a potential catch.  If there were quantifiers that dont bind anything,
  # there could be unmatched term_metavariables in `modifiedLeft`.
  # But since we did `removeQuantifiersThatBindNothing` (as part of `eliminateRedundancyInPNF`),
  # this possibility will not arise here.
  # console.log "arePNFExpressionsEquivalent modifiedLeft = #{util.expressionToString modifiedLeft}"
  # console.log "arePNFExpressionsEquivalent right = #{util.expressionToString right}"
  
  return arePrefixedQuantifiersEquivalent modifiedLeft, right
exports.arePNFExpressionsEquivalent = arePNFExpressionsEquivalent

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
  if not listOfJuncts or not  listOfJuncts.length? or listOfJuncts.length is 0
    throw new Error "rebuildExpression called with listOfJuncts = #{listOfJuncts}"
    
  if listOfJuncts.length is 1
    return listOfJuncts[0]
  
  head = listOfJuncts.shift()
  tail = listOfJuncts
  right = rebuildExpression(tail, type)
  return {type:type, left:head, right:right}
exports.rebuildExpression = rebuildExpression


# `expression` starts with zero or more quantifiers of type `type` (e.g. 'existential_quantifier').
# This function returns an object containing (i) `quantifiedExpression`, the expression after 
# the initial quantifiers of `type`, and (ii) `boundVariables`, a list of variables bound by
# those quantifiers.
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
  if quantifiers is null
    return expression
  if quantifiers.left isnt null
    attachExpressionToQuantifiers(expression, quantifiers.left) 
  else
    quantifiers.left = expression
  return quantifiers
exports.attachExpressionToQuantifiers = attachExpressionToQuantifiers


# Returns true for 
#   `arePrefixedQuantifiersEquivalent fol.parse("all x all y P"), fol.parse("all y all x Q")`
# Returns false for 
#   `arePrefixedQuantifiersEquivalent fol.parse("all x exists y P"), fol.parse("all y exists x Q")`
#
arePrefixedQuantifiersEquivalent = (left, right, _inProgress) ->
  _inProgress ?= 
    quantifierType : null
    leftBoundVariables : []
    rightBoundVariables : []
  
  quantifierType = left?.type or null
  
  if _inProgress.quantifierType isnt quantifierType
    # New type of quantifier or end of sequence. 
    # First check that the boundVariables we collected previously match.
    _inProgress.leftBoundVariables.sort()
    _inProgress.rightBoundVariables.sort()
    # console.log "_inProgress.leftBoundVariables #{_inProgress.leftBoundVariables}"
    return false unless _.isEqual(_inProgress.leftBoundVariables, _inProgress.rightBoundVariables)
    # Everything matches so far: reset the list of bounded variables for the next quantifier sequence.
    _inProgress.leftBoundVariables = []
    _inProgress.rightBoundVariables = []
    _inProgress.quantifierType = quantifierType

  # `left` or `right` can be null when we reach the end of a sequence of quantifiers.
  if left is null
    return true if right is null 
    return true if (not right.boundVariable?) #I.e. if `right` isn't a quantifier.
    return false

  # Test whether expression1 is a quantifier: only quantifiers have `.boundVariable` properties.
  if not left.boundVariable?
    # The number of quantifiers must match.
    return true if right is null  #Right isn't a quantifier either.
    return true if (not right.boundVariable?) #I.e. if `right` isn't a quantifier either.
    return false
  
  # From here on, we know that left is a quantifier.
  
  # The sequence of quantifier types must match.
  return false if right is null
  return false if not right.type? 
  return false if right.type isnt quantifierType
  
  _inProgress.leftBoundVariables.push(left.boundVariable.name)
  _inProgress.rightBoundVariables.push(right.boundVariable.name)
  return arePrefixedQuantifiersEquivalent left.left, right.left, _inProgress
exports.arePrefixedQuantifiersEquivalent = arePrefixedQuantifiersEquivalent

# `expression` must be in PNF.
# `expression` will be modified in place.
# Provides a canonical sorting  for identity statements.
# This helps with finding equivalent expressions.
# For identity statements containing two variables,
# the order in which the variables appear depends on the order of the quantifiers.
# So `exists y all x x=y` will become `exists y all x y=x` because y is first.
# Note: param `_variableOrder` should not normally be given (used for recursion).
sortIdentityStatements = (expression, _variableOrder) ->
  if _variableOrder is undefined
    _variableOrder = _getVariableOrder(expression)
  return expression unless expression?.type?
  
  if expression.type isnt 'identity'
    if expression.left?
      sortIdentityStatements expression.left, _variableOrder
    if expression.right?
      sortIdentityStatements expression.right, _variableOrder
    return expression
  
  identity = expression
  left = expression.termlist[0]
  right = expression.termlist[1]
  
  # First, deal with two names or one name and a variable.
  if util.termComparator(left, right) is 1
     #swap left and right
    [left, right] = [right, left]
    
  # Now deal with two variables.
  if left.type is 'variable' and right.type is 'variable'
    leftRank = _variableOrder.indexOf(left.name)
    rightRank = _variableOrder.indexOf(right.name)
    if leftRank > rightRank
      [left, right] = [right, left]
      
  expression.termlist = [left, right]
  return expression
exports.sortIdentityStatements = sortIdentityStatements  
  
# Returns a list of the names of variables bound by quantifiers where `expression` 
# is in PNF.
# The variables are ordered in such a way that alternation between different 
# types of quantifier (existential and universal) is preserved; but variables
# bound by a sequence of quantifiers of the same type are sorted by name.
# This is used by `sortIdentityStatements` to determine which variable to put first
# in identity statements like x=y.
_getVariableOrder = (expression, _inProgress) ->
  _inProgress ?= 
    quantifierType : null
    thisTypeBoundVariables : []
    allBoundVariables : []
  
  quantifierType = expression?.type or null
  
  # console.log "_inProgress.thisTypeBoundVariables #{_inProgress.thisTypeBoundVariables}"
  # console.log "_inProgress.allBoundVariables #{_inProgress.allBoundVariables}"
  # console.log "quantifierType #{quantifierType}"
  
  if _inProgress.quantifierType isnt quantifierType
    # New type of quantifier or end of sequence. 
    _inProgress.thisTypeBoundVariables.sort()
    _inProgress.allBoundVariables.push (_inProgress.thisTypeBoundVariables)...
    _inProgress.thisTypeBoundVariables = []
    _inProgress.quantifierType = quantifierType
  
  if quantifierType is null or not expression.boundVariable?
    return _inProgress.allBoundVariables
  
  _inProgress.thisTypeBoundVariables.push(expression.boundVariable.name)
  return _getVariableOrder expression.left, _inProgress
# Only export this for testing.
exports._getVariableOrder = _getVariableOrder  



# Warning : convert to PNF first!  (This only works for PNF sentences)
eliminateRedundancyInPNF = (expression) ->
  fn = (expression) ->
    for name, sub of substitute.subs_eliminate_redundancy
      expression = substitute.doSubRecursive expression, sub
    expression = sortPNFExpression(expression)
  result = util.exhaust expression, fn
  result = removeQuantifiersThatBindNothing result
  return result
exports.eliminateRedundancyInPNF = eliminateRedundancyInPNF  


# Returns `true` if the variable named `variableName` occurs free in `expression`.
isVariableFree = (variableName, expression) ->
  # console.log "#{variableName} : #{util.expressionToString expression}"
  if expression.termlist?
    termNames = (t.name for t in expression.termlist)
    # console.log "termNames #{termNames}, test = #{variableName in termNames}"
    return true if variableName in termNames
  if expression.boundVariable?
    if expression.boundVariable.name is variableName
      return false
  if expression.left?
    return true if isVariableFree(variableName, expression.left)
  if expression.right?
    return true if isVariableFree(variableName, expression.right)
  return false
exports.isVariableFree = isVariableFree
  
# This may modify `expression` in place but you need to use its
# return value as it does not always modify `expression` in place.
removeQuantifiersThatBindNothing = (expression) ->
  # Add the `parent` property to help with deleting a quantifier.
  util.addParents expression 

  fn = (expression) ->
    # There's nothing to do if `expression` isn't a quantifier.
    return expression if not expression.boundVariable?
    
    # `expression` is a quantifier.
    quantifier = expression
    quantifiedExpression = expression.left
    
    # There's nothing to do if `quantifier` binds a variable that occurs 
    # free in the expression it quantifies.
    return expression if isVariableFree(quantifier.boundVariable.name, quantifiedExpression) 
    
    # We need to remove this quantifier.
    if not quantifier.parent
      return quantifiedExpression
      
    # Quantifier has a parent, so we want to attach `quantifiedExpression` to its parent.
    # We need to out work whether `quantifier` is the `.left` or `.right` child.
    if quantifier.parent.left is quantifier
      quantifier.parent.left = quantifiedExpression
    else if expression.parent.right is expression
      quantifier.parent.right = quantifiedExpression
    else
      throw new Error "Could not work out how to remove quantifier from expression."
    return quantifiedExpression
        
  return util.walk expression, fn
exports.removeQuantifiersThatBindNothing = removeQuantifiersThatBindNothing