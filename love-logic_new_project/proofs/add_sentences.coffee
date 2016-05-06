# Takes a `block_parser.Block` with extracted line numbers and justification
# but otherwise unprocessed strings of a awFOL proof as its lines, 
# extracts and parses the awFOL expressions (using `fol`),
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
      
      line.canBeDecomposed = () ->
        sentence = line.sentence
        # the sentence could not be parsed:
        return false unless sentence?
        # The sentence is atomic:
        return false unless sentence.left?
        # the sentence is `not phi`  where `phi` is atomic
        return false if (sentence.type is 'not' and not sentence.left.left?)
        return true
      
      return undefined  # Keep walking.
  block.walk walker

  return block
  
exports.to = to