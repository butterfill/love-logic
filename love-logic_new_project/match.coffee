# Match is for finding and applying matches between patterns like `φ[a-->β]`
# and awFOL expressions like `F(b)`.  This is used in converting
# expressions to PNF, and in verifying rules of proof.
#
# Two things make this tricky.  First, patterns may contain meta variables 
# like `φ` (which matches any sentence-like expression) and `β` which matches
# any term.


_ = require 'lodash'

util = require './util'

# If there is a way of selectively applying the substitutions in `pattern` and 
# identifying metavariables in `pattern` with components of `expression`, then
# this function will find it. 
#
# It returns the matches between metavariables in `pattern` and components of 
# `expression` unless `expression` is not an instance of `pattern`.  In that case,
# this function returns false.
#
# Note: the function handles substitutions (as in `φ[α-->β]`) as optional; i.e.
# if there is a way of fully or partially applying the substitution that will
# generate a mtach, a match is generated.  
#
# See below for how the order in which it consideres applying substitutions.
# (In essence, `C` is an instance of `A[A-->B,B-->C]` but not of `A[B-->C,A-->B]`.)
find = (expression, pattern, _matches={}) ->
  _matches ?= {}
  
  matchFinder = (patternWithSubsDone) ->
    newMatches = findWithoutApplyingSubs(expression, patternWithSubsDone, _matches)
    return undefined if newMatches is false
    for k,v of newMatches
      newMatches[k] = util.cloneExpression v
    return newMatches

  # Note: `or false` so that `.find` returns false when `doAfterApplyingSubstitutions`
  # returns `undefined`.
  return doAfterApplyingSubstitutions(pattern, matchFinder) or false
exports.find = find


# Determines whether  `expression` matches `pattern`, e.g. whether `not not A` matches `not φ`.
# Where `expression` and `pattern` are fol.parse objects (not strings).
# @returns `false` if no match, otherwise a map with each variable's match.
#   E.g, in the above case it will return `{φ:fol.parse('not A')}`
#
# @param expression is like `fol.parse("not not (P and Q)")`
# @param pattern is like `fol.parse("not not φ")` (extraneous properties will be removed)
#
# Note: `fol.parse "φ"` creates an expression with type  `expression_variable`
#
# Set @param `_matches` to constrain what metavariables can match (this can be
# useful if matching sets of sentences to sets of patterns).
#
# Note: this function only attempts to match `expression` itself 
# (it does not look for matches with components of `expression`).
findWithoutApplyingSubs = (expression, pattern, _matches={}) ->
  
  # Note: returning anything other than undefined immediately ends the 
  # topDown walk performed by `util.walkCompare` (to which `comparator` is sent)
  comparator = (expression, pattern) ->
    return undefined unless pattern?.type?
    
    # Check whether `pattern` is an expression_variable; and, if so, test for a match.
    if pattern.type in ['expression_variable', 'term_metavariable', 'term_metavariable_hat']
      targetVar = pattern.letter if pattern.type is 'expression_variable' # eg φ
      targetVar = pattern.name if pattern.type in ['term_metavariable', 'term_metavariable_hat'] # eg τ2
      targetValue = expression
      if targetVar of _matches
        return util.areIdenticalExpressions(targetValue, _matches[targetVar])
      else
        _matches = _.clone _matches
        # console.log "matched #{targetVar} : #{util.expressionToString targetValue}"
        if pattern.type is 'term_metavariable_hat'
          # a `term_metavariable_hat` can only match a `name_hat`
          return false unless targetValue.type is 'name_hat'
        _matches[targetVar] = targetValue
        if pattern.box?
          # remove the box from the match
          expressionMinusBox = util.cloneExpression expression
          delete expressionMinusBox.box
          _matches[targetVar] = expressionMinusBox
          # check that the box parts match
          return false if not expression.box?
          return util.walkCompare(expression.box, pattern.box, comparator)
        return _matches
        
    return undefined

  expressionMatchesPattern = util.walkCompare(expression, pattern, comparator)
  if expressionMatchesPattern
    return _matches
  else
    return false
exports.findWithoutApplyingSubs = findWithoutApplyingSubs


# Generate all different ways of applying and not applying all substitutions 
# in `expression`.  Pass each generated expression to `process`; stop and 
# return the result if `process` returns something other than undefined;
# otherwise keep generating ways of applying and not applying all substitutions 
# in `expression` and passing them to `process`.
doAfterApplyingSubstitutions = (expression, process) ->
  # Shortcut in case `expression` has no substitutions (not necessary, but 
  # saves lots of time.)
  if not util.expressionContainsSubstitutions(expression)
    return process(expression)
  
  # Preliminary: move every substitution onto all terms in its scope
  # (or onto all sentences in the case of a substitution for a sentence 
  # letter or `expression_variable`).
  eClone = util.cloneExpression expression
  eClone = _moveAllSubsInwards eClone 
  
  return _applyOrSkipSubstitutions(eClone, process)
exports.doAfterApplyingSubstitutions = doAfterApplyingSubstitutions


# Consider the substitutions in a fixed order (defined by `util.walkMutate` and
# the fact that we do `sub1` first in `[sub1,sub2]`); for each sub,
# create a branch in which it is (a) applied and (b) ignored.
_applyOrSkipSubstitutions = (e, process) ->
  e1 = _applyOneSubstitution e
  e1done = not util.expressionContainsSubstitutions( e1 )
  if e1done
    result = process( e1 )
    return result if result 
    # Since `e1` didn't work, try `e2`.
  
  e2 = _skipOneSubstitution  e
  e2done = not util.expressionContainsSubstitutions( e2 )
  e1ISNTe2 = not util.areIdenticalExpressions(e1, e2)
  if e2done and e1ISNTe2
    result = process( e2 )
    # Note: at this point we must return whatever `result` is.
    return result if result
  
  if not e1done
    result = _applyOrSkipSubstitutions(e1, process)
    return result if result

  if not e2done and e1ISNTe2
    result = _applyOrSkipSubstitutions(e2, process)
    return result if result
    
  return undefined


# Find the first (in the order of `util.walkMutate`) substitution in any
# sub-expression of `expression`, remove it and apply it.  
# Removes any identity substitutions found along the way.
# Does not mutate `expression`.
_applyOneSubstitution = (expression) ->
  
  mutateFinder = (e) ->
    return undefined if not e?.substitutions?
  
    # Note: `pullSub` mutates `e`
    newExpression = util.cloneExpression e
    theSub = _pullSub newExpression
    if not theSub?
      # This might happen if the subs are all like `α->α`.
      # In this case, remove `e.substitutions` but keep walking
      return {newExpression:eClone, aResult:undefined}

    if _canApplySubAtInnermostPoint(newExpression, theSub)
      newTo = util.cloneExpression(theSub.to) 
      if newExpression.substitutions?
        newTo.substitutions = newExpression.substitutions
      if newExpression.box?
        newTo.box = newExpression.box
      newExpression = newTo
      # console.log "\treplaced #{util.expressionToString theSub.from}->#{util.expressionToString theSub.to}; got #{util.expressionToString newExpression}"

    return {newExpression, aResult:theSub}
  
  eClone = util.cloneExpression expression
  {theResult, mutatedExpression} = util.walkMutateFindOne(eClone, mutateFinder)
  return mutatedExpression


_canApplySubAtInnermostPoint = (e, theSub) ->
  return false unless e.type is theSub.from.type
  if e.name? and theSub.from.name? and e.name is theSub.from.name
    return true
  if e.letter? and theSub.from.letter? and e.letter is theSub.from.letter
    return true
  return false


_skipOneSubstitution = (expression) ->
  mutateFinder = (e) ->
    return undefined if not e?.substitutions?

    # Note: `pullSub` modifies `e`
    eClone = util.cloneExpression e
    theSub = _pullSub eClone
    # Note: `theSub` may be undefined; in which case, we will keep going.
    return {newExpression:eClone, aResult:theSub}

  eClone = util.cloneExpression expression
  {theResult, mutatedExpression} = util.walkMutateFindOne(eClone, mutateFinder)
  return mutatedExpression


# Whenever a part of `e` other than a term has substitutions, 
# remove those substitutions and attach them to all terms in that
# part of `e`.
# Does not mutate `expression`.
_moveAllSubsInwards = (expression) ->
  
  walker = (e) ->
    return e if not e?.substitutions?
    return e if e?.type? and e.type in ['name','variable','term_metavariable']
    theSub = _pullSub e
    while theSub
      if _isTermSub(theSub)
        e = _addSubToEveryTerm(e, theSub)
      else 
        e = _addSubToEverySentence(e, theSub)
      theSub = _pullSub e
    return e
  
  eClone = util.cloneExpression expression
  return util.walkMutate(eClone, walker)
exports._moveAllSubsInwards = _moveAllSubsInwards    


# Take one substitution from `e.substitutions`, ignoring identity substitutions
# like α->α.
# Mutate `e` by removing the the substitution from it, and deleting `e.substitutions` 
# if necessary.
_pullSub = (e) ->
  if not e.substitutions?
    return undefined
  
  # console.log "\t_pullSub got #{util.expressionToString e}"
    
  theSub = e.substitutions.shift()

  # Tricky case: subs like `α->α`. These can arise in proofs
  # (see test 2518C33E-587C-11E5-B046-B15A631DAC50), and as a consequence of
  # multiple substitutions.  Save branching by ignoring them.
  while e.substitutions.length > 0 and util.areIdenticalExpressions(theSub.from, theSub.to)
    theSub = e.substitutions.shift()
  if util.areIdenticalExpressions(theSub.from, theSub.to) 
    # We have a sub like  `α->α`. We will just delete this.
    delete e.substitutions
    return undefined

  if e.substitutions.length is 0
    delete e.substitutions
  
  return theSub


_isTermSub = (sub) ->
  return true if sub.from.type in util.termTypes
  return false


# Add `theSub` to every name, variable and term_metavariable of `e`
# (which, in awFOL syntax, aren't actually allowed to have substitutions.).
# Note: this does not mutate `e`.
# Note: Here we assign substitutions to elements that awFOL doesn't allow to have substiutions.
# TODO: Should awFOL syntax be correspondingly modified?
_addSubToEveryTerm = (expression, theSub) ->
  return _addSubToEveryX(expression, theSub, util.termTypes)
exports._addSubToEveryTerm = _addSubToEveryTerm

_addSubToEverySentence = (expression, theSub) ->
  return _addSubToEveryX(expression, theSub, ['sentence_letter', 'expression_variable'])
exports._addSubToEverySentence = _addSubToEverySentence

_addSubToEveryX = (expression, theSub, expressionTypes) ->
  walker = (e) ->
    return e if not e?.type?
    return e if not (e.type in expressionTypes)

     # Do not attach substitutions when in substitutions.
    return e if walker._inSub 

    if e.substitutions and not util.expressionHasSub(e, theSubClone)
      e.substitutions.push(theSubClone)
    else
      e.substitutions = [theSubClone]
      # console.log "\tadded #{util.expressionToString theSub.from}->#{util.expressionToString theSub.to}; got #{util.expressionToString e}"
    return e
    
  eClone = util.cloneExpression expression
  theSubClone = util.cloneExpression theSub
  eClone = util.walkMutate(eClone, walker)
  return eClone

# This assumes that `_moveAllSubsInwards` has been done
# (otherwise it's harder to know exactly which subs will make a difference.)
_removeInefficaciousSubs = (e) ->
  return e if not e?.substitutions?
  


# ----
# END of doAfterApplyingSubstitutions 
# ----




# Replaces occurrences of an `expression_variable` in `pattern` with the corresponding
# value from `matches`.  E.g. 
#     `match.apply fol.parse("not not φ"), {φ:fol.parse('A and B')}`
# will return fol.parse("not not (A and B)")
apply = (pattern, matches, o={}) ->
  walker = (pattern) ->
    # Screen out everything but the variables we might replace
    return pattern unless pattern?.type? and pattern.type in ['expression_variable', 'term_metavariable', 'term_metavariable_hat']

    # Work out what we are potentially replacing.
    targetVar = pattern.letter if pattern.type is 'expression_variable' # eg φ
    targetVar = pattern.name if pattern.type in ['term_metavariable', 'term_metavariable_hat'] # eg τ2

    # Do nothing if the variable to be replaced is not in matches
    return pattern unless targetVar of matches

    # Replace the variable with its match.
    toReplace = util.cloneExpression(matches[targetVar])
    # Be sure to add back any substitutions and boxes (which will already have been
    # processed by `match.apply`.)
    toReplace.substitutions = pattern.substitutions if pattern.substitutions?
    toReplace.box = pattern.box if pattern.box?
    return toReplace
  
  if o.noClone
    return util.walkMutate(pattern, walker)
  theClone = util.cloneExpression pattern
  return util.walkMutate(theClone, walker)

exports.apply = apply
