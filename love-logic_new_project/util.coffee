_ = require 'lodash'


  
# Walk through `expression` depth-first applying `fn`.
# This will visit terms and bound variables.
walk = (expression, fn) ->
  return null if not expression?
  if _.isArray(expression)  #e.g. it's a termlist
    for e in expression
      walk e, fn
  if expression.boundVariable?
    walk expression.boundVariable, fn
  if expression.termlist?
    walk expression.termlist, fn
  if expression.left?
    walk expression.left, fn
  if expression.right?
    walk expression.right, fn
  return fn(expression)
exports.walk = walk  


# This modifies `expression` in place.
# It is useful when we want to compare expressions ignoring things like
# location information and symbols provided by the parser.  (See `areIdenticalExpressions`.)
# If you create a function that adds attributes to expressions, 
# update this function to be sure that it deletes them.
delExtraneousProperties = (expression) ->
  # For testing, this might be called indirectly with strings or numbers.
  # When that happens, just return what was sent.
  return expression unless expression?.type?
  
  return walk(expression, _delExtraneousProperties)

_delExtraneousProperties = (expression) ->
  for attr in ['location','symbol','parent']
    delete(expression[attr]) if attr of expression
  return expression
exports.delExtraneousProperties = delExtraneousProperties

cloneExpression = (expression) ->
  return delExtraneousProperties(_.cloneDeep(expression))
exports.cloneExpression = cloneExpression


areIdenticalExpressions = (expression1, expression2) ->
  # Deal with primitive values (might be useful when testing using recursion)
  return true if expression1 is expression2 
  # Deal with null (useful in starting some loops with util.exhaust)
  return false if expression1 is null or expression2 is null
    
  e1 = cloneExpression expression1
  e2 = cloneExpression expression2
  delExtraneousProperties e1 
  delExtraneousProperties e2 
  return _.isEqual(e1, e2)
exports.areIdenticalExpressions = areIdenticalExpressions


# Create a string representation of a fol expression.
# It uses the symbols that were specified when the expression was parsed (where these exist).
# TODO: what cases does this not yet handle?
# TODO: check system for deciding when brackets are needed.
_cleanUp = 
  whitespace :
    from : /\s+/g
    to : ' '
  quantifier_space :
    from : /([∀∃])\s+/g
    to : "$1"
expressionToString = (expression) ->
  result = _expressionToString(expression)
  # Now clean up whitespace.
  result = result.trim()
  for k, rplc of _cleanUp
    result = result.replace(rplc.from, rplc.to)
  return result
_expressionToString = (expression) ->
  if expression is undefined or expression is null
    return "[undefined or null expression]"
  brackets_needed = expression.right?
  left_bracket = " "
  right_bracket = " "
  if brackets_needed 
    left_bracket = " (" 
    right_bracket = " )" 
  
  if expression.type in ['sentence_letter','expression_variable']
    return expression.letter
    
  if expression.type is 'not'
    symbol = expression.symbol or expression.type
    return "#{symbol}#{left_bracket}#{expressionToString(expression.left)}#{right_bracket}"
  
  # Is `expression` a quantifier?
  if expression.boundVariable?
    symbol = (expression.symbol or expression.type)
    symbol = '∀' if symbol is 'universal_quantifier'
    symbol = '∃' if symbol is 'existential_quantifier'
    variableName = expression.boundVariable.name
    return "#{symbol} #{variableName} #{left_bracket}#{expressionToString(expression.left)}#{right_bracket}"
  
  if expression.type is 'identity'
    symbol = (expression.symbol or '=')
    return termToString(expression.termlist[0])+" #{symbol} "+termToString(expression.termlist[1])

  if expression.termlist?
    symbol = (expression.name or expression.symbol or expression.type)
    termStringList = (termToString(t) for t in expression.termlist)
    return "#{symbol}(#{termStringList.join(',')})"
  
  result = [left_bracket]
  if expression.left?
    result.push(expressionToString(expression.left))
  if expression.type?
    result.push(expression.symbol or expression.type or "!unknown expression!")
  if expression.right?
    result.push(expressionToString(expression.right))
  result.push(right_bracket)
  return result.join(" ")
exports.expressionToString = expressionToString

termToString = (term) ->
  return term.name
exports.termToString = termToString


# Check whether two lists have the same elements.
# The default comparitor is _.isEqual (which does deep comparisons).
# (In the `symmetry` module, this will be used with comparator set to areEquivalent.)
sameElementsDeep = (list1, list2, comparator) ->
  comparator = comparator ? _.isEqual
  
  return false if (list1.length isnt list2.length)
  
  whatWeMatchedInList2 = []
  for target, targetIdx in list1
    for candidate, candidateIdx in list2 
      #check we didn't already match this element: each element can only be matched once
      if not (candidateIdx in whatWeMatchedInList2)
        if comparator(target, candidate)
          whatWeMatchedInList2.push candidateIdx
          break
    # end of attempt to match `target`
    return false unless (candidateIdx in whatWeMatchedInList2)
  # If we're here:
  #     (a) all elements of list1 were matched to distinct elements in list2
  #     (b) list1 and list2 have the same length
  return true

exports.sameElementsDeep = sameElementsDeep

# Apply `fn` to `expression` until doing so makes no difference 
# according to `comparitor` and then return the result.
# This function uses clones so `expression` itself will not be modified.
# Note: `fn` must return an expression.
exhaust = (expression, fn, comparator) ->
  comparator ?= areIdenticalExpressions
  pre = null
  post = expression
  while not comparator(pre, post)
    pre = post
    post = fn(cloneExpression(pre))
  return post
exports.exhaust = exhaust  


listOfAtomicExpressionsComparator = (left, right) ->
  # Shorter lists go first.
  return -1 if left.length < right.length
  return 1 if left.length > right.length
  
  for leftElement, idx in left
    result = atomicExpressionComparator leftElement, right[idx]
    return result unless result is 0
  
  return 0
exports.listOfAtomicExpressionsComparator = listOfAtomicExpressionsComparator


atomicExpressionComparator = (left, right) ->
  result = _typeComparator(left.type, right.type)
  return result unless result is 0
  
  # Negated atomic statements are sorted according to the sort order of what they negate.
  if left.type is 'not' and right.type isnt 'not'
    test = atomicExpressionComparator left.left, right
    return 1 if test is 0  #not comes after the unnegated thing
    return test

  if left.type isnt 'not' and right.type is 'not'
    test = atomicExpressionComparator left, right.left
    return -1 if test is 0  #not comes after the unnegated thing
    return test

  if left.type is 'not' and right.type is 'not'
    return atomicExpressionComparator left.left, right.left
    
  # From now on, we know that `left` and `right` are of the same type.

  # Truth values are sorted by value
  if left.value?
    return -1 if left.value < right.value
    return 1 if left.value > right.value
    return 0

  # Sentence letters are sorted by name.
  if left.letter?
    return -1 if left.letter < right.letter
    return 1 if left.letter > right.letter
    return 0
  
  # Predicates are sorted by name.
  if left.name?
    return -1 if left.name < right.name
    return 1 if left.name > right.name
    return 0
  
  # Identity statements are sorted like this.
  if left.termlist?
    leftToCompare = max left.termlist[0], left.termlist[1], termComparator
    rightToCompare = max right.termlist[0], right.termlist[1], termComparator
    return termComparator leftToCompare, rightToCompare
  
  throw new Error "Could not do a comparison for #{JSON.stringify left,null,4}"
exports.atomicExpressionComparator = atomicExpressionComparator


max = (left, right, comparator) ->
  return left unless comparator(left,right)>0
  return right


# A comparator for variables and names only.
termComparator = (left, right) ->
  result =  _typeComparator(left.type, right.type)
  return result unless result is 0
  
  return -1 if left.name < right.name
  return 1 if left.name > right.name
  return 0
exports.termComparator = termComparator


# A comparator for some expression types.
_typeComparator = (left, right) ->
  if left is 'not' or right is 'not'
    # we do not sort nots
    return 0
  order = {value:5, sentence_letter:10, predicate:20, identity:30, "name":50, "variable":60}
  return -1 if  order[left] < order[right]
  return 1 if  order[left] > order[right]
  return 0

  
# Returns a list of terms in `expression`.
# (What is returned are the actual terms (objects), not their names.)
# This does not include variables bound by a quantifier.
# You should not normally set parameter `_terms` (this is used for recursion).
listTerms = (expression) ->
  terms = []
  fn = (expression) ->
    if expression.type in ['variable','name','term_metavariable']
      terms.push(expression)
    return terms
  return walk expression, fn

exports.listTerms = listTerms

# Adds the `parent` property to expression and every component of it.
addParents =  (expression, _parent) ->
  _parent ?= null
  expression.parent = _parent
  
  # This expression is parent to all its children
  _parent = expression
  
  if _.isArray(expression)  #e.g. it's a termlist
    for e in expression
      addParents e, _parent
  if expression.boundVariable?
    addParents expression.boundVariable, _parent
  if expression.termlist?
    addParents expression.termlist, _parent
  if expression.left?
    addParents expression.left, _parent
  if expression.right?
    addParents expression.right, _parent
  return expression
exports.addParents = addParents








  