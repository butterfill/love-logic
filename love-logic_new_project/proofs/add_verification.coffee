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
#
# In adding verification, this module also checks that the cited lines 
# and blocks exist and can be cited from the line they are cited from.  
# (It makes sense to do this here rather than in `rule` because the
# check doesn't depend on which rule is used.)
 
_ = require 'lodash'


blockParser = require './block_parser'
addLineNumbers = require './add_line_numbers'
addJustification = require './add_justification'
addSentences = require './add_sentences'
addStatus = require './add_status'

theRules = (require './fitch_rules').rules

# This is only used for testing (so that `verifyLine` can take text).
_parseProof = (proofText) ->
  block = blockParser.parse proofText
  addLineNumbers.to block
  addJustification.to block
  addSentences.to block
  addStatus.to block
  return block


# Add a `verify` method to each line and block of `proof`.
# (This is the only method you are likely to need.)
to = (proof) ->
  walker = 
    visit : (item) ->
      return undefined unless item?.type?
      
      if item.type is 'block' 
        aBlock = item
        aBlock.verify = () ->
          allLinesOk = true
          verifyABlockWalker = 
            visit : (item) ->
              if item.type is 'line'
                result = item.verify()
                allLinesOk = allLinesOk and result
                return undefined # keep walking
          aBlock.walk verifyABlockWalker
          return allLinesOk
      else
        # item is a line, blank_line, divider or comment.
        aLine = item
        aLine.verify = () ->
          return verifyLine(aLine, proof)
      
      return undefined

  proof.walk walker
exports.to = to


# Verifies whether the line at `lineOrLineNumber` is correct, 
# returning error messages if not.
# If `lineOrLineNumber`  is not of `.type` `line`, this function confirms 
# that the line is correct but adds a message explaning that it has been treated
# as a blank, divider or whatever.
# `lineOrLineNumber` is the 1-based linenumber in the proofText (so
# not the name of the line) or a line object.
# `proofText` may be a parsed proof (or a string, for testing).
verifyLine = (lineOrLineNumber, proofText) ->
  if _.isString proofText
    proofText = _parseProof proofText
  proof = proofText

  if lineOrLineNumber.type?
    theLine = lineOrLineNumber
  else
    lineNumber = lineOrLineNumber
    theLine = proof.getLine lineNumber
    if not theLine
      throw new Error "Could not find line #{lineNumber} in #{proofText}"

  theLine.status.verificationAttempted = true
  
  # Blank lines, comments, dividers are fine; we don't need to check those.
  # (Here we assume that the only thing we do check are things of `.type` `line`.)
  if theLine.type isnt 'line'
    theLine.status.verified = true
    theLine.status.addMessage("(This is a #{theLine.type.replace(/_/g,' ')})")
    return true
  
  # We can't go on if there are errors, nor if justification is missing.
  if theLine.sentenceErrors? or 
      theLine.justificationErrors? or
      not theLine.justification?
    theLine.status.verified = false
    return false 
  
  # From here on, we have a sentence and justification.
  
  # First, check that the lines cited are legit.
  areLinesCitedOk = _linesCitedAreOk(theLine)
  if areLinesCitedOk isnt true
    errorMessage = areLinesCitedOk
    theLine.status.addMessage errorMessage
    theLine.status.verified = false
    return false
  
  result = checkItAccordsWithTheRules theLine, result
  return result

exports._line = verifyLine   #for testing only

# This function checks that the lines cited are (i) visible to `line`
# and (ii) contain correct sentences of awFOL.
# It returns `true` if checks are passed, or an error string if they fail.
# It does not check the rule of proof at all.
_linesCitedAreOk = (line) ->
  numbers = line.justification.numbers
  return true if not numbers
  for num in numbers
    found = line.findLineOrBlock(num)
    if not found
      return "something you cited, #{num}, cannot be cited here (either it does not exist, or it is below this line, or else it occurs above but in a closed subproof)."
    ancestors = []
    parent = line.parent
    while parent
      ancestors.push parent
      parent = parent.parent
    if found in ancestors
      return "you cannot cite a subproof (#{num}) from within that subproof (you must close it, then cite it)."
    if not (found.type in ['line','block'])
      return "you cannot cite line #{num} because it is a #{found.type.replace(/_/g,' ')}."
    if found.type is 'line' and found.status.sentenceParsed isnt true
      return "you cannot cite line #{num} yet because it does not contain a correct awFOL sentence."
    if found.type is 'block' 
      firstLine = found.getFirstLine()
      lastLine = found.getLastLine()
      if lastLine.type is 'block'
        return "you cannot cite #{num} because it finishes with an unclosed (sub)subproof (you must close it, then cite it)"
      if not (firstLine? and lastLine? and firstLine.status.sentenceParsed and lastLine.status.sentenceParsed)
        return "you cannot cite subproof #{num} yet because it contains lines that are not correct sentence of awFOL."
  return true
exports._linesCitedAreOk = _linesCitedAreOk


checkItAccordsWithTheRules = (line, result) ->
  # `connective` is 'and', 'reit' or 'premise' or ...
  connective = line.justification.rule.connective
  # `intronation` is 'elim' or 'intro'
  intronation = line.justification.rule.variant.intronation
  # `side` is 'left' or 'right'
  side = line.justification.rule.variant.side

  ruleMap = theRules[connective]

  if not ruleMap
    line.status.addMessage ("the rule you specified, `#{connective} #{intronation or ''} #{side or ''}` does not exist (or, if it does, you are not allowed to use it in this proof).".replace /\s\s+/g,'')
    line.status.verified = false 
    return false
  
  if not intronation
    # We need to check the rule specified is complete.
    if ruleMap.type is 'rule'
      # Yes, the rule specified is complete.
      aRule = ruleMap
      return checkThisRule(aRule, line, result)
    # The rule specified is incomplete.
    line.status.addMessage "you only partially specified the rule: `#{connective}` needs something extra (intro? elim?)."
    line.status.verified = false 
    return false
  
  # From here on, we know that `intronation` is specified.
  
  ruleMap = ruleMap[intronation]
  if not ruleMap
    line.status.addMessage "you specified the rule #{connective} *#{intronation}* but there is no ‘#{intronation}’ version of the rule for #{connective} (or, if there is, you are not allowed to use it in this proof)."
    line.status.verified = false
    return false
  
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
      # Meeting the `left` requirement is sufficient when no `side is specified.
      return result if result is true
    if not ruleMap.right?
      return result
      
    # Remove any error message resulting from having tried the `left` variant of the rule.
    leftMessage = line.status.popMessage()
    result = checkThisRule(ruleMap.right, line, result)
    if result is false 
      rightMessage = line.status.popMessage()
      if leftMessage? and rightMessage?
        line.status.addMessage "Either #{leftMessage}, or else #{rightMessage}."
      else 
        # Just put the one message we got (if any) back again
        line.status.addMessage(leftMessage or rightMessage or '')
        
    return result
  
  # From here on, we know that `side` is specified.
  
  # Preliminary check : if `side` is specified, there must be a corresponding rule.
  if not ruleMap[side]?
    line.status.addMessage "you specified the rule #{connective} #{intronation} *#{side}* but there is no ‘#{side}’ version of  #{connective} #{intronation} (or, if there is, you are not allowed to use it in this proof)."
    line.status.verified = false
    return false
  
  return checkThisRule(ruleMap[side], line, result)  

# TODO: remove this --- can just call rule.check directly.  
checkThisRule = (rule, line, result) ->
  outcome = rule.check(line)
  if outcome is true
    line.status.verified = true
    return true
  else
    line.status.verified = false
    return false
      

