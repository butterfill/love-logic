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

util = require '../util'

blockParser = require './block_parser'
addLineNumbers = require './add_line_numbers'
addJustification = require './add_justification'
addSentences = require './add_sentences'
addStatus = require './add_status'

# theRules = (require './fitch_rules').rules
# IMPORT TO MAKE SURE THAT THE RULES ARE REGISTERED
require './fitch_rules'
require './teller_rules'
require './forallx_rules'
require './logicbook_rules'
require './logicbook_tree_rules'
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
# TODO: add verifyNaturalDeduction and check that the first line of a
#   subproof has no justification other than premise 
#   (i.e. `.justification.rule.connective` is `'premise'`)
to = (proof) ->
  walker = 
    visit : (item) ->
      return undefined unless item?.type?
      
      if item.type is 'block' 
        aBlock = item
        aBlock.verify = (theRules) ->
          theRules ?= dialectManager.getCurrentRules()
          
          allLinesOk = true
          verifyABlockWalker = 
            visit : (item) ->
              if item.type in ['line', 'close_branch', 'open_branch']
                result = item.verify(theRules)
                allLinesOk = allLinesOk and result
                return undefined # keep walking
          aBlock.walk verifyABlockWalker
          return allLinesOk
      else
        # item is a line, blank_line, divider or comment.
        aLine = item
        aLine.verify = (theRules) ->
          theRules ?= dialectManager.getCurrentRules()
          return verifyLine(aLine, proof, theRules)
        aLine.canLineBeTicked = () ->
          return canLineBeTicked(aLine)
      return undefined

  proof.walk walker
  
  proof.verifyTree = (theRules) ->
    theRules ?= dialectManager.getTreeRules()
    test1 = proof.verify(theRules)
    return false if test1 is false
    console.log "verify done"
    
    return false if anythingOtherThanABranchOccursAfterABranch(proof)
    console.log "anythingOtherThanABranchOccursAfterABranch done"
    
    branches = proof.getChildren()
    test2 = checkBranchingRules(branches)
    return false if test2 is false
    console.log "checkBranchingRules done"
    
    test3 = checkTicksAreCorrect(proof)
    return false if test3 is false
    
    return true
    
exports.to = to


anythingOtherThanABranchOccursAfterABranch = (proof) ->
  branches = proof.getChildren()
  # If there are no branches, nothing can occur after them:
  return false unless branches?.length > 0
  # Check all the branches:
  for b in branches
    return true if anythingOtherThanABranchOccursAfterABranch(b)
  # Finally, check the lines of this block:
  foundBranch = false
  for item in proof.content
    foundBranch = true if item.type is 'block'
    if foundBranch and not (item.type in ['block', 'blank_line'])
      return true
  return false

checkTicksAreCorrect = (proof) ->
  walker = 
    visit : (item) ->
      return undefined unless item?.justification?.ticked
      test = canLineBeTicked(item)
      return false if test is false
      return undefined # keep walking
  result = proof.walk(walker)
  return false if result is false
  return true




# In a tree proof, check that where a branch is created,
# the right number of branches have been created using
# the right rules.
checkBranchingRules = (branches) ->
  return true unless branches?.length > 0
  for b in branches
    test = checkBranchingRules(b)
    return false if test is false
  
  ruleSet = branches[0].getFirstLine()?.rulesChecked?[0]?.rule.ruleSet
  unless ruleSet?
    throw new Error "Could not get ruleSet at line #{branches[0].getFirstLine()?.number}."
  rulesUsed = []
  for b in branches
    line = b.getFirstLine()
    console.log "at line #{line?.number}."
    rule = line?.rulesChecked?[0].rule
    unless rule? 
      throw new Error "Could not get rule at line #{b.getFirstLine()?.number}."
    if rule in rulesUsed
      # You cannot use the same rule twice in branching ...
      # ... provided there is more than one rule.
      # (This is a kludge for rules like `existential D 2`; there is 
      # just one rule that is applied a variable number of times
      # depending on facts about the proof in which it occurs.)
      if ruleSet.length > 1
        # Further exception : when other rules could have verified
        # this line (as happens with or decomposition applied to `A or A`), 
        # it is ok to use the same rule twice.
        itIsOkToUseTheSameRuleTwiceHere = false
        for r in ruleSet
          unless r in rulesUsed
            if r.check(line)
              itIsOkToUseTheSameRuleTwiceHere = true
              rulesUsed.push(r)
        unless itIsOkToUseTheSameRuleTwiceHere
          line.status.addMessage("you cannot use the same rule twice in branching")
          console.log "you cannot use the same rule twice in branching"
          return false
    if rule.ruleSet isnt ruleSet
      # You cannot combine rules from different ruleSets in branching
      return false
    rulesUsed.push(rule)
  if rulesUsed.length < ruleSet.length
    # All rules in a `RuleSet` must be used in branching ...
    # ... provided there is more than one rule.
    # (This is a kludge for rules like `existential D 2`; for this rule,
    # a guarantee that the correct branches are made is provided via a 
    # `.where` clause in the rule definition.)
    if ruleSet.length > 1
      # May need to exclude some non-branching rules (because the rules
      # for, e.g., `<->` include a mix of branching and non-branching rules).
      nofBranchingRules = (r for r in ruleSet when r.isBranchingRule).length
      if rulesUsed.length < nofBranchingRules
        return false
  return true

# For tree proofs.  A line containing, e.g., ‘A or B’ or ‘a=b’ needs
# to be ticked; but one containing ‘not A’ does not need 
# to be ticked.
lineNeedsToBeTicked = (line) ->
  return false unless line.sentence?
  # a=b needs ticking:
  return true if sentence.type is 'identity'
  # If sentence.left? is false, we have a predicate or sentence letter
  return false unless sentence.left?
  if sentence.type is 'not'
    return false unless sentence.left.left?
  return true
# for testing only:
exports.lineNeedsToBeTicked = lineNeedsToBeTicked

# For tree proofs.  A line can be ticked if 
# all rules that can be applied to it have been
# applied.
# Defaults to true if there is no `tickChecker` for the 
# connective (e.g. with identity).
canLineBeTicked = (line) ->
  theRules = dialectManager.getCurrentRules()
  sentence = line.sentence
  tickChecker = theRules.tickCheckers[sentence.type] 
  # Default to true
  return true unless tickChecker?
  unless _.isFunction(tickChecker)
    # We need to go one level further into the tickChecker object.
    # This is for rules like `not and decomposition`
    sentence = sentence.left
    return true unless sentence?
    tickChecker = tickChecker[sentence.type] 
    return true unless tickChecker?
  return tickChecker(line) 
# for testing only:
exports.canLineBeTicked = canLineBeTicked
  
# Verifies whether the line at `lineOrLineNumber` is correct, 
# returning error messages if not.
# If `lineOrLineNumber`  is not of `.type` `line`, this function confirms 
# that the line is correct but adds a message explaning that it has been treated
# as a blank, divider or whatever.
# `lineOrLineNumber` is the 1-based linenumber in the proofText (so
# not the name of the line) or a line object.
# `proofText` may be a parsed proof (or a string, for testing).
verifyLine = (lineOrLineNumber, proofText, theRules) ->
  
  theRules ?= dialectManager.getCurrentRules()
  # console.log "using #{dialectManager.getCurrentRulesName()}"
  
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
  if theLine.type not in ['line', 'close_branch', 'open_branch']
    theLine.status.verified = true
    theLine.status.addMessage("(This is a #{theLine.type.replace(/_/g,' ')})")
    return true
  
  # console.log "verifyLine #{theLine.number}"
  
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
  
  result = checkItAccordsWithTheRules theLine, theRules
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
      languageNames = util.getLanguageNames()
      return "you cannot cite line #{num} yet because it does not contain a correct sentence of #{languageNames.join(' or ')}."
    if found.type is 'block' 
      firstLine = found.getFirstLine()
      lastLine = found.getLastLine()
      if lastLine.type is 'block'
        return "you cannot cite #{num} because it finishes with an unclosed (sub)subproof (you must close it, then cite it)"
      if not (firstLine? and lastLine? and firstLine.status.sentenceParsed and lastLine.status.sentenceParsed)
        languageNames = util.getLanguageNames()
        return "you cannot cite subproof #{num} yet because it contains lines that are not correct sentence of #{languageNames.join(' or ')}."
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
    


checkItAccordsWithTheRules = (line, theRules) ->
  # `connective` is 'and', 'reit' or 'premise' or ...
  connective = line.justification.rule.connective
  # `intronation` is 'elim' or 'intro'
  intronation = line.justification.rule.variant?.intronation
  # `side` is 'left' or 'right'
  side = line.justification.rule.variant?.side

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

