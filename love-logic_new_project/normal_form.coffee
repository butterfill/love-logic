# This module provides functions for converting expressions to 
# prenex normal form, and for comparing expressions in PNF in such a way
# that some trivial differences (e.g. ordering of conjuncts) are ignored.


_ = require 'lodash'

util = require './util'
match = require './match'
substitute = require './substitute'




# returns a clone of `expression` in prenex normal form
prenexNormalForm = (expression) ->
  result = util.cloneExpression expression
  
  # Some substitutions only need doing once.
  result = substitute.doSubRecursive(result, substitute.subsForPNF.replace_arrow)
  result = substitute.doSubRecursive(result, substitute.subsForPNF.replace_double_arrow)
  result = renameVariables result

  # The rest of the substitutions may need to be done repeatedly.
  pnf = (e) ->
    for name,sub of substitute.subsForPNF when not (name in ['replace_arrow', 'replace_double_arrow'])
      e = substitute.doSubRecursive(e, sub)
    return e
  result = util.exhaust result, pnf

  # # The above dnf thing is slow; it can be sped up by applying subsitutions
  # # in smaller sets as follows 
  # # (but this makes it less obvious the alogrithm will always work).
  # ```
  # # First move the quantifiers out.
  # quantifiersOut = (expression) ->
  #   result = expression
  #   for sub in [subs.not_all, subs.not_exists
  #               subs.all_and_left, subs.all_and_right
  #               subs.all_or_left, subs.all_or_right
  #               subs.exists_and_left, subs.exists_and_right
  #               subs.exists_or_left,  subs.exists_or_right
  #             ]
  #     result = doSubRecursive result, sub
  #   return result
  # result = util.exhaust result, quantifiersOut
  #
  # # Then fix the body: push negations all the way in to the atomic formulae.
  # demorgan = (expression) ->
  #   result = expression
  #   for sub in [subs.dbl_neg, subs.demorgan1, subs.demorgan2]
  #     result = doSubRecursive result, sub
  #   return result
  # result = util.exhaust result, demorgan
  #
  # # Finally, move disjunctions into conjunctions
  # dnf = (expression) ->
  #   result = expression
  #   for sub in [subs.cnf_left, subs.cnf_right]
  #     result = doSubRecursive result, sub
  #   return result
  # result = util.exhaust result, dnf
  # ```
  
  return result
  
exports.prenexNormalForm = prenexNormalForm


# Returns true just if expression is in prenex normal form.
isPNF = (expression) ->
  core = removeQuantifiers expression
  conjuncts = listJuncts core, 'and'
  nestedDisjuncts = ( listJuncts(junct, 'or') for junct in conjuncts)
  for someDisjuncts in nestedDisjuncts
    for disjunct in someDisjuncts
      # We are only allowed sentence letters or negations in here
      return false unless (disjunct.type in ['not', 'sentence_letter', 'predicate'])
      if disjunct.type is 'not'
        # The thing negated must be a sentence letter or predicate
        return false unless disjunct.left.type in ['sentence_letter','predicate']
  return true
exports.isPNF = isPNF


# Go through expression and rename variables so that each 
# quantifier binds a distinct variable.
# This may use variable names that are illegal in the awFOL lexer (e.g. xx1, xx2).
# (This isn't strictly necessary: it just provides a visual marker that things have been changed.)
#
# The new variable names will have the form `newVariableBaseName[0-9]+` .
# If you want to create a pattern to match, set `newVariableBaseName` to 'τ'.
renameVariables = (expression, newVariableBaseName) ->
  newVariableBaseName ?= 'x'
  newVariableType = ('term_metavariable' if newVariableBaseName[0] in ['α','β','γ','τ']) or 'variable'
  
  _newVarIdx = 0 #Note: this is not a number because we need to mutate it.
  # The keys are the old variable names, values are their replacements.
  _newVarNames = {} 
  # The keys are the new variable names, values are what they replaced.
  _oldVarNames = {}
  
  # Get a replacement name for the `variable`, either the current replacement
  # if there is one, or else a new replacement (which is saved for next time
  # we see a variable with the same name).
  getReplacementName = (variable) ->
    if not _newVarNames[variable.name]?
      _newVarIdx += 1
      newName = "#{newVariableBaseName}#{_newVarIdx}"
      _newVarNames[variable.name] = newName
    return _newVarNames[variable.name]

  # Force whatever name was replaced by `variable.name` (if any)
  # to be discarded, so that future occurrences of variables with this 
  # name will get a different name.
  setNewReplacementName = (variable) ->
    if _newVarNames[variable.name]?
      delete _newVarNames[variable.name]
  
  topDownWalker = (expression) ->
    return expression if expression is null # Because null can occur in substitutions.
    return expression unless (expression?.boundVariable?) or (expression?.type? and expression.type is 'variable')
    
    # Require that a new replacement name be used for a variable every time 
    # we see it bound to a quantifier.
    #
    # Note: `expression.boundVariable?` is the test for whether an awFOL 
    # expression is a quantifier.  
    # (What follows should generalise in case new quantifiers are added.)
    if expression.boundVariable?
      setNewReplacementName(expression.boundVariable)
  
    if expression?.type? and expression.type is 'variable'
      variable = expression
      variable.name = getReplacementName(variable)
      variable.type = newVariableType
      
    return expression
  
  return util.walkMutate(expression, topDownWalker, topDown:true)
    
exports.renameVariables = renameVariables


convertToPNFsimplifyAndSort = (expression) ->
  expression = prenexNormalForm expression
  expression =  eliminateRedundancyInPNF(expression)
  # Strictly speaking, we don't need to sort as `eliminateRedundancyInPNF` currently does so anyway.
  # But it's essential that we are sorted, so I'll do it anyway.
  expression = sortPNFExpression(expression)
  sortIdentityStatements(expression)
  return expression
exports.convertToPNFsimplifyAndSort = convertToPNFsimplifyAndSort

areExpressionsEquivalent = (left, right) ->
  left = prenexNormalForm left
  right = prenexNormalForm right
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
  sortIdentityStatements(right)
  pattern = renameVariables left, 'τ'
  patternCore = removeQuantifiers pattern
  rightCore = removeQuantifiers right

  # Note: matches will found irrespective of the original order of terms 
  # in identity statements because we have sorted identity statements 
  # (using `sortIdentityStatements`).
  matches = match.find rightCore, patternCore 
  return false if matches is false
  
  # From this point on, we know that the cores (expressions minus quantifiers)
  # match.  The question is just whether the quantifiers match.
  modifiedLeft = match.apply pattern, matches
  
  # There's a potential catch.  If there were quantifiers that dont bind anything,
  # there could be unmatched term_metavariables in `modifiedLeft`.
  # But since we did `removeQuantifiersThatBindNothing` (as part of `eliminateRedundancyInPNF`),
  # this possibility will not arise here.
  
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
# `expression` is a awFOL expression.
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
      # The commented code here and below illustrates how to record the 
      # substitutions applied -- could be useful in giving feedback to 
      # students when exercises involve writing substutions schemes.
      # pre = util.cloneExpression expression
      expression = substitute.doSubRecursive expression, sub
      # if not util.areIdenticalExpressions(pre,expression)
      #   console.log "eliminateRedundancyInPNF:"
      #   console.log "\t from: #{util.expressionToString pre}"
      #   console.log "\t to: #{util.expressionToString expression}"
      #   console.log "\t using #{util.expressionToString sub.from} -> #{util.expressionToString sub.to} "
    expression = sortPNFExpression(expression)
  result = util.exhaust expression, fn
  result = removeQuantifiersThatBindNothing result
  return result
exports.eliminateRedundancyInPNF = eliminateRedundancyInPNF  


# Returns `true` if the variable named `variableName` occurs free in `expression`.
isVariableFree = (variableName, expression) ->
  if expression.termlist?
    termNames = (t.name for t in expression.termlist)
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
  
# This does not modify `expression` in place.
removeQuantifiersThatBindNothing = (expression) ->
  walker = (expression) ->
    # There's nothing to do if `expression` isn't a quantifier.
    return expression if not expression?.boundVariable?
    
    # `expression` is a quantifier.
    quantifier = expression
    quantifiedExpression = expression.left
  
    # There's nothing to do if `quantifier` binds a variable that occurs 
    # free in the expression it quantifies.
    return expression if isVariableFree(quantifier.boundVariable.name, quantifiedExpression) 
    
    # We need to remove this quantifier.
    return quantifier.left
  e = util.cloneExpression expression
  return util.walkMutate e, walker
    
exports.removeQuantifiersThatBindNothing = removeQuantifiersThatBindNothing



