# This module provides the main point of entry.
# Use it like:
# ```
#     proof = '''
#       1. A      // premise
#       2. A and B
#     '''
#     result = proof.parse(proof)
#     if _.isString(result)
#       # There was an error parsing the proof (e.g. duplicate line numbers)
#     else
#       theProof = result
#       if theProof.verify()
#         # Everything checked out with your proof
#       else
#         errorList = theProof.listErrorMessages()
#       # You can also verify individual lines:
#       # Note: here the number 1 refers to the line of the text,
#       # not the label the proof writer might have assigned to the line.
#       aLine = theProof.getLine(1)   
#       isLineOk = aLine.verify()
#       if not isLineOk
#         errors = aLine.getErrorMessage()
# ```

blockParser = require './block_parser'
addLineNumbers = require './add_line_numbers'
addJustification = require './add_justification'
addSentences = require './add_sentences'
addStatus = require './add_status'
addVerification = require './add_verification'

parse = (proofText) ->
  try
    block = blockParser.parse proofText
    addLineNumbers.to block
    addJustification.to block
    addSentences.to block
    addStatus.to block
    addVerification.to block
  catch e
    return e.message
  
  return block
  
exports.parse = parse