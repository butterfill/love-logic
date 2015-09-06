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
  result = {}
  for property in ['left','right','variable']
    if expression[property]?
      result[property] = doSubRecursive expression[property], sub
  if expression.termlist?
    result.termlist = (doSubRecursive(t,sub) for t in expression.termlist)      
  result = _.defaults result, expression
  return doSub(result, sub)
exports.doSubRecursive = doSubRecursive



# Determines whether  `expression` matches `pattern`, e.g. whether `not not A` matches `not φ`.
# Where `expression` and `pattern` are fol.parse objects (not strings).
# @returns false if no match, otherwise a map with each variable's match.
#   E.g, in the above case it will return `{φ:fol.parse('not A')}`
# @param expression is like `fol.parse("not not (P and Q)")`
# @param pattern is like `fol.parse("not not φ")` (extraneous properties will be removed)
# Note: `fol.parse "φ"` creates an expression with type  `expression_variable`
# @param _matches should normally be null 
# (is used internally to keep track of what is already matched), but you 
# might also use it if keeping track of multiple matches where one constains another.
# Note: this function only attempts to match `expression` itself 
# (it does not look for matches with components of `expression`).
findMatches = (expression, pattern, _matches, o) ->
  _matches ?= {
    addMatches : (moreMatches) ->
      _.defaults @, moreMatches
    
    # apply these matches to `pattern` and return the result
    apply : (pattern) ->
      return applyMatches(pattern, @)
  }
  o ?= {}
  o.symmetricIdentity ?= false
  o._notFirstCall ?= false
  if not o._notFirstCall
    # function is being called by user (not recursively)
    util.delExtraneousProperties(pattern)
    o._notFirstCall = true
  
  if pattern is null
    if expression is null
      return _matches
    else
      return false
  
  if _.isArray pattern
    return _findMatchesArray expression, pattern, _matches, o #may update _matches
    
  if _.isString pattern
    if _.isString(expression) and (expression is pattern)
      return _matches
    else
      return false
  
  if _.isBoolean pattern
    if _.isBoolean(expression) and (expression is pattern)
      return _matches
    else
      return false
  
  # Pattern is an object.
  
  # First check whether it's an expression_variable; and, if so, test for a match.
  if 'type' of pattern and (pattern.type in ['expression_variable', 'term_metavariable'])
    targetVar = pattern.letter if pattern.type is 'expression_variable' # eg φ
    targetVar = pattern.name if pattern.type is 'term_metavariable' # eg τ2
    targetValue = expression
    if targetVar of _matches
      if util.areIdenticalExpressions targetValue, _matches[targetVar]
        return _matches
      else
        return false
    else
      # console.log "matched #{targetVar} with #{targetValue.type}"
      _matches[targetVar] = targetValue
      return _matches

  # From this point on, we know that pattern.type isn neither 
  # an expression_variable nor a term_metavariable.

  # The following special case is needed only because we want to be able to
  # treat identity as symmetric when `o.symmetricIdentity` is true.
  # (This was needed for `symmetry.arePNFExpressionsEquivalent`, although now 
  # we don't need it because we sort identity statements.)
  if 'type' of pattern and pattern.type is 'identity'
    return false unless (expression.type? and expression.type is 'identity')
    result = _findMatchesArray expression.termlist, pattern.termlist, _matches, o
    # Check whether we need to treat identity as symmetric.
    if result is false and o.symmetricIdentity is true
      # We need to attempt to match the other way around.
      reversedPatternTermlist = [pattern.termlist[1],pattern.termlist[0]]
      result = _findMatchesArray expression.termlist, reversedPatternTermlist, _matches, o
    return false if result is false
    return _matches
    
  # # We could attempt to save some time by checking primitive 
  # # properties first as follows.
  # for attr in ['type','letter','name']
  #   if pattern[attr]?
  #     return false unless expression[attr]?
  #     return false unless expression[attr] is pattern[attr]

  # Pattern is an object and not an expression_variable, so we
  # loop through its keys and match them with keys of `expression`.
  for key, value of pattern
    return false unless (key of expression)
    if pattern[key] is undefined
      console.log "pattern = #{util.expressionToString pattern}, key = #{key}"
    result = findMatches expression[key], pattern[key], _matches, o #may update _matches
    return false if result is false
  return _matches
  
exports.findMatches = findMatches

_findMatchesArray = (expression, arrayOfPatterns, _matches, o) ->
  if not (_.isArray(expression))
    return false
  arrayOfExpressions = expression
  if expression.length isnt arrayOfPatterns.length
    return false
  for pattern, i in arrayOfPatterns
    result = findMatches arrayOfExpressions[i], arrayOfPatterns[i], _matches, o
    return false if result is false
  return _matches





# Replaces occurrences of an `expression_variable` in `pattern` with the corresponding
# value from `matches`.  E.g. 
#     `applyMatches fol.parse("not not φ"), {φ:fol.parse('A and B')}`
# will return fol.parse("not not (A and B)")
applyMatches = (pattern, matches) ->
  if 'type' of pattern and (pattern.type is 'expression_variable' or pattern.type is 'term_metavariable')
    targetVar = pattern.letter if pattern.type is 'expression_variable' # eg φ
    targetVar = pattern.name if pattern.type is 'term_metavariable' # eg τ2
    return util.cloneExpression(matches[targetVar])
  res = {}
  if pattern.left?
    res.left = applyMatches pattern.left, matches
  if pattern.right?
    res.right = applyMatches pattern.right, matches
  if pattern.termlist?
    res.termlist = (applyMatches(t,matches) for t in pattern.termlist)
  if pattern.boundVariable?
    res.boundVariable = applyMatches(pattern.boundVariable, matches)
  if pattern.box?
    res.box = _.cloneDeep pattern.box
    res.box.term = applyMatches(res.box.term, matches)
  if pattern.substitutions?
    res.substitutions = _.cloneDeep pattern.substitutions
    for s in res.substitutions
      s.from = applyMatches s.from, matches
      s.to = applyMatches s.to, matches
  # add everything from `pattern` to `res` except where `res` already contains it
  return _.defaults(res, pattern)
  
exports.applyMatches = applyMatches


# Replaces all instances of `whatToReplace.from` with `whatToReplace.to` in `expression`.
# E.g.
#    the expression `fol.parse "Loves(x,b)"` 
#    would be turned into `Loves(a,b)` with whatToReplace = {from:VARIABLE_X, to:NAME_A}
#
# WARNING: At present this will not take into account whether a variable is bound
# when replacing it!
#
replace =  (expression, whatToReplace) ->
  toFind = whatToReplace.from
  toReplace = whatToReplace.to
  console.log "replace: #{util.expressionToString toFind} with #{util.expressionToString toReplace} in #{util.expressionToString(expression)}"
  if util.areIdenticalExpressions(expression, toFind)
    return util.cloneExpression(toReplace)
  result = {}
  if expression.left?
    result.left = replace expression.left, whatToReplace
  if expression.right?
    result.right = replace expression.right, whatToReplace
  if expression.termlist?
    result.termlist = (replace(t,whatToReplace) for t in expression.termlist)
  if expression.boundVariable?
    result.boundVariable = replace(expression.boundVariable, whatToReplace)
  if expression.box?
    result.box = _.cloneDeep expression.box
    result.box.term = replace(expression.box.term, whatToReplace)
  # add everything from `expression` to `result` except where `result` already contains it
  return _.defaults(result, expression)  
  
exports.replace = replace

# Given `A[A->B]` as the `expression`, return `B`.
# (This is not to be confused with doSub, doSubRecursive (TODO: rename, reorganize).)
# `expression` will not be modified.
applySubstitutions = (expression) ->
  # We are going to do this by starting at a point innermost in the expression
  # and walking outwards, so that `(A[A->B] and C)[B->D]` returns `D and C`.
  doit = (e) ->
    return e if not e.substitutions?
    console.log "at expression #{util.expressionToString(e)}"
    theSubs = _.cloneDeep e.substitutions
    delete e.substitutions
    for s in theSubs
      whatToReplace =
        from : s.from
        to : s.to
      console.log "aS: replace: #{util.expressionToString whatToReplace.from} with #{util.expressionToString whatToReplace.to} in #{util.expressionToString(e)}"
      e = replace(e, whatToReplace)
    # Note : if we don't delete the substitutions, this won't work.
    return e
    
  e = _.cloneDeep expression
  return util.walkMutate(e, doit)
exports.applySubstitutions = applySubstitutions

# Go through expression and rename variables so that each 
# quantifier binds a distinct variable.
# This may use variable names that are illegal in the awFOL lexer (e.g. xx1, xx2).
# (This isn't strictly necessary: it just provides a visual marker that things have been changed.)
#
# The new variable names will have the form `newVariableBaseName[0-9]+` .
# If you want to create a pattern to match, set `newVariableBaseName` to 'τ'.
renameVariables = (expression, newVariableBaseName, _varStack, _newVarIdx) ->
  newVariableBaseName ?= 'xx'
  _newVarIdx ?= {idx:0} #Note: this is not a number because we need to mutate it.
  _varStack ?= {}
  
  # Note: `expression.boundVariable?` is currently equivalent to 
  # `(expression.type in ['existential_quantifier','universal_quantifier'])`.  
  # But what follows should generalise in case new quantifiers are added to awFOL.
  if expression.boundVariable?
    quantifier = expression
    variableNameToRename = quantifier.boundVariable.name
    _newVarIdx.idx += 1
    newName = "#{newVariableBaseName}#{_newVarIdx.idx}"
    _varStack[variableNameToRename] ?= []
    _varStack[variableNameToRename].push newName
    quantifier.boundVariable.name = newName
    if newVariableBaseName[0] in ['α','β','γ','τ']
      quantifier.boundVariable.type = 'term_metavariable'
    renameVariables quantifier.left, newVariableBaseName, _varStack, _newVarIdx
    # None of the awFOL quantifiers currently have `.right` but we would rename
    # `quantifier.right` as well if they did.
    if quantifier.right?
      renameVariables quantifier.right, newVariableBaseName, _varStack, _newVarIdx
    _varStack[variableNameToRename].pop()
    return expression
  
  # Note: `expression.termlist?` is currently short for testing `expression.type` 
  # against 'predicate' and 'identity'.  But doing it this way means it will work
  # for any extensions involving termlists.
  if expression.termlist?
    #I'm calling it a predicate but `expression.type` may be 'identity'; that will work fine too.
    predicate = expression
    for term in expression.termlist when term.type is 'variable'
      variable = term
      variableNameToRename = variable.name
      # Find out whether have already assigned this variable a new name.
      _varStack[variableNameToRename] ?= []
      theStack = _varStack[variableNameToRename]
      if theStack.length is 0
        # No, we have not already assigned this variable a new name (it's unbound).
        _newVarIdx.idx += 1
        newName = "#{newVariableBaseName}#{_newVarIdx.idx}"
        theStack.push newName
      # From here we can proceed regardless of whether we have already assigned this variable a new name.
      newName = _.last theStack
      variable.name = newName
      if newVariableBaseName[0] in ['α','β','γ','τ']
        variable.type = 'term_metavariable'
    #I assume that any expression with a termlist is terminal (i.e. has no `.left` or `.right`)
    return expression
  
  # If we are here expression isn't a quantifier and doesn't have a termlist.
  # So I assume it doesn't contain any variables to rename.
  if expression.left?
    renameVariables expression.left, newVariableBaseName, _varStack, _newVarIdx
  if expression.right?
    renameVariables expression.right, newVariableBaseName, _varStack, _newVarIdx
  return expression
    
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





