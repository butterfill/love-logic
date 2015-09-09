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
      if @messages.length > 0
        msg = @messages.pop()
        @message = "#{@message}"
        return msg
      return ''
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
  # and assumptions by the `add_justification` module.)
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
    if reqList.type is 'rule'
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
    if reqList.type is 'rule'
      return checkTheseRequirements(reqList, line, result)
    
    # We are in the tricky case where there are left and right rules.
    # In this case, at least one of the 'left' and 'right'
    # requirements must be met.
    # We first check left and, if that fails, check right.
    # We also want to provide a disjunctive message if neither left nor right
    # requirements are met.
    if reqList.left?
      result = checkTheseRequirements(reqList.left, line, result)
      if result.verified 
        # meeting the `left` requirement is sufficient when no `side is specified 
        return result 
    if not reqList.right?
      # There are no further checks so the line has not been verified.
      return result
      
    leftMessage = result.popMessage()
    result = checkTheseRequirements(reqList.right, line, result)
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
  if not reqList[side]?
    result.addMessage "you specified the rule #{connective} #{intronation} *#{side}* but there is no ‘#{side}’ version of  #{connective} #{intronation} (or, if there is, you are not allowed to use it in this proof)."
    result.verified = false
    return result
  
  return checkTheseRequirements(reqList[side], line, result)  

  
checkTheseRequirements = (req, line, result) ->
  outcome = req.check(line)
  if outcome is true
    result.verified = true
  else
    result.verified = false
    msg = outcome.getMessage()
    result.addMessage(msg)
  return result
      

requirements = 
  premise : rule.premise()

  reit : rule.from('φ').to('φ')

  'and' :
    elim : 
      left : rule.from('φ and ψ').to('φ')
      right : rule.from('φ and ψ').to('ψ')
    intro : rule.from('φ').and('ψ').to('φ and ψ')

  'or' :
    elim  : rule.from('φ or ψ').and(rule.subproof('φ', 'χ')).and(rule.subproof('ψ', 'χ') ).to('χ' )
    intro : 
      left  : rule.from('φ or ψ').to('φ')
      right : rule.from('φ or ψ').to('ψ')

  'not' : 
    elim : rule.from('not not φ').to('φ') 
    intro : rule.from( rule.subproof('φ','contradiction') ).to('not φ') 

  contradiction :
    elim : rule.from('contradiction').to('φ') 
    intro : rule.from('not φ').and('φ').to('contradiction')
    
  arrow :
    elim : rule.from('φ arrow ψ').and('φ').to('ψ')
    intro : rule.from( rule.subproof('φ','ψ') ).to('φ arrow ψ')
    
  double_arrow :
    elim : 
      left : rule.from('φ↔ψ').and('φ').to('ψ')
      right : rule.from('φ↔ψ').and('ψ').to('φ')
    intro : rule.from( rule.subproof('φ','ψ') ).and( rule.subproof('ψ','φ') ).to('φ↔ψ')

  identity :
    intro : rule.to('α=α')
    elim : 
      # Note: this rule will fail as things stand because `α=β` might match
      # what φ should match when =elim is applied to an identity statement.
      left : rule.from('α=β').and('φ').to('φ[α->β]')
      right : rule.from('α=β').and('φ').to('φ[β->α]')
        
  existential :
    elim : rule.from('exists τ φ').and( rule.subproof('[α]φ[τ->α]', 'ψ') ).to('ψ[α->null]')

    intro : rule.from('φ[τ->α]').to('exists τ φ')

  universal :
    elim : rule.from('all τ φ').to('φ[τ->α]')
    intro : rule.from( rule.subproof('[α]', 'φ') ).to('all τ φ[α->τ]')

