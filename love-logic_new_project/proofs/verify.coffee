# Verify whether a proof is correct.

_ = require 'lodash'

blockParser = require '../block_parser'
lineNumbers = require '../line_numbers'
addJustification = require '../add_justification'
addSentences = require '../add_sentences'


parseProof = (proofText), ->
  block = blockParser.parse proofText
  lineNumbers.addNumbers block
  addJustification.to block
  addSentences.to block
  return block

# Verifies whether the line at `lineNumber` is correct, 
# returning error messages if not.
# `lineNumber` is the 1-based number in the proofText.
# `proofText` may be a parsed proof (used internally).
line = (lineNumber, proofText), ->
  if _.isString proofText
    proof = _proof or parseProof proofText
  else 
    proof = proofText

  line = proof.goto lineNumber
  
  result = 
    verified: false 
    message : ''
    addMessage : (txt) => 
      @message = "#{@message} #{txt}".trim()
    areThereErrors : =>
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
  result = checkRequirements line, result
  return result

the = (proofText), ->
  proof = parseProof proofText


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
  if side
    reqList = reqList[side]
  
  # In some cases we will have to check both left and right
  # versions of a rule.  
  if reqList.left?
    tempResult = _.cloneDeep result
    result = evalRequirement
  

requirements = 
  premise : []
  reit : [  test.singleNumber
            (line) -> line.isIdenticalExpression( line.getReferencedLine() )
          ]
  'and' :
    'elim'  : 
      'left' : []
      'right' : []
    'intro' : 
      'left' : []
      'right' : []
      
test = 
  singleNumber : (line) ->
    if line.justification.numbers.length isnt 1
      # The test has failed, so we return a function that updates `result`.
      return (result) ->
        result.addMessage "... you must cite exactly one line with #{line.getRuleName()}."
    return true # Test passed
        
    