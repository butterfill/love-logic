# Apply various substitutions to awFOL expressions,
# including converting an arbitrary formula to prenex normal form.
#
# apply substitutions to formulae like
# ```
#      sub =
#        from : fol.parse 'not not φ'
#        to : fol.parse 'φ'
#  ```

_ = require 'lodash'

util = require './util'
fol = require './parser/awFOL'  # TODO remove dependence (only required for compiling subs)
symmetry = require './symmetry'


_subs = 
  replace_arrow :
    from : 'φ arrow ψ'
    to: '(not φ) or ψ'
  replace_double_arrow :
    from : 'φ ↔ ψ'
    to: '(φ or (not ψ)) and ((not φ) or ψ)'
    # to: '(φ and ψ) or ((not φ) and (not ψ))'
  demorgan1:
    from: 'not (φ and ψ)',
    to: '((not φ) or (not ψ))'
  demorgan2:
    from: 'not (φ or ψ)',
    to: '((not φ) and (not ψ))'
  dbl_neg: 
    from: 'not not φ',
    to: 'φ'
  not_all:
    from: 'not ((all τ) φ)'
    to: '(exists τ) (not φ)'
  not_exists:
    from: 'not ((exists τ) φ)'
    to: '(all τ) (not φ)'
  cnf_left:
    from: 'φ1 or (φ2 and φ3)'
    to: '(φ1 or φ2) and (φ1 or φ3)'
  cnf_right:
    from: '(φ2 and φ3) or φ1'
    to: '(φ2 or φ1) and (φ3 or φ1)'
  # The following only preserve truth in expressions where no two quantifiers bind the same variable.
  # (So always apply `renameVariables` before using them.)
  all_and_left:
    from: 'φ and ((all τ) ψ)'
    to: '(all τ) (φ and ψ)'
  all_and_right:
    from: '((all τ) ψ) and φ'
    to: '(all τ) (ψ and φ)'
  all_or_left:
    from: 'φ or ((all τ) ψ)'
    to: '(all τ) (φ or ψ)'
  all_or_right:
    from: '((all τ) ψ) or φ'
    to: '(all τ) (ψ or φ)'
  exists_and_left:
    from: 'φ and ((exists τ) ψ)'
    to: '(exists τ) (φ and ψ)'
  exists_and_right:
    from: '((exists τ) ψ) and φ'
    to: '(exists τ) (ψ and φ)'
  exists_or_left:
    from: 'φ or ((exists τ) ψ)'
    to: '(exists τ) (φ or ψ)'
  exists_or_right:
    from: '((exists τ) ψ) or φ'
    to: '(exists τ) (ψ or φ)'

# TODO : Should these built in subs be compiled as part of the build, not here 
# as the module inits?
subs = {}
for k,v of _subs
  from = fol.parse v.from
  util.delExtraneousProperties from
  to = fol.parse v.to
  util.delExtraneousProperties to
  theSub = {from:from, to:to}
  subs[k] = theSub
exports.subs = subs


# To be useful, these substitutions depend on the standard sort order, 
# as defined in `symmetry.sortPNFExpression`.
# Note: it is required that none of these substitutions could take an expression
# in PNF to one that is not in PNF!
_subs_eliminate_redundancy = 
  identity :
    from : 'τ=τ'
    to : 'true'
  not_true : 
    from : 'not true'
    to : 'false'
  not_false : 
    from : 'not false'
    to : 'true'
  or_duplicate:
    from : 'φ or φ'
    to : 'φ'
  or_duplicate_left:
    from : 'φ or (φ or ψ)'
    to : 'φ or ψ'
  # TODO: Is the right version (`or_duplicate_right`) is needed 
  # given how `symmetry.rebuildExpression` works?
  # (This applies to the stuff below as well.)
  or_duplicate_right:
    from : '(ψ or φ) or φ'
    to : 'ψ or φ'
  and_duplicate:
    from : 'φ and φ'
    to : 'φ'
  and_duplicate_left:
    from : 'φ and (φ and ψ)'
    to : 'φ and ψ'
  and_duplicate_right:
    from : '(ψ and φ) and φ'
    to : 'ψ and φ'
  false_or :
    from : 'false or φ'
    to : 'φ'
  true_or :
    from : 'true or φ'
    to : 'true'
  false_and : 
    from : 'false and φ'
    to : 'false'
  true_and : 
    from : 'true and φ'
    to : 'φ'
  # The following are useful because of the sorting provided by `symmetry.sortPNFExpression`.
  # E.g. this sorting guaratees that not φ comes after φ in a disjunction.
  contradiction_and :
    from : 'φ and not φ'
    to : 'false'
  contradiction_and_left :
    from : 'φ and (not φ and ψ)'
    to : 'false'
  contradiction_and_right : # Do we need this (`symmetry.rebuildExpression` should mean it doesn't happen)?
    from : '(ψ and φ) and not φ'
    to : 'false'
  taut_or :
    from : 'φ or not φ'
    to : 'true'
  taut_and_left :
    from : 'φ or (not φ or ψ)'
    to : 'true'
  taut_and_right :       # Do we need this (`symmetry.rebuildExpression` should mean it doesn't happen)?
    from : '(ψ or φ) or not φ'
    to : 'true'
  # The following are not needed because we now use
  # the more general `symmetry.removeQuantifiersThatBindNothing`.
  # exists_false :
  #   from : 'exists τ false'
  #   to : 'false'
  # exists_true :
  #   from : 'exists τ true'
  #   to : 'true'
  # all_false :
  #   from : 'all τ false'
  #   to : 'false'
  # all_true :
  #   from : 'all τ true'
  #   to : 'true'
    
  
    
subs_eliminate_redundancy = {}
for k,v of _subs_eliminate_redundancy
  from = fol.parse v.from
  util.delExtraneousProperties from
  to = fol.parse v.to
  util.delExtraneousProperties to
  theSub = {from:from, to:to}
  subs_eliminate_redundancy[k] = theSub
exports.subs_eliminate_redundancy = subs_eliminate_redundancy


# Apply the `sub` to the `expression`.  `sub` is like {from:"not not φ", to:"φ"}
# If `sub` cannot be applied, returns `expression` unchanged.
doSub = (expression, sub) ->
  theMatches = findMatches expression, sub.from 
  if theMatches 
    return applyMatches(sub.to, theMatches)
  else 
    return expression 
exports.doSub = doSub

# Apply the `sub` to the `expression` and all its components.  
# (See doSub.)
doSubRecursive = (expression, sub) ->
  walker = (e) ->
    return e if e is null
    return e if _.isArray(e)
    return e if e.type? and e.type is 'box'
    return doSub(e, sub)
  return util.walkMutate(expression, walker)
exports.doSubRecursive = doSubRecursive



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
# You don't normally need to set @param _matches; is used internally to keep track 
# of what is already matched, but you  might also use it if keeping track of 
# multiple matches where one constains another.
#
# Note: this function only attempts to match `expression` itself 
# (it does not look for matches with components of `expression`).
#
# Note: the function handles substitutions (as in `φ[α->β]`) as optional; i.e.
# if there is a way of fully or partially applying the substitution that will
# generate a mtach, a match is generated.
findMatches = (expression, pattern, _matches) ->
  _matches ?= {}
  
  # Note: returning anything other than undefined immediately ends the 
  # topDown walk performed by `util.walkCompare` (to which `comparator` is sent)
  comparator = (expression, pattern) ->
    return undefined unless pattern?.type?
    
    if pattern.substitutions? 
      # Abort comparison and switch to an alternative, branching method.
      patternClone = util.cloneExpression pattern
      # Note : we only take one of the substitutions so that there will be nested
      # branching for multiple subsitutions.
      # TODO: doesn't work!  Why not? 
      theSub = patternClone.substitutions.pop()
      if patternClone.substitutions.length is 0
        delete patternClone.substitutions
      _matchesClone = _.clone _matches
      result =  _findMatchesSubstitutions(expression, patternClone, _matchesClone, theSub)
      _matches = result
      if result isnt false
        return true
      else
        return false
    
    # Check whether `pattern` is an expression_variable; and, if so, test for a match.
    if pattern.type in ['expression_variable', 'term_metavariable']
      targetVar = pattern.letter if pattern.type is 'expression_variable' # eg φ
      targetVar = pattern.name if pattern.type is 'term_metavariable' # eg τ2
      targetValue = expression
      if targetVar of _matches
        # Note that we have to compare these sub-expressions using this `comparator`
        # because there may be sustitutions to partially match.
        # return util.walkCompare(targetValue, _matches[targetVar], comparator)
        return util.areIdenticalExpressions(targetValue, _matches[targetVar])
      else
        if comparator._trace?
          console.log "matched #{targetVar} to  #{util.expressionToString targetValue}"
        _matches[targetVar] = targetValue
        if pattern.box?
          return false if not expression.box?
          return util.walkCompare(expression.box, pattern.box, comparator)
        return true
        
    return undefined

  expressionMatchesPattern = util.walkCompare(expression, pattern, comparator)
  if expressionMatchesPattern
    # Protect the expressions matched by cloning them. 
    for k,v of _matches
      _matches[k] = util.cloneExpression v
    return _matches
  else
    return false

exports.findMatches = findMatches

# This concerns patterns with substitutions like `φ[a->β]`.  This is
# tricky because there are many valid substitution instances --- any
# subset of the occurrences of `a` may be replaced with `β`.
# This matters for correctly verifying rules of proof (see test id 
# A7774B7C-57DA-11E5-B920-720262EA09BE and test id AF96B036-57DA-11E5-8511-720262EA09BE.  
_findMatchesSubstitutions = (expression, pattern, _matches, theSub) ->
  
  console.log "branching for sub #{util.expressionToString theSub.from}->#{util.expressionToString theSub.to} from pattern = #{util.expressionToString pattern}"
  
  comparator = (expression, pattern) ->
    # Make a match without relying on substitutions if we can.
    # (This avoids using metavariables unnecessarily, which would prevent
    # them from matching when they are really necessary.)
    priorMatches = _.clone _matches
    firstTry = findMatches(expression, pattern, priorMatches)
    if firstTry isnt false
      _matches = _.defaults _matches, firstTry
      return true
    
    # Attempt to make a match relying of substitutions if we cannot.
    priorMatches = _.clone _matches
    cloneForPatternWithSubApplied = util.cloneExpression(pattern)
    patternWithSubApplied = replace(cloneForPatternWithSubApplied, theSub)
    console.log "testing with sub #{util.expressionToString theSub.from}->#{util.expressionToString theSub.to} from pattern = #{util.expressionToString pattern}"
    # console.log "\tpatternWithSubApplied = #{JSON.stringify patternWithSubApplied,null,4}"
    secondTry = findMatches(expression, patternWithSubApplied, priorMatches)
    if secondTry isnt false
      _matches = _.defaults _matches, secondTry
      return true
    
    return undefined # Keep comparing

  expressionMatchesPattern = util.walkCompare(expression, pattern, comparator)
  if expressionMatchesPattern
    return _matches
  else
    return false



# Replaces occurrences of an `expression_variable` in `pattern` with the corresponding
# value from `matches`.  E.g. 
#     `applyMatches fol.parse("not not φ"), {φ:fol.parse('A and B')}`
# will return fol.parse("not not (A and B)")
applyMatches = (pattern, matches) ->
  walker = (pattern) ->
    # Screen out everything but the variables we might replace
    return pattern unless pattern?.type? and pattern.type in ['expression_variable', 'term_metavariable']

    # Work out what we are potentially replacing.
    targetVar = pattern.letter if pattern.type is 'expression_variable' # eg φ
    targetVar = pattern.name if pattern.type is 'term_metavariable' # eg τ2

    # Do nothing if the variable to be replaced is not in matches
    return pattern unless targetVar of matches

    # Replace the variable with its match.
    toReplace = util.cloneExpression(matches[targetVar])
    # Be sure to add back any substitutions and boxes (which will already have been
    # processed by `applyMatches`.)
    toReplace.substitutions = pattern.substitutions if pattern.substitutions?
    toReplace.box = pattern.box if pattern.box?
    return toReplace

  theClone = util.cloneExpression pattern
  return util.walkMutate(theClone, walker)

exports.applyMatches = applyMatches


# Replaces all instances of `whatToReplace.from` with `whatToReplace.to` in `expression`.
# E.g.
#    the expression `fol.parse "Loves(x,b)"` 
#    would be turned into `Loves(a,b)` with whatToReplace = {from:VARIABLE_X, to:NAME_A}
#
# Note: This will not take into account whether or not a variable is bound
# when replacing it.
#
# Special feature for substitutions like `[a->null]`: if it actually finds a match
# to replace, it will throw Error with `.messsage` "_internal: replace to null".
replace =  (expression, whatToReplace) ->
  toFind = whatToReplace.from
  toReplace = whatToReplace.to
  walker = (e) ->
    return e if e is null or _.isArray(e)
    if util.areIdenticalExpressions(e, toFind)
      if toReplace is null
        throw new Error "_internal: replace to null"
      return util.cloneExpression(toReplace)
    return e
  e = util.cloneExpression(expression)
  return util.walkMutate(e, walker)
exports.replace = replace


# Given `A[A->B]` as the `expression`, return `B`.
# (This is not to be confused with doSub, doSubRecursive (TODO: rename, reorganize).)
# `expression` will not be modified.
applySubstitutions = (expression) ->
  # We are going to do this by starting at a point innermost in the expression
  # and walking outwards, so that `(A[A->B] and C)[B->D]` returns `D and C`.
  walker = (e) ->
    return e if not e?.substitutions?
    theSubs = _.cloneDeep e.substitutions
    delete e.substitutions
    for s in theSubs
      whatToReplace =
        from : s.from
        to : s.to
      e = replace(e, whatToReplace)
    return e
    
  e = _.cloneDeep expression
  try
    return util.walkMutate(e, walker)
  catch e 
    return null if e.message is "_internal: replace to null"
    throw e
exports.applySubstitutions = applySubstitutions

# Go through expression and rename variables so that each 
# quantifier binds a distinct variable.
# This may use variable names that are illegal in the awFOL lexer (e.g. xx1, xx2).
# (This isn't strictly necessary: it just provides a visual marker that things have been changed.)
#
# The new variable names will have the form `newVariableBaseName[0-9]+` .
# If you want to create a pattern to match, set `newVariableBaseName` to 'τ'.
renameVariables = (expression, newVariableBaseName) ->
  newVariableBaseName ?= 'xx'
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


# returns a clone of `expression` in prenex normal form
prenexNormalForm = (expression) ->
  result = expression #No need to clone: that is done by the substitutions.
  result = doSubRecursive result, subs.replace_arrow
  result = doSubRecursive result, subs.replace_double_arrow
  result = renameVariables result
  # The rest of the substitutions may need to be done repeatedly.
  
  dnf = (expression) ->
    result = expression
    for name,sub of subs when not (name in ['replace_arrow', 'replace_double_arrow'])
      result = doSubRecursive result, sub
    return result
  result = util.exhaust result, dnf

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
  core = symmetry.removeQuantifiers expression
  conjuncts = symmetry.listJuncts core, 'and'
  nestedDisjuncts = ( symmetry.listJuncts(junct, 'or') for junct in conjuncts)
  for someDisjuncts in nestedDisjuncts
    for disjunct in someDisjuncts
      # We are only allowed sentence letters or negations in here
      return false unless (disjunct.type in ['not', 'sentence_letter', 'predicate'])
      if disjunct.type is 'not'
        # The thing negated must be a sentence letter or predicate
        return false unless disjunct.left.type in ['sentence_letter','predicate']
  return true
exports.isPNF = isPNF





