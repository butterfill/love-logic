# Takes a `block_parser.Block` with extracted line numbers and justification
# but otherwise unprocessed strings of a yaFOL proof as its lines, 
# extracts and parses the yaFOL expressions (using `fol`),
# and adds the expressions the lines of the `Block`, noting any errors.
#

fol = require '../fol'
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
      # Now we add some functions that may be useful later.
      item.isIdenticalExpressionLeft = (e) ->
        return util.areIdenticalExpressions(@sentence.left, e)
      # Now we add some functions that may be useful later.
      item.isIdenticalExpressionRight = (e) ->
        return util.areIdenticalExpressions(@sentence.right, e)
      
      return undefined  # Keep walking.
  block.walk walker

  return block
  
exports.to = to