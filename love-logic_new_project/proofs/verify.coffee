# Verify whether a proof is correct.

_ = require 'lodash'

blockParser = require './block_parser'
lineNumbers = require './line_numbers'
addJustification = require './add_justification'
addSentences = require './add_sentences'


parseProof = (proofText) ->
  block = blockParser.parse proofText
  lineNumbers.addNumbers block
  addJustification.to block
  addSentences.to block
  return block

# Verifies whether the line at `lineNumber` is correct, 
# returning error messages if not.
# `lineNumber` is the 1-based number in the proofText.
# `proofText` may be a parsed proof (used internally).
line = (lineNumber, proofText) ->
  if _.isString proofText
    proofText = parseProof proofText
  proof = proofText

  line = proof.goto lineNumber
  if not line
    throw new Error "Could not find line #{lineNumber} in #{proofText}"
  
  result = 
    verified: false 
    message : ''
    addMessage : (txt) -> 
      @message = "#{@message} #{txt}".trim()
    areThereErrors : ->
      return true if @sentenceErrors? or @justificationErrors?
      return false
  
  # We can't go on if there are errors.
  if line.sentenceErrors? 
    result.sentenceErrors = line.sentenceErrors 
    result.addMessage 'There were errors with the sentence you wrote.'
  if line.justificationErrors?  
    result.justificationErrors = line.justificationErrors
    result.addMessage 'There were errors with the justification you gave.'
  if result.areThereErrors()
    return result
  
  # Blank lines are fine; we don't need to check those.
  if not line.sentence?  and line.content?.trim() is ''
    result.verified = true
    return result
  
  # A line missing justification is a mistake.
  # (Note that justification is automatically added to premises 
  # by the `add_justification` module.)
  if not line.justification?
    result.addMessage 'You did not provide any justification'
    return result
  
  # From here on, we have a sentence and justification.
  
  # First, check that the lines cited are legit.
  if not linesCitedAreOk(line)
    result.addMessage 'you cited lines that cannot be cited here (either they do not exist, or they are below this line, or else they occur above but in a closed block).'
    return result
  
  result = checkRequirements line, result
  return result
  
exports.line = line


linesCitedAreOk = (line) ->
  numbers = line.justification.numbers
  return true if not numbers
  for num in numbers
    found = line.findLineOrBlock(num)
    return false if not found
  return true


checkRequirements = (line, result) ->
  # `connective` is 'and', 'reit' or 'premise' or ...
  connective = line.justification.rule.connective
  # `intronation` is 'elim' or 'intro'
  intronation = line.justification.rule.variant.intronation
  # `side` is 'left' or 'right'
  side = line.justification.rule.variant.side

  reqList = requirements[connective]
  if intronation
    reqList = reqList[intronation]
    
  if not reqList.both? and not reqList.left?
    return checkTheseRequirements(reqList, line, result)
  
  if not reqList.both? and side
    reqList = reqList[side]
    return checkTheseRequirements(reqList, line, result)
  
  result = checkTheseRequirements(reqList.both, line, result)
  if not result.verified
    return result
  
  if side 
    if not reqList[side]?
      return result
    return checkTheseRequirements(reqList[side], line, result)
  
  if not reqList.left?
    return result
  
  # In some cases we will have to check both left and right
  # versions of a rule.  Success with either counts as success.
  oldMessage = result.message
  result.message = ''
  result = checkTheseRequirements(reqList.left, line, result)
  if result.verified 
    result.message = oldMessage
    return result 
  leftMessage = result.message
  result.message = ''
  result = checkTheseRequirements(reqList.right, line, result)
  if result.verified
    # Remove any fail message from having checked the left requirements.
    result.message = oldMessage
  rightMessage = result.message 
  # Remove any closing period from the end of `leftMessage`.
  leftMessage = leftMessage.replace /\.$/, ''
  result.message = oldMessage + "Either: #{leftMessage}, or else #{rightMessage}"
  return result
  
  
checkTheseRequirements = (reqList, line, result) ->
  for req in reqList
    itPassed = req(line)
    if itPassed isnt true
      result.verified = false
      update = itPassed
      update result
      return result
  # It passed all the requirements.
  result.verified = true
  return result

      
test = {}
test.throw = ->
  throw new Error "Not implemented yet!"

test.singleNumberCited = (line) ->
  if line.justification.numbers?.length isnt 1
    # The test has failed, so we return a function that updates `result`.
    return (result) ->
      # Note: when a sentence in message starts lowercase, it will be prefixed
      # with something appropriate like "This step is incorrect because ".
      result.addMessage "you must cite exactly one line with #{line.getRuleName()}."
  if line.getReferencedLine().type isnt 'line'
    return (result) ->
      result.addMessage "you must cite a line, not a block, with #{line.getRuleName()}."
  return true # Test passed

test.twoNumbersCited = (line) ->
  if line.justification.numbers.length isnt 2
    # The test has failed, so we return a function that updates `result`.
    return (result) ->
      # Note: when a sentence in message starts lowercase, it will be prefixed
      # with something appropriate like "This step is incorrect because ".
      result.addMessage "you must cite exactly one line with #{line.getRuleName()}."
  # console.log "singleNumberCited passed"
  return true # Test passed

test.lineIsReferencedLine = (line) ->
  return true if line.isIdenticalExpression( line.getReferencedLine() )
  return (result) ->
    result.addMessage "the line you cite with  #{line.getRuleName()} must be identical to this line."

test.lineIsLeftJunctOfReferencedLine = (line) ->
  return true if line.getReferencedLine().leftIsIdenticalExpression(line.sentence)
  return (result) ->
    result.addMessage "the left part of line you cite must be identical to this line when you use #{line.getRuleName()}."

test.lineIsRightJunctOfReferencedLine = (line) ->
  return true if line.getReferencedLine().rightIsIdenticalExpression(line.sentence)
  return (result) ->
    result.addMessage "the right part of line you cite must be identical to this line when you use #{line.getRuleName()}."
test.referencedLineConnectiveIs = (connective) ->
  return (line) ->
    otherLine = line.getReferencedLine()
    return true if otherLine.sentence.type is connective
    return (result) ->
      result.addMessage "with #{line.getRuleName()}, the main connective in the line you cite must be #{connective}."


requirements = 
  premise : [ test.throw ]
  reit : [  
    test.singleNumberCited
    test.lineIsReferencedLine
  ]
requirements.and =
  'elim'  : 
    'both' : [
      test.singleNumberCited
      test.referencedLineConnectiveIs('and')
    ]
    'left' : [ 
      test.lineIsLeftJunctOfReferencedLine     
    ]
    'right' : [
      test.lineIsRightJunctOfReferencedLine     
    ]
  'intro' : 
    'both' : [
      test.twoNumbersCited
    ]
    'left' : []
    'right' : []
        
    