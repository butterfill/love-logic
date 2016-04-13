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
#
# Note that all sets of rules of proofs must register themselves by
# being imported either here or before they are first used
#
 
_ = require 'lodash'


blockParser = require './block_parser'
addLineNumbers = require './add_line_numbers'
addJustification = require './add_justification'
addSentences = require './add_sentences'
addStatus = require './add_status'

# theRules = (require './fitch_rules').rules
# IMPORT TO MAKE SURE THAT THE RULES ARE REGISTERED
require './fitch_rules'
require './teller_rules'
dialectManager = require('../dialect_manager/dialectManager')

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
  
  result = checkItAccordsWithTheRules theLine
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


checkLineAccordsWithOneOfTheseRules = (line, rules) ->
  errorMessages = []
  for aRule in rules
    res = aRule.check(line)
    if res is true
      line.status.verified = true
      return true
    # The rule does not match.  Remove any error message
    # in case a later rule does match.
    msg = line.status.popMessage()
    errorMessages.push(msg) if msg?
    
  # None of the rules matched.
  line.status.verified = false
  # Put the error messages back.
  if errorMessages.length is 1
    line.status.addMessage(errorMessages[0])
  if errorMessages.length > 1
    msg = "This rule has multiple forms and none of them matched.  "
    for m, idx in errorMessages
      msg += "(#{idx}) #{m}  "
    line.status.addMessage msg
  return false
    


checkItAccordsWithTheRules = (line) ->
  # `connective` is 'and', 'reit' or 'premise' or ...
  connective = line.justification.rule.connective
  # `intronation` is 'elim' or 'intro'
  intronation = line.justification.rule.variant.intronation
  # `side` is 'left' or 'right'
  side = line.justification.rule.variant.side

  theRules = dialectManager.getCurrentRules()
  # console.log "using #{dialectManager.getCurrentRulesName()}"
  ruleMap = theRules[connective]

  if not ruleMap?
    line.status.addMessage ("the rule you specified, `#{connective} #{intronation or ''} #{side or ''}` does not exist (or, if it does, you are not allowed to use it in this proof).".replace /\s\s+/g,'')
    line.status.verified = false 
    return false
  
  if not intronation
    # We need to check the rule specified is complete.
    if ruleMap.type is 'rule'
      # Yes, the rule specified is complete.
      aRule = ruleMap
      return checkLineAccordsWithOneOfTheseRules(line, [aRule])
    if _.isArray(ruleMap)
      rules = ruleMap
      return checkLineAccordsWithOneOfTheseRules(line, rules)
    # The rule specified is incomplete.
    line.status.addMessage "you only partially specified the rule: `#{connective}` needs something extra (intro? elim?)."
    line.status.verified = false 
    return false
  
  # From here on, we know that `intronation` is specified.
  
  ruleMap = ruleMap[intronation]
  if not ruleMap?
    line.status.addMessage "you specified the rule #{connective} *#{intronation}* but there is no ‘#{intronation}’ version of the rule for #{connective} (or, if there is, you are not allowed to use it in this proof)."
    line.status.verified = false
    return false
  
  if not side
    # Now there are two cases.  The simple case is where the rule specification
    # doesn't involve left or right either.  
    if ruleMap.type is 'rule'
      aRule = ruleMap
      return checkLineAccordsWithOneOfTheseRules(line, [aRule])
    if _.isArray(ruleMap)
      rules = ruleMap
      return checkLineAccordsWithOneOfTheseRules(line, rules)
      
    # There are left and right rules.
    # In this case, at least one of the 'left' and 'right'
    # requirements must be met.
    rules = []
    if ruleMap.left?.type is 'rule'
      rules.push(ruleMap.left)
    if _.isArray(ruleMap.left)
      (rules.push(r) for r in ruleMap.left)
    if ruleMap.right?.type is 'rule'
      rules.push(ruleMap.right)
    if _.isArray(ruleMap.right)
      (rules.push(r) for r in ruleMap.right)
    return checkLineAccordsWithOneOfTheseRules(line, rules)
  
  # From here on, we know that `side` is specified.
  
  # Preliminary check : if `side` is specified, there must be a corresponding rule.
  if not ruleMap[side]?
    line.status.addMessage "you specified the rule #{connective} #{intronation} *#{side}* but there is no ‘#{side}’ version of  #{connective} #{intronation} (or, if there is, you are not allowed to use it in this proof)."
    line.status.verified = false
    return false
  
  rules = ruleMap[side]
  unless _.isArray(rules)
    rules = [rules]
  return checkLineAccordsWithOneOfTheseRules(line, rules)

