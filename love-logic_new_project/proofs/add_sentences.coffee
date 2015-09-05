# Takes a `block_parser.Block` with extracted line numbers and justification
# but otherwise unprocessed strings of a yaFOL proof as its lines, 
# extracts and parses the yaFOL expressions (using `fol`),
# and adds the expressions the lines of the `Block`, noting any errors.
#

fol = require '../fol'
substitute = require '../substitute'
util = require '../util'


# This is the main function.
# Add sentences to the lines of `block`.
to = (block) ->
  
  walker = 
    visit : (item) ->
      return undefined if item.type isnt 'line'
      return undefined if item.sentence? or item.sentenceErrors?
      line = item
      line.sentenceText = item.content
      try
        line.sentence = fol.parse line.sentenceText
      catch e
        line.sentenceErrors = e.message
      
      # Now we add some functions that may be useful later.
      
      item.isIdenticalExpression = (e) ->
        return util.areIdenticalExpressions(@sentence, e)
      item.leftIsIdenticalExpression = (e) ->
        return util.areIdenticalExpressions(@sentence.left, e)
      item.rightIsIdenticalExpression = (e) ->
        return util.areIdenticalExpressions(@sentence.right, e)
      
      item.matches = (pattern, _matches, o) ->
        return substitute.findMatches @sentence, pattern, _matches, o
      
      return undefined  # Keep walking.
  block.walk walker

  return block
  
exports.to = to