# Verify whether a proof is correct.
#
# Terminology:
#    a 'block' is a subproof.
#

_ = require 'lodash'

# Only required for testing.
util = require '../util'


blockParser = require './block_parser'
lineNumbers = require './line_numbers'
addJustification = require './add_justification'
addSentences = require './add_sentences'

rule = require './rule'

parseProof = (proofText) ->
  block = blockParser.parse proofText
  lineNumbers.addNumbers block
  addJustification.to block
  addSentences.to block
  return block
exports._parseProof = parseProof

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
    messages : []
    addMessage : (txt) -> 
      @messages.push txt
      @message = "#{@message} #{txt}".trim()
    popMessage : () ->
      msg = @messages.pop()
      @message = "#{@message}"
      return msg
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

  if not reqList
    result.addMessage ("the rule you specified, `#{connective} #{intronation or ''} #{side or ''}` does not exist (or, if it does, you are not allowed to use it in this proof).".replace /\s\s+/g,'')
    result.verified = false 
    return result
  
  if not intronation
    # We need to check the rule specified is complete.
    if _.isArray(reqList) or reqList.type is 'rule'
      return checkTheseRequirements(reqList, line, result)
    # The rule specified is incomplete.
    result.addMessage "you only partially specified the rule: `#{connective}` needs something extra (intro? elim?)."
    result.verified = false 
    return result
  
  # From here on, we know that `intronation` is specified.
  
  reqList = reqList[intronation]
  if not reqList
    result.addMessage "you specified the rule #{connective} *#{intronation}* but there is no ‘#{intronation}’ version of the rule for #{connective} (or, if there is, you are not allowed to use it in this proof)."
    result.verified = false
    return result
  
  if not side
    # Now there are two cases.  The simple case is where the rule specification
    # doesn't involve left or right either.  
    if _.isArray(reqList) or reqList.type is 'rule'
      return checkTheseRequirements(reqList, line, result)
    
    # We are in the tricky case where there are left and right rules, plus maybe a 'both'.
    # In this case, the 'both' requirement must be met and at least one of the 'left' and 'right'
    # requirements must be met.
    if reqList.both?
      result = checkTheseRequirements(reqList.both, line, result)
      if not result.verified
        return result

    # Now we check left and, if that fails, check right.
    # We also want to provide a disjunctive message if neither left nor right
    # requirements are met.
    if reqList.left?
      result = checkTheseRequirements(reqList.left, line, result)
      if result.verified 
        # meeting the `left` requirement is sufficient when no `side is specified 
        return result 
    if reqList.right?
      leftMessage = result.popMessage()
      result = checkTheseRequirements(reqList.right, line, result)
      if not result.verified 
        rightMessage = result.popMessage()
        # TODO: This will look weird if there is only one message (e.g. when ad hoc rule 
        # restrictions apply).
        result.addMessage "Either #{leftMessage}, or else #{rightMessage}."
      return result
    else
      # There are no further checks we can do.  
      return result
  
  # From here on, we know that `side` is specified.
  
  # Preliminary check : if `side` is specified, there must be a corresponding rule.
  if  not reqList[side]?
    result.addMessage "you specified the rule #{connective} #{intronation} *#{side}* but there is no ‘#{side}’ version of  #{connective} #{intronation} (or, if there is, you are not allowed to use it in this proof)."
    result.verified = false
    return result
  
  # When `side` is specified, success involves meeting any `.both` requirements as 
  # well as the `.side` requirements.
  if reqList.both?
    result = checkTheseRequirements(reqList.both, line, result)
    if not result.verified
      return result
  return checkTheseRequirements(reqList[side], line, result)  

  
checkTheseRequirements = (reqList, line, result) ->
  # Currently we have two ways of expressing requirements.
  # The first is an array of functions that take a line and return either true or 
  # a function which adds a message to result.
  if _.isArray reqList
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

  # The alternative way of expressing requirements uses the `rules` module.
  req = reqList
  outcome = req.check(line)
  if outcome is true
    result.verified = true
  else
    result.verified = false
    msg = outcome.getMessage()
    result.addMessage(msg)
  return result
      
test = {}
test.throw = ->
  throw new Error "Not implemented yet!"

test.singleLineCited = (line) ->
  if line.justification.numbers?.length isnt 1
    # The test has failed, so we return a function that updates `result`.
    return (result) ->
      # Note: when a sentence in message starts lowercase, it will be prefixed
      # with something appropriate like "This step is incorrect because ".
      result.addMessage "you must cite exactly one line with #{line.getRuleName()}."
  if line.getCitedLines().length isnt 1
    return (result) ->
      result.addMessage "you must cite a line, not a block, with #{line.getRuleName()}."
  return true # Test passed

test.singleBlockCited = (line) ->
  if line.justification.numbers?.length isnt 1
    return (result) ->
      result.addMessage "you must cite exactly one subproof with #{line.getRuleName()}."
  if line.getCitedLine().type isnt 'block'
    return (result) ->
      result.addMessage "you must cite a block, not a line, with #{line.getRuleName()}."
  return true 

test.twoLinesCited = (line) ->
  if line.justification.numbers.length isnt 2
    return (result) ->
      result.addMessage "you must cite exactly two lines with #{line.getRuleName()}."
  if line.getCitedLines().length isnt 2
    return (result) ->
      result.addMessage "you may only cite lines, not blocks, with #{line.getRuleName()}."
  return true 

test.lineAndBlockCited = (line) ->
  citedLines = line.getCitedLines()
  citedBlocks = line.getCitedBlocks()
  if citedLines.length isnt 1 or citedBlocks.length isnt 1
    return (result) ->
      result.addMessage "you must cite one line and one subproof with #{line.getRuleName()}; you cited #{citedLines.length} lines and #{citedBlocks.length} blocks."
  return true 

test.lineIsCitedLine = (line) ->
  return true if line.isIdenticalExpression( line.getCitedLine().sentence )
  return (result) ->
    # console.log "line = #{util.expressionToString line.sentence}, line.getCitedLine() = #{util.expressionToString line.getCitedLine().sentence}"
    result.addMessage "the line you cite with  #{line.getRuleName()} must be identical to this line."

test.lineIsLeftJunctOfCitedLine = (line) ->
  return true if line.getCitedLine().leftIsIdenticalExpression(line.sentence)
  return (result) ->
    result.addMessage "the left part of line you cite must be identical to this line when you use #{line.getRuleName()}."

test.lineIsRightJunctOfCitedLine = (line) ->
  return true if line.getCitedLine().rightIsIdenticalExpression(line.sentence)
  return (result) ->
    result.addMessage "the right part of line you cite must be identical to this line when you use #{line.getRuleName()}."

test.connectiveIs = (connective) ->
  return (line) ->
    return true if line.sentence.type is connective
    return (result) ->
      result.addMessage "the main connective in this line must be #{connective} with #{line.getRuleName()}."

test.connectiveIs = (connective) ->
  return (line) ->
    return true if line.sentence.type is connective
    return (result) ->
      result.addMessage "you can only use #{line.getRuleName()} on lines where the main connective is #{connective}."

test.citedLineConnectiveIs = (connective) ->
  return (line) ->
    otherLine = line.getCitedLine()
    return true if otherLine.sentence.type is connective
    return (result) ->
      result.addMessage "with #{line.getRuleName()}, the main connective in the line you cite must be #{connective}."

test.citedLinesAreTheJunctsOfThisLine = (line) ->
  [citedLine1, citedLine2] = line.getCitedLines()
  if not citedLine1.isIdenticalExpression( line.sentence.left )
    return  citedLine2.isIdenticalExpression( line.sentence.left ) and citedLine1.isIdenticalExpression( line.sentence.right ) 
  else
    return citedLine2.isIdenticalExpression( line.sentence.right )

requirements = 
  premise : [ test.throw ]

requirements.reit = rule.from('φ').to('φ')

requirements.and =
  elim : 
    left : rule.from('φ and ψ').to('φ')
    right : rule.from('φ and ψ').to('ψ')
  intro : rule.from('φ').and('ψ').to('φ and ψ')

requirements.or = 
  elim  : rule.from('φ or ψ').and(rule.subproof('φ', 'χ')).and(rule.subproof('ψ', 'χ') ).to('χ' )
  intro : 
    left  : rule.from('φ or ψ').to('φ')
    right : rule.from('φ or ψ').to('ψ')

requirements.not = 
  elim : rule.from('not not φ').to('φ') 
  intro : rule.from( rule.subproof('φ','contradiction') ).to('not φ') 
        
requirements.existential = 
  'elim' : [
    test.lineAndBlockCited
    test.throw
  ]
  'intro' : [
    test.singleLineCited
    test.connectiveIs 'existential_quantifier'
    test.throw
  ]
  
exports._test = test
