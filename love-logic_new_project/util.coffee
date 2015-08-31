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