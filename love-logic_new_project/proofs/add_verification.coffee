# Verify whether a proof is correct.  The main use 
# is like `addVerification.to proof`.
#
# This module assumes that `add_line_numbers`, `add_sentences`,
# `add_justification` and `add_status` have all already applied to `proof`.
#
#
# Terminology:
#    a 'block' is a subproof.
#
# This module links `add_justification` (which is about
# parsing justification and attaching it to the proof), `add_line_numbers`
# (which is about identifying how the proof writer names lines) and 
# `rule` (which is for describing rules of proof).

 
_ = require 'lodash'


blockParser = require './block_parser'
addLineNumbers = require './add_line_numbers'
addJustification = require './add_justification'
addSentences = require './add_sentences'

theRules = (require './fitch_rules').rules

# TODO: remove (was used for testing).
_parseProof = (proofText) ->
  block = blockParser.parse proofText
  addLineNumbers.to block
  addJustification.to block
  addSentences.to block
  return block
exports._parseProof = _parseProof


# Add a `verify` method to each line and block of `proof`.
# (This is the only method you are likely to need.)
to = (proof) ->
  walker = 
    visit : (item) ->

      if item?.type is 'line'
        aLine = item
        aLine.verify = () ->
          result = verifyLine(aLine, proof)
          return true if result.verified
          return result
          
      if item?.type is 'block'
        aBlock = item
        allLinesOk = true
        aBlock.verify = () ->
          verifyABlock = 
            visit : (item) ->
              if item.type is 'line'
                result = item.verify()
                allLinesOk = allLinesOk and result
          aBlock.walk verifyABlock
          return allLinesOk
          
      return undefined

  proof.walk walker
exports.to = to


# Verifies whether the line at `lineNumber` is correct, 
# returning error messages if not.
# `lineNumber` is the 1-based number in the proofText.
# `proofText` may be a parsed proof (used internally).
verifyLine = (lineOrLineNumber, proofText) ->
  if _.isString proofText
    proofText = _parseProof proofText
  proof = proofText

  if lineOrLineNumber.type is 'line'
    theLine = lineOrLineNumber
  else
    lineNumber = lineOrLineNumber
    theLine = proof.getLine lineNumber
    if not theLine
      throw new Error "Could not find line #{lineNumber} in #{proofText}"
  
  result = 
    verified: false 
    message : ''
    messages : []
    addMessage : (txt) -> 
      @messages.push txt
      @message = "#{@message} #{txt}".trim()
    popMessage : () ->
      if @messages.length > 0
        msg = @messages.pop()
        @message = "#{@message}"
        return msg
      return ''
    areThereErrors : ->
      return true if @sentenceErrors? or @justificationErrors?
      return false
  
  # We can't go on if there are errors.
  if theLine.sentenceErrors? 
    result.sentenceErrors = theLine.sentenceErrors 
    result.addMessage 'there were errors with the sentence you wrote.'
  if theLine.justificationErrors?  
    result.justificationErrors = theLine.justificationErrors
    result.addMessage 'there were errors with the justification you gave.'
  if result.areThereErrors()
    return result
  
  # Blank lines are fine; we don't need to check those.
  if not theLine.sentence?  and theLine.content?.trim() is ''
    result.verified = true
    return result
  
  # A line missing justification is a mistake.
  # (Note that justification is automatically added to premises 
  # and assumptions by the `add_justification` module.)
  if not theLine.justification?
    result.addMessage 'You did not provide any justification'
    return result
  
  # From here on, we have a sentence and justification.
  
  # First, check that the lines cited are legit.
  if not linesCitedAreOk(theLine)
    result.addMessage 'you cited lines that cannot be cited here (either they do not exist, or they are below this line, or else they occur above but in a closed block).'
    return result
  
  result = checkItAccordsWithTheRules theLine, result
  return result

exports._line = verifyLine   #for testing only


linesCitedAreOk = (line) ->
  numbers = line.justification.numbers
  return true if not numbers
  for num in numbers
    found = line.findLineOrBlock(num)
    return false if not found
  return true


checkItAccordsWithTheRules = (line, result) ->
  # `connective` is 'and', 'reit' or 'premise' or ...
  connective = line.justification.rule.connective
  # `intronation` is 'elim' or 'intro'
  intronation = line.justification.rule.variant.intronation
  # `side` is 'left' or 'right'
  side = line.justification.rule.variant.side

  ruleMap = theRules[connective]

  if not ruleMap
    result.addMessage ("the rule you specified, `#{connective} #{intronation or ''} #{side or ''}` does not exist (or, if it does, you are not allowed to use it in this proof).".replace /\s\s+/g,'')
    result.verified = false 
    return result
  
  if not intronation
    # We need to check the rule specified is complete.
    if ruleMap.type is 'rule'
      aRule = ruleMap
      return checkThisRule(aRule, line, result)
    # The rule specified is incomplete.
    result.addMessage "you only partially specified the rule: `#{connective}` needs something extra (intro? elim?)."
    result.verified = false 
    return result
  
  # From here on, we know that `intronation` is specified.
  
  ruleMap = ruleMap[intronation]
  if not ruleMap
    result.addMessage "you specified the rule #{connective} *#{intronation}* but there is no ‘#{intronation}’ version of the rule for #{connective} (or, if there is, you are not allowed to use it in this proof)."
    result.verified = false
    return result
  
  if not side
    # Now there are two cases.  The simple case is where the rule specification
    # doesn't involve left or right either.  
    if ruleMap.type is 'rule'
      aRule = ruleMap
      return checkThisRule(aRule, line, result)
    
    # We are in the tricky case where there are left and right rules.
    # In this case, at least one of the 'left' and 'right'
    # requirements must be met.
    # We first check left and, if that fails, check right.
    # We also want to provide a disjunctive message if neither left nor right
    # requirements are met.
    if ruleMap.left?
      result = checkThisRule(ruleMap.left, line, result)
      if result.verified 
        # meeting the `left` requirement is sufficient when no `side is specified 
        return result 
    if not ruleMap.right?
      # There are no further checks so the line has not been verified.
      return result
      
    leftMessage = result.popMessage()
    result = checkThisRule(ruleMap.right, line, result)
    if not result.verified 
      rightMessage = result.popMessage()
      if leftMessage? and rightMessage?
        result.addMessage "Either #{leftMessage}, or else #{rightMessage}."
      else 
        # Just put the one message we got (if any) back again
        result.addMessage leftMessage or rightMessage or ''
        
    return result
  
  # From here on, we know that `side` is specified.
  
  # Preliminary check : if `side` is specified, there must be a corresponding rule.
  if not ruleMap[side]?
    result.addMessage "you specified the rule #{connective} #{intronation} *#{side}* but there is no ‘#{side}’ version of  #{connective} #{intronation} (or, if there is, you are not allowed to use it in this proof)."
    result.verified = false
    return result
  
  return checkThisRule(ruleMap[side], line, result)  

  
checkThisRule = (rule, line, result) ->
  outcome = rule.check(line)
  if outcome is true
    result.verified = true
  else
    result.verified = false
    msg = outcome.getMessage()
    result.addMessage(msg)
  return result
      

