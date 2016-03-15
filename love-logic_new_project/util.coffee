_ = require 'lodash'



# Walk through `expression` depth-first (unless `o.topDown`) applying `fn` to mutate it.
# This will visit termlists, terms, and bound variables.
# It will also visit substitution lists, individual substitutions 
# and their components (like `τ` and `α` in `φ[τ-->α]`) and boxes (like `[a]φ`).
#
# Note that `fn` can receive null when visiting substitutions like `ψ[α-->null]`.
#
# `fn` takes an expression, term, substitutions, termlist and returns.
#
# If you don't need to change `expression`, use `.walk` to save having to
# return things.
#
# NB: This (and all the walking things) will throw if given `undefined`;
# this is useful because getting `undefined` is almost certainly an error.
walkMutate = (expression, fn, o) ->
  if _.isArray(expression)  #e.g. it's a termlist, or `substitutions`
    return (walkMutate(e,fn,o) for e in expression)

  if expression is null
    return fn(expression)

  if o?.topDown? and o.topDown
    result = fn(expression)
  
  if fn._trace
    console.log "walkMutate got #{util.expressionToString expression}"

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
# and their components (like `τ` and `α` in `φ[τ-->α]`) and boxes (like `[a]φ`).
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
# and their components (like `τ` and `α` in `φ[τ-->α]`) and boxes (like `[a]φ`).
#
# Note that `fn` can receive primitive values, and also null (when visiting 
# substitutions like `ψ[α-->null]`).
walkCompare = (firstExp, otherExp, comparator, o={}) ->

  if comparator
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

areIdenticalExpressions = (firstExp, otherExp, o) ->
  return walkCompare(firstExp, otherExp, undefined, o)
exports.areIdenticalExpressions = areIdenticalExpressions


find = (expression, finder) ->
  decision = finder(expression)
  return decision unless decision is undefined
  
  return undefined if expression is null
  
  for test in [_.isBoolean, _.isNumber, _.isString]
    if test(expression)
      return undefined
  
  if _.isArray(expression)
    for x in expression
      decision = find(x, finder)
      return decision unless decision is undefined
    return undefined
  
  for attr in [ 'substitutions', 'from', 'to'       #for substitions
                'box','term'                        #for boxes
                'boundVariable'
                'termlist'
                'left', 'right'
                # attributes with primitive values:
                'type', 'name', 'letter', 'value'   
              ]
    if attr of expression
      decision = find(expression[attr], finder)
      return decision unless decision is undefined

  return undefined
exports.find = find  
  
# `mutateFinder` returns on object containing two things: `newExpression` 
# which replaces the expression it recieves (unless this is undefined,
# which means no change is made); and `aResult`, which will be returned 
# wrapped in an object along with `mutatedExpression`.
# For convenience, `mutateFinder` may return undefined (which means keep going
# without doing anything).
walkMutateFindOne = (expression, mutateFinder, o) ->
  # `theResult` stores the result of applying `mutateFinder` to 
  # `expression` and its parts.
  theResult = undefined
  
  wrappedFn = (e) ->
    # Once `mutateFinder` has yielded a result, we do nothing.
    return e unless theResult is undefined

    # Because `.walkMutate` sets some properties on its `fn` parameter,
    # let `mutateFinder` have these properties too.
    for own k,v of wrappedFn
      mutateFinder[k] = v
    # Note: `mutateFinder` can return undefined (that's why `or {}`).
    {newExpression, aResult } = mutateFinder(e) or {} 
    theResult = aResult
    return newExpression unless newExpression is undefined
    return e

  mutatedExpression = walkMutate(expression, wrappedFn, o)
  return {theResult, mutatedExpression}
exports.walkMutateFindOne = walkMutateFindOne

  

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
  # # (which is basically `findMatches`, `match.apply`, and the walker
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

SYMBOLS =
  'not' : '¬'
  'false' : "⊥"
  'identity' : "="
  'and' : "∧"
  'arrow' : "→"
  'double_arrow' : "↔"
  'or' : "∨"
  'nor' :  "↓"
  'nand' : "↑"
  'universal_quantifier' : "∀"
  'existential_quantifier' : "∃" 
exports.SYMBOLS = SYMBOLS

# Create a string representation of a fol expression.
# It uses the symbols that were specified when the expression was parsed (where these exist) unless param `o.replaceSymbols` is true.
expressionToString = (expression, o={}) ->
  o.symbols ?= SYMBOLS
  
  # Help with debug 
  for test in [_.isBoolean, _.isNumber, _.isString, _.isArray]
    if test(expression)
      return "#{expression}"

  # This counter is used to index the symbols when param `o.wrapWithDivs` is true.
  symbolNum = 0
  
  walker = (e) ->
    return 'null' if e is null 
    
    symbolNum += 1
    
    for test in [_.isBoolean, _.isNumber, _.isString]
      if test(e)
        return "#{e}"

    if _.isArray(e)
      return e.join(',')

    if not e?.type?
      return '[undefined]' if e is undefined
    
    if e.type in ['variable','name','term_metavariable']
      return e.name unless e.substitutions
      return "{#{e.name}[#{e.substitutions}]}"
    
    if e.type is 'box'
      return "[#{e.term}]"
    
    if e.type is 'termlist'
      return (x.name for x in e)
    
    if e.type is 'substitution'
      return "#{e.from}-->#{e.to}"
    
    if e.box?
      aBox = e.box
    
    if e.substitutions
      theSubs = "[#{e.substitutions}]"
    
    if e.termlist? 
      symbol = e.name or e.symbol or o.symbols[e.type] or e.type
      middle = "#{symbol}(#{e.termlist.join(',')})"
  
    if e.type is 'identity'
      symbol = (e.symbol or '=')
      [lhs,rhs] = e.termlist
      middle = "#{lhs}#{symbol}#{rhs}"
    
    if e.type in ['sentence_letter','expression_variable']
      middle = e.letter

    if e.type is 'value'
      middle = "#{((e.symbol if e.symbol?) or (o.symbols.false if e.value is "false" or e.value is false) or e.value)}"
    
    bracketsNeeded = e.right?
    left_bracket = ""
    right_bracket = ""
    if bracketsNeeded 
      left_bracket = "(" 
      right_bracket = ")" 

    # All of the following need the `symbol`, e.g. `and` or `arrow`
    symbol = e.symbol or o.symbols[e.type] or ''
    if o.wrapWithDivs
      symbol = "<span class='_symbolWrap' data-symbolNum='#{symbolNum}'>#{symbol}</span>"
    
    if e.boundVariable?
      # e is a quantifier phrase
      variableName = e.boundVariable
      if o.symbols.universal_quantifier is ''
        # Copi style
        middle = "(#{symbol}#{variableName})#{left_bracket}#{e.left}#{e.right or ''}#{right_bracket}"
      else
        middle = "#{symbol}#{variableName} #{left_bracket}#{e.left}#{e.right or ''}#{right_bracket}"
    
    if e.left? and not e.boundVariable?
      if not e.right?   # e.g. `not P`
        middle = "#{left_bracket}#{symbol}#{e.left or ''}#{right_bracket}"
      else 
        middle = "#{left_bracket}#{e.left or ''} #{symbol} #{e.right or ''}#{right_bracket}"
        
    if o.wrapWithDivs
      middle = "<span class='_expressionWrap'>#{middle}</span>"
      
    return "#{aBox or ''}#{middle}#{theSubs or ''}"

  if o.replaceSymbols
    eClone = cloneExpression expression
  else
    # Use `_.cloneDeep` to preserve extraneous properties here
    eClone = _.cloneDeep expression
  expressionStr = walkMutate eClone, walker
  
  _cleanUp = 
    remove_extra_whitespace :
      from : /\s+/g
      to : ' '
    remove_space_between_quantifiers : 
      from : /([∀∃].)\s+([∀∃].)/
      to: '$1$2'
    remove_space_between_quantifier_and_brackets : 
      from : /([∀∃].)\s+(\()/
      to: '$1$2'
    remove_outer_brackets :
      #   (^\s*\()    --- start of line, any amount of space, left bracket
      #   ([\s\S]*)   --- anything at all
      #   (\)\s*$)    --- right bracket, any amount of space, end of line
      from : /(^\s*\()([\s\S]*)(\)\s*$)/
      to : '$2'
  unless o.symbols.universal_quantifier is ''
    # no cleanup for Copi style (will break!)
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
# This does not include variables attached to a quantifier.
listTerms = (expression) ->
  terms = []
  fn = (expression) ->
    if expression.type in ['variable','name','term_metavariable']
      terms.push(expression)
  walk expression, fn
  return terms
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
    
    
# A list of everything that counts as an expression in awFOL.
expressionTypes = [
  'existential_quantifier'
  'universal_quantifier'
  'and'
  'or'
  'nand'
  'nor'
  'arrow'
  'double_arrow'
  'not'
  'value'
  'predicate'
  'identity'
  'expression_variable'
  'sentence_letter'
]
exports.expressionTypes = expressionTypes

termTypes = [
  'name'
  'variable'
  'term_metavariable'
]
exports.termTypes = termTypes

atomicSentenceTypes = [
  'sentence_letter'
  'expression_variable'
  'identity'
  'predicate'
]
exports.atomicSentenceTypes = atomicSentenceTypes

# Return true if an expression contains substitutions.
expressionContainsSubstitutions = (expression) ->
  finder = (e) ->
    return true if e?.substitutions?
    return undefined
  test = find expression, finder
  return true if test is true
  return false
exports.expressionContainsSubstitutions = expressionContainsSubstitutions

# Return true if sub is in expression.substitutions.
expressionHasSub = (expression, sub) ->
  return false unless expression?.substitutions? 
  for candidateSub in expression.substitutions
    if areIdenticalExpressions(candidateSub.from, sub.from) and areIdenticalExpressions(candidateSub.to, sub.to) 
      return true
  return false
exports.expressionHasSub = expressionHasSub

