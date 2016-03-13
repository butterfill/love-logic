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
fol = require './parser/awFOL'
match = require './match'

_subsForPNF = 
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
subsForPNF = {}
for k,v of _subsForPNF
  from = fol.parse v.from
  util.delExtraneousProperties from
  to = fol.parse v.to
  util.delExtraneousProperties to
  theSub = {from:from, to:to}
  subsForPNF[k] = theSub
exports.subsForPNF = subsForPNF


# To be useful, these substitutions depend on the standard sort order, 
# as defined in `normalForm.sortPNFExpression`.
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
  # given how `normalForm.rebuildExpression` works?
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
  # The following are useful because of the sorting provided by `normalForm.sortPNFExpression`.
  # E.g. this sorting guaratees that not φ comes after φ in a disjunction.
  contradiction_and :
    from : 'φ and not φ'
    to : 'false'
  contradiction_and_left :
    from : 'φ and (not φ and ψ)'
    to : 'false'
  contradiction_and_right : # Do we need this (`normalForm.rebuildExpression` should mean it doesn't happen)?
    from : '(ψ and φ) and not φ'
    to : 'false'
  taut_or :
    from : 'φ or not φ'
    to : 'true'
  taut_and_left :
    from : 'φ or (not φ or ψ)'
    to : 'true'
  taut_and_right :       # Do we need this (`normalForm.rebuildExpression` should mean it doesn't happen)?
    from : '(ψ or φ) or not φ'
    to : 'true'
  # The following are not needed because we now use
  # the more general `normalForm.removeQuantifiersThatBindNothing`.
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
  theMatches = match.findWithoutApplyingSubs expression, sub.from 
  if theMatches 
    return match.apply(sub.to, theMatches)
  else 
    return expression 
exports.doSub = doSub

# Apply the `sub` to the `expression` and all its components.  
# (See doSub.)
doSubRecursive = (expression, sub, o={}) ->
  walker = (e) ->
    return e if e is null
    return e if _.isArray(e)
    return e if e.type? and e.type is 'box'
    return doSub(e, sub)
  return util.walkMutate(expression, walker)
exports.doSubRecursive = doSubRecursive


# Replaces all instances of `whatToReplace.from` with `whatToReplace.to` in `expression`.
# E.g.
#    the expression `fol.parse "Loves(x,b)"` 
#    would be turned into `Loves(a,b)` with whatToReplace = {from:VARIABLE_X, to:NAME_A}
#
# Note: This will not take into account whether or not a variable is bound
# when replacing it.
#
# Special feature for substitutions like `[a-->null]`: if it actually finds a match
# to replace, it will throw Error with `.messsage` "_internal: replace to null".
replace =  (expression, whatToReplace, o={}) ->
  toFind = whatToReplace.from
  toReplace = whatToReplace.to
  walker = (e) ->
    return e if e is null or _.isArray(e)

    # Do not replace expressions or names in substitutions.
    return e if walker._inSub

    if util.areIdenticalExpressions(e, toFind)
      if toReplace is null
        throw new Error "_internal: replace to null"
      return util.cloneExpression(toReplace)
    return e

  if o.noClone
    e = expression
  else
    e = util.cloneExpression(expression) 
  return util.walkMutate(e, walker)

exports.replace = replace


# Given `A[A-->B]` as the `expression`, return `B`.
# (By contrast, `doSub` and `doSubRecursive` perform substitutions using 
# patterns like `φ arrow ψ` to `(not φ) or ψ`; this is about applying
# the substitutions that are part of an awFOL expression (as in `A[A-->B]`).
#
# Note: `expression` will not be mutated.
applySubstitutions = (expression) ->
  # We are going to do this by starting at a point innermost in the expression
  # and walking outwards, so that `(A[A-->B] and C)[B-->D]` returns `D and C`.
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




