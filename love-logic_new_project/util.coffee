_ = require 'lodash'

# caution: this modifies the `expression`
delExtraneousProperties = (expression) ->
  # console.log "delete expression for: #{expression.type}"
  delete(expression.location) if expression.location?
  delete(expression.symbol) if expression.symbol?
  delExtraneousProperties(expression.left) if expression.left?
  delExtraneousProperties(expression.right) if expression.right?
  delExtraneousProperties(expression.boundVariable) if expression.boundVariable?
  delExtraneousProperties(expression.name) if expression.name? and expression.name?.type?
  if expression.termlist?
    for term in expression.termlist
      delExtraneousProperties term
  return expression    
exports.delExtraneousProperties = delExtraneousProperties


cloneExpression = (expression) ->
  return _.cloneDeep expression
exports.cloneExpression = cloneExpression


areIdenticalExpressions = (expression1, expression2) ->
  # Deal with primitive values (might be useful when testing using recursion)
  return true if expression1 is expression2 
  # Deal with null (useful in starting some loops with util.exhaust)
  return false if expression1 is null or expression2 is null
    
  e1 = cloneExpression expression1
  e2 = cloneExpression expression2
  return _.isEqual(delExtraneousProperties(e1), delExtraneousProperties(e2))
exports.areIdenticalExpressions = areIdenticalExpressions


# Create a string representation of a fol expression.
# It uses the symbols that were specified when the expression was parsed (where these exist).
# TODO: currently does not handle many cases
# TODO: check system for deciding when brackets are needed.
# TODO: clean up whitespace 
expressionToString = (expression) ->
  brackets_needed = expression.right?
  left_bracket = " "
  right_bracket = " "
  if brackets_needed 
    left_bracket = " (" 
    right_bracket = " )" 
  
  if expression.type is 'sentence_letter'
    return expression.letter
  if expression.type is 'not'
    return (expression.symbol or expression.type)+left_bracket+expressionToString(expression.left)+right_bracket
  
  # Is `expression` a quantifier?
  if expression.boundVariable?
    symbol = (expression.symbol or expression.type)
    variableName = expression.boundVariable.name
    return symbol+" #{variableName} "+left_bracket+expressionToString(expression.left)+right_bracket
  
  if expression.type is 'identity'
    symbol = (expression.symbol or expression.type)
    return termToString(expression.termlist[0])+" #{symbol} "+termToString(expression.termlist[1])

  if expression.termlist?
    symbol = (expression.name or expression.symbol or expression.type)
    termStringList = (termToString(t) for t in expression.termlist)
    return "#{symbol}(#{termStringList.join(', ')})"
  
  result = [left_bracket]
  if expression.left?
    result.push(expressionToString(expression.left))
  if expression.type?
    result.push(expression.symbol or expression.type)
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
  
  # From now on, we know that `left` and `right` are of the same type.

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
  
  # Negated atomic statements are sorted according to the sort order of what they negate.
  if left.type is 'not'
    return atomicExpressionComparator left.left, right.left
  
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

# A comparator for some expression types.
_typeComparator = (left, right) ->
  order = {sentence_letter:0, predicate:1, identity:2, "not":3, "name":4, "variable":5}
  return order[left]-order[right]
  





  