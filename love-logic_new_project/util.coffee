_ = require 'lodash'



# Walk through `expression` depth-first (unless `o.topDown`) applying `fn` to mutate it.
# This will visit termlists, terms, and bound variables.
# It will also visit substitution lists, individual substitutions 
# and their components (like `τ` and `α` in `φ[τ->α]`) and boxes (like `[a]φ`).
#
# Note that `fn` can receive null when visiting substitutions like `ψ[α->null]`.
#
# `fn` takes an expression, term, substitutions, termlist and returns.
#
# If you don't need to change `expression`, use `.walk` to save having to
# return things.
walkMutate = (expression, fn, o) ->
  if _.isArray(expression)  #e.g. it's a termlist, or `substitutions`
    return (walkMutate(e,fn,o) for e in expression)

  if expression is null
    return fn(expression)

  if o?.topDown? and o.topDown
    result = fn(expression)
  
  #console.log "walkMutate got #{expressionToString expression}"

  # Special case: the expression contains a box.
  if expression.box?
    fn._inBox = true
    expression.box = walkMutate expression.box, fn, o
    fn._inBox = undefined      # Set this to undefined so that fn._inBox? works.
  
  # Special case: the expression contains one or more subtitutions.
  # Note: we use _inSubCount because it's possible for substitutions to be nested.
  if expression.substitutions?
    fn._inSubCount ?= 0
    fn._inSubCount += 1
    fn._inSub = true
    # Note `expression.substitutions` is an array of substitutions.
    expression.substitutions = walkMutate expression.substitutions, fn, o
    fn._inSubCount -= 1
    fn._inSub = undefined if fn._inSubCount is 0    # Set this to undefined so that fn._inSub? works.
  if expression.type is 'substitution'
    fn._inSubLeft = true
    expression.from = walkMutate expression.from, fn, o
    fn._inSubLeft = undefined
    expression.to = walkMutate expression.to, fn, o

  # The standard parts of an expression.
  if expression.boundVariable?
    fn._inBoundVariable = true
    expression.boundVariable = walkMutate expression.boundVariable, fn, o
    fn._inBoundVariable = undefined
  if expression.termlist?
    expression.termlist = walkMutate expression.termlist, fn, o
  # Note: boxes contain `.term`s.  
  if expression.term?
    expression.term = walkMutate expression.term, fn, o
  if expression.left?
    expression.left = walkMutate expression.left, fn, o
  if expression.right?
    expression.right = walkMutate expression.right, fn, o
    
  if o?.topDown? and o.topDown
    return result
  else
    return fn(expression)
exports.walkMutate = walkMutate


# Walk through `expression` depth-first applying `fn` to mutate it.
# This will visit termlists, terms, and bound variables.
# It will also visit substitution lists, individual substitutions 
# and their components (like `τ` and `α` in `φ[τ->α]`) and boxes (like `[a]φ`).
# The return value from `fn` is discarded, except for the final time it is called
# on the whole expression.
walk = (expression, fn, o) ->
  wrappedFn = (e) ->
    # Because `.walkMutate` sets some properties on its `fn` parameter,
    # we want the function provided to walk to have these properties too.
    for own k,v of wrappedFn
      fn[k] = v
    
    fn(e)
    return e
  return walkMutate(expression, wrappedFn, o)
exports.walk = walk  


# Walk through `firstExp` and `otherExp` comparing them with `comparator`.
# Stop as soon as `comparator` returns false.
# This will visit termlists, terms, and bound variables.
# It will also visit substitution lists, individual substitutions 
# and their components (like `τ` and `α` in `φ[τ->α]`) and boxes (like `[a]φ`).
#
# Note that `fn` can receive primitive values, and also null (when visiting 
# substitutions like `ψ[α->null]`).
walkCompare = (firstExp, otherExp, comparator) ->

  if comparator
    if comparator._trace
      try 
        console.log "walkCompare: #{expressionToString firstExp} with #{expressionToString otherExp}"
    result = comparator(firstExp, otherExp)
    return result unless result is undefined
  
  if firstExp is null or otherExp is null
    return (firstExp is otherExp)

  for test in [_.isBoolean, _.isNumber, _.isString]
    if test(firstExp) or test(otherExp)
      return (firstExp is otherExp)
  
  if _.isArray(firstExp) or _.isArray(otherExp)
    return false unless _.isArray(firstExp) and _.isArray(otherExp) 
    return false unless firstExp.length is otherExp.length
    for e, idx in firstExp
      return false unless walkCompare(e, otherExp[idx], comparator)
    return true
  
  for attr in [ 'substitutions', 'from', 'to'       #for substitions
                'box','term'                        #for boxes
                'boundVariable'
                'termlist'
                'left', 'right'
                # attributes with primitive values:
                'type', 'name', 'letter', 'value'   
              ]
    if attr of firstExp or attr of otherExp
      return false unless attr of firstExp and attr of otherExp
      return false unless walkCompare(firstExp[attr], otherExp[attr], comparator)

  return true
exports.walkCompare = walkCompare

areIdenticalExpressions = walkCompare
exports.areIdenticalExpressions = areIdenticalExpressions


# This modifies `expression` in place.
# If you create a function that adds attributes to expressions, 
# update this function to be sure that it deletes them.
delExtraneousProperties = (expression) ->
  # For testing, this might be called indirectly with strings or numbers.
  # When that happens, just return what was sent.
  return expression unless expression?.type?
  
  return walk(expression, _delExtraneousProperties)

_delExtraneousProperties = (expression) ->
  return expression if expression is null   # (Because `null` can occur in substitutions.)
  for attr in ['location','symbol','parent']
    delete(expression[attr]) if attr of expression
  for own attr, value of expression
    if _.isFunction value
      delete(expression[attr])
  return expression
exports.delExtraneousProperties = delExtraneousProperties


# Returns a clone of expression with no extraneousProperties.
cloneExpression = (expression) ->
  
  # # Some things might be slow because `cloneExpression` is used a lot
  # # in doing substitutions (which get looped quite a bit).
  # # The following helps to trace where the calls are coming from 
  # # (which is basically `findMatches`, `applyMatches`, and the walker
  # # in `substitute.replace`)
  # try
  #   throw new Error "view stack"
  # catch e
  #   console.log "\tclone #{expressionToString expression} \t by #{e.stack.split('\n')[2].slice(0,20)} \t #{e.stack.split('\n')[3].slice(0,20)} \t #{e.stack.split('\n')[4].slice(0,20)} "
  
  if expression is null
    return null

  for test in [_.isBoolean, _.isNumber, _.isString]
    if test(expression)
      return expression
  
  if _.isArray(expression)
    return (cloneExpression(x) for x in expression)
  
  _clone = {}
  for attr in [ 'substitutions', 'from', 'to'       #for substitions
                'box','term'                        #for boxes
                'boundVariable'
                'termlist'
                'left', 'right'
                # attributes with primitive values:
                'type', 'name', 'letter', 'value'   
              ]
    if attr of expression
      _clone[attr] = cloneExpression(expression[attr])

  return _clone

exports.cloneExpression = cloneExpression


# Create a string representation of a fol expression.
# It uses the symbols that were specified when the expression was parsed (where these exist).
expressionToString = (expression) ->
  
  # Help with debug 
  for test in [_.isBoolean, _.isNumber, _.isString, _.isArray]
    if test(expression)
      return "#{expression}"
  
  
  walker = (e) ->
    return 'null' if e is null 

    for test in [_.isBoolean, _.isNumber, _.isString]
      if test(e)
        return "#{e}"

    if _.isArray(e)
      return e.join(',')

    if not e?.type?
      return '[undefined]' if e is undefined
    
    if e?.type in ['variable','name','term_metavariable']
      return e.name
    
    if e.type is 'box'
      return "[#{e.term}]"
    
    if e.type is 'termlist'
      return (x.name for x in e)
    
    if e.type is 'substitution'
      return "#{e.from}->#{e.to}"
    
    if e.box?
      aBox = e.box
    
    if e.substitutions
      theSubs = "[#{e.substitutions}]"
    
    if e.termlist? 
      symbol = e.name or e.symbol or e.type
      middle = "#{symbol}(#{e.termlist.join(',')})"
  
    if e.type is 'identity'
      symbol = (e.symbol or '=')
      [lhs,rhs] = e.termlist
      middle = "#{lhs} #{symbol} #{rhs}"
    
    if e.type in ['sentence_letter','expression_variable']
      middle = e.letter

    if e.type is 'value'
      middle = "#{((e.symbol if e.symbol?) or ('⊥' if e.value is "false") or e.value)}"
    
    bracketsNeeded = e.right?
    left_bracket = " "
    right_bracket = " "
    if bracketsNeeded 
      left_bracket = " (" 
      right_bracket = " )" 
    
    if e.boundVariable?
      symbol = (e.symbol or e.type)
      symbol = '∀' if symbol is 'universal_quantifier'
      symbol = '∃' if symbol is 'existential_quantifier'
      variableName = e.boundVariable
      middle = "#{symbol} #{variableName} #{left_bracket}#{e.left}#{e.right or ''}#{right_bracket}"
    
    if e.left? and not e.boundVariable?
      if not e.right?   # e.g. `not P`
        middle = "#{left_bracket}#{e.symbol or e.type or ''} #{e.left or ''}#{right_bracket}"
      else 
        middle = "#{left_bracket}#{e.left or ''} #{e.symbol or e.type or ''} #{e.right or ''}#{right_bracket}"
    return "#{aBox or ''}#{middle}#{theSubs or ''}"

  eClone = cloneExpression expression
  expressionStr = walkMutate eClone, walker
  
  _cleanUp = 
    remove_extra_whitespace :
      from : /\s+/g
      to : ' '
    remove_quantifier_space :
      from : /([∀∃])\s+/g
      to : "$1"
    remove_outer_brackets :
      #   (^\s*\()    --- start of line, any amount of space, left bracket
      #   ([\s\S]*)   --- anything at all
      #   (\)\s*$)    --- right bracket, any amount of space, end of line
      from : /(^\s*\()([\s\S]*)(\)\s*$)/
      to : '$2'
  for k, rplc of _cleanUp
    expressionStr = expressionStr.replace(rplc.from, rplc.to)
  return expressionStr.trim()
  
exports.expressionToString = expressionToString



# Takes a set of matches (from metavariables to terms or expressions) and 
# returns a string representation.
matchesToString = (matches) ->
  return "false" if matches is false 
  return "[no]" if not matches 
  _str = ""
  for own k,v of matches
    if v?.type? 
      _str = "#{_str}\n\t#{k} : #{expressionToString v}"
  return _str
exports.matchesToString = matchesToString



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
listTerms = (expression) ->
  terms = []
  fn = (expression) ->
    if expression.type in ['variable','name','term_metavariable']
      terms.push(expression)
    return terms
  return walk expression, fn
exports.listTerms = listTerms


# Returns an object with lists of the names of the metavariables (such as α and ψ)
# in various parts of an expression.
listMetaVariableNames = (expression) ->
  result = 
    inExpression : []
    inBox : []
    inSub : 
      left : []
      right : []
      
  walker = (expression) ->
    return expression if not expression?.type?
    return expression if expression.type isnt 'term_metavariable' and expression.type isnt 'expression_variable'
    theName = (expression.letter if expression?.letter?) or expression.name
    if walker._inSub?
      if walker._inSubLeft?
        result.inSub.left.push theName
      else
        result.inSub.right.push theName
    else
      if walker._inBox?
        result.inBox.push theName
      else
        result.inExpression.push theName
    return expression

  walk expression, walker
  return result
exports.listMetaVariableNames = listMetaVariableNames
    
    

