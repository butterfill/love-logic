_ = require 'lodash'
fol = require './fol'

    
# evaluates `sentenceText` (a sentence of FOL)
# against world `world`: ie returns true if the sentence
# is true in the world and false otherwise
#
evaluate = (sentenceText, world) ->
  e = new Evaluator(sentenceText, world)
  return e.evaluate()

# Useful to have a prototype so we can keep track of
# the world in which we're evaluating the sentence, and 
# the values assigned to variables (for evaluating quantifiers).
Evaluator = (sentenceText, @world) ->
  @sentence = fol.parse(sentenceText)
  # `varStack` is used in interpreting quantifier expressions.
  # it is a map from variable names to 
  @varStack = {}
  # @logSentence()
  return @
  
Evaluator::logSentence = ->
  console.log "sentence #{JSON.stringify @sentence, null, 4}"  

Evaluator::evaluate = (sentence) ->
  sentence = sentence ? @sentence
  
  if sentence.type is 'value' 
    return sentence.value
  
  if sentence.type is 'and'
    return @evaluate(sentence.left) and @evaluate(sentence.right)
  
  if sentence.type is 'nand'
    return not (@evaluate(sentence.left) and @evaluate(sentence.right))
  
  if sentence.type is 'or'
    return @evaluate(sentence.left) or @evaluate(sentence.right)

  if sentence.type is 'nor'
    return not (@evaluate(sentence.left) or @evaluate(sentence.right))
  
  if sentence.type is 'not'
    return not @evaluate(sentence.left)
  
  if sentence.type is 'arrow'
    return (not @evaluate(sentence.left)) or @evaluate(sentence.right)
  
  if sentence.type is 'double_arrow'
    return (@evaluate(sentence.left) is @evaluate(sentence.right))
  
  if sentence.type is 'sentence_letter'
    return @world[sentence.letter]
  
  if sentence.type is 'predicate' or sentence.type is 'identity'
    predicate = sentence
    if predicate.type is 'identity'
      predicateExtension = ([x,x] for x in @world.domain)
    else
      predicateExtension = @world.predicates[predicate.name]
    valuesOfPredicateTerms = @instantiate_terms(predicate.termlist)
    # console.log "predicateExtension #{JSON.stringify predicateExtension, null, 4}"
    # console.log "valuesOfPredicateTerms #{JSON.stringify valuesOfPredicateTerms, null, 4}"
    # The following test uses lodash's `_.where` function to see whether the valuesOfPredicateTerms
    # are in the predicateExtension.
    test = _.where predicateExtension, valuesOfPredicateTerms
    return test.length>0 
  
  if sentence.type is 'existential_quantifier' or sentence.type is 'universal_quantifier'
    boundVariable = sentence.boundVariable
    variableName = boundVariable.name
    if not (variableName of @varStack)
      @varStack[variableName] = []
    self = @
    theTest = _.some if sentence.type is 'existential_quantifier' 
    theTest = _.all if sentence.type is 'universal_quantifier' 
    return theTest @world.domain, (object) ->
      self.varStack[variableName].push(object)
      res = self.evaluate sentence.left
      self.varStack[variableName].pop()
      return res
      
  throw new Error "e (evaluate inner) could not evaluate sentence #{JSON.stringify sentence, null, 4}"  


Evaluator::instantiate_terms = (termlist) ->
  res = []
  for term in termlist
    if term.type is 'name'
      if not (term.name of @world.names)
        throw new Error "The name #{term.name} is not defined in this world."
      res.push @world.names[term.name]
    else if term.type is 'variable'
      variable = term
      if not (variable.name of @varStack)
        throw new Error "The variable #{variable.name} is not bound by any quantifier."
      res.push _.last @varStack[variable.name]
    else
      throw new Error "Encountered a term of unknown type: #{JSON.stringify term, null, 4}"
  return res


exports.evaluate = evaluate  