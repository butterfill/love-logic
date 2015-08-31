_ = require 'lodash'

# caution: this modifies the `expression`
delExtraneousProperties = (expression) ->
  # console.log "delete expression for: #{expression.type}"
  delete(expression.location) if expression.location?
  delete(expression.symbol) if expression.symbol?
  delExtraneousProperties(expression.left) if expression.left?
  delExtraneousProperties(expression.right) if expression.right?
  delExtraneousProperties(expression.variable) if expression.variable?
  delExtraneousProperties(expression.name) if expression.name? and expression.name?.type?
  if expression.termlist?
    for term in expression.termlist
      delExtraneousProperties term
  return expression  
  
exports.delExtraneousProperties = delExtraneousProperties

areIdenticalExpressions = (expression1, expression2) ->
  e1 = _.cloneDeep expression1
  e2 = _.cloneDeep expression2
  return _.isEqual(delExtraneousProperties(e1), delExtraneousProperties(e2))
exports.areIdenticalExpressions = areIdenticalExpressions

# Create a string representation of a fol expression.
# TODO: currently does not handle many cases
# TODO: check system for deciding when brackets are needed.
# TODO: clean up whitespace 
expressionToString = (expression) ->
  result = []
  brackets_needed = expression.left?.right?
  left_bracket = " "
  right_bracket = " "
  if brackets_needed 
    left_bracket = " (" 
    right_bracket = " )" 
  
  if expression.type is 'sentence_letter'
    return expression.letter
  if expression.type is 'not'
    return expression.symbol+left_bracket+expressionToString(expression.left)+right_bracket
    
  if expression.left?
    result.push(left_bracket)
    result.push(expressionToString(expression.left))
    result.push(right_bracket)
  if expression.type?
    result.push(expression.symbol)
  if expression.right?
    result.push(left_bracket)
    result.push(expressionToString(expression.right))
    result.push(right_bracket)
  return result.join(" ")
exports.expressionToString = expressionToString