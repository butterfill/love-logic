# Module for creating requirements on lines of a proof expressed like this:
#     `rule.from('not not φ').to('φ')`
# and:
#     `rule.from( rule.subproof('φ','contradiction') ).to('not φ') `
#
# Having created a rule, use `.check` to see whether a line conforms to the rule:
#     `rule.from( rule.subproof('φ','contradiction') ).to('not φ').check(line)`
#
# Note that this module doesn't care at all about the actual justification given.
# (It does care about which lines or subproofs are cited; but it does not 
# check whether the proof writer can cite these lines or subproofs (`add_verification`
# does that job).)
#
# This module depends on `add_line_numbers.to`, `add_status.to` and `add_sentences.to` 
# have been applied to any proof it sees.
#
# Terminology: a `matches` object is a map from metavariables (like `φ` and `α`) to
# the expressions or terms they have matched (see the core module `substitute.findMatches`).
#

_ = require 'lodash'

util = require '../util'
fol = require '../fol'


# Rules can be written using any parser.
# (Note that the parser in which the rules are written doesn’t have to be
# the parser in which proofs are written).
parser = undefined 
exports.setParser = (aParser) ->
  parser = aParser

# For testing only:
_matchesToString = (priorMatches) ->
  res = ""
  for key of priorMatches
    res += "#{key} : #{fol._decorate(priorMatches[key]).toString()} ; "
  return res

# Use like rule.from( rule.match('ψ[τ-->α]').isNewName('α') ).to(...
match = (sentence) ->
  pattern = parseAndDecorateIfNecessary(sentence)
  baseCheck = (line, priorMatches) ->
    test = doesLineMatchPattern(line, pattern, priorMatches)
    return test
  checkFunctions = [baseCheck]
  return {
    check : (line, priorMatches) ->
      currentMatches = priorMatches
      for f in checkFunctions
        test = f(line, currentMatches)
        # if test is false
        #   console.log "    did not match #{pattern} to #{line.sentence}, #{_matchesToString(priorMatches)}"
        # else
        #   console.log "    matched #{pattern} to #{line.sentence}, #{_matchesToString(test)}"
        return false if test is false
        currentMatches = test
      return currentMatches
    
    toString : () ->
      return pattern.toString()

    # Add a requirement to the match: `name` must not occur on
    # any line above in the proof (except in a closed subproof).
    isNewName : (name) ->
      nameThatMustBeNew = _parseNameIfNecessaryAndDecorate(name)
      newNameCheck = (line, priorMatches) ->
        nameThatMustBeNewClone = nameThatMustBeNew.clone()
        nameThatMustBeNewClone = nameThatMustBeNewClone.applyMatches(priorMatches).applySubstitutions()
        theNameTxt = nameThatMustBeNewClone.name
        # console.log "checking #{theNameTxt} is new from line #{line.number}"
        return false if doesALineAboveContainThisName(theNameTxt, line)
        return priorMatches
      checkFunctions.push newNameCheck
      return @
      
    isNotInAnyUndischargedPremise : (name) ->
      nameThatCantBeInAnyUndischargedPremise = _parseNameIfNecessaryAndDecorate(name)
      newCheck = (line, priorMatches) ->
        nameClone = nameThatCantBeInAnyUndischargedPremise.clone()
        nameClone = nameClone.applyMatches(priorMatches).applySubstitutions()
        nameTxt = nameClone.name
        return false if doesAPremiseHereOrAboveContainThisName(nameTxt, line)
        return priorMatches
      checkFunctions.push newCheck
      return @
  }
exports.match = match

# Return false if not; otherwise return the `newMatches` involved
# in matching the line to the pattern.
doesLineMatchPattern = (line, pattern, priorMatches) ->
  return false if line.type isnt 'line'
  
  # check that we can do the substitutions
  metaVariableNames = pattern.listMetaVariableNames()
  # console.log "metaVariableNames.inSub.left = #{metaVariableNames.inSub.left} for pattern #{pattern}."
  for varName in metaVariableNames.inSub.left
    if not (varName of priorMatches)
      # console.log "    fail check because #{varName} not of priorMatches, #{_matchesToString(priorMatches)}"
      return false
  
  patternClone = pattern.clone().applyMatches(priorMatches)

  # Special case: there was a subsutition like `[a-->null]` which
  # results in `e` being null.  This indicates a requirement has 
  # not been met.
  testVerbotenName = patternClone.applySubstitutions()
  if testVerbotenName is null
    return false

  # Note: We must NOT apply substitutions before doing `.findMatches`.
  # (Because `.findMatches` needs to selectively apply substitutions,
  # whereas `.applySubstitutions` replaces all matches indiscriminately.)
  aSentence = line.sentence
  # We might in principle be citing a blank line or something:
  return false unless aSentence?
  
  if not patternClone.box? and aSentence.box?
    aSentence = aSentence.clone()
    delete aSentence.box

  # console.log "#{reqClone.toString({replaceSymbols:true})}"
  newMatches = aSentence.findMatches patternClone, priorMatches
  
  # console.log "_checkOneLine sentence = #{aLine.sentence.toString()}"
  # console.log "_checkOneLine aReq = #{aReq.toString()}"
  # console.log "_checkOneLine reqClone = #{reqClone.toString()}"
  # console.log "_checkOneLine priorMatches = #{util.matchesToString priorMatches}"
  # console.log "_checkOneLine newMatches = #{util.matchesToString newMatches}"
  
  return false if (newMatches is false)
  
  # Special case: if `aReq` involves a box, we need to apply the requirement
  # that the name in the box must not already occur in the proof.
  if patternClone.box? or (patternClone.type is 'box')
    aBox = (patternClone if patternClone.type is 'box') or (patternClone.box if patternClone.box?)
  
    # Do this or fail test `454092AA-57A4-11E5-9C09-B0C78BD11E5D`.
    # (It's necessary because the box may contain a `term_metavariable` which
    # we have only now just matched.)
    aBox = aBox.applyMatches(newMatches).applySubstitutions()
  
    # The name in the box must not occur on a line earlier in the proof
    # (although it may appear in earlier subproofs).
    theName = aBox.term.name
    # nameInBoxIsAlreadyUsedInProof = @_isALineContainingTheName(theName, aLine)
    test = doesALineAboveContainThisName(theName, line)
    # console.log "    checked #{theName} does not appear above line #{line.number}: #{test}"
    return false if (test isnt false)

  return newMatches  

# Check whether `theName` occurs anywhere above the `lineOrBlock`
# ignoring any closed subproofs.
# Note that param `theName` is a string (eg. 'a'), not a fol name object.
doesALineAboveContainThisName = (theName, aLine) ->
  test = (lineOrBlock) ->
    # Note: we don't care if the name occurs in closed subproofs
    # as long as it doesn't occur in any line above this one.
    return false if lineOrBlock.type isnt 'line'
    # console.log "#{lineOrBlock.number} : #{lineOrBlock.sentence} contains #{theName}? #{(theName in lineOrBlock.sentence.getNames())}"
    return true if (theName in lineOrBlock.sentence.getNames())
    return false
  return aLine.findAbove( test )

doesAPremiseHereOrAboveContainThisName = (theName, aLine) ->
  if aLine.isPremise()
    return true if (theName in aLine.sentence.getNames())
  test = (lineOrBlock) ->
    # Note: we don't care if the name occurs in closed subproofs
    # as long as it doesn't occur in any line above this one:
    return false if lineOrBlock.type isnt 'line'
    # console.log "#{lineOrBlock.number} : #{lineOrBlock.sentence} contains #{theName}? #{(theName in lineOrBlock.sentence.getNames())}"
    # We only care about premises:
    return false unless lineOrBlock.isPremise()
    return true if (theName in lineOrBlock.sentence.getNames())
    return false
  return aLine.findAbove( test ) 

convertTextToRequirementIfNecessary = (requirement) ->
  return match(requirement) if _.isString(requirement)
  return requirement 
  

# When the prerequisites for a rule include subproofs,
# specify them using `rule.subproof` as in:
# `rule.from( rule.subproof('φ','contradiction') ).to('not φ')`.
subproof = (premisePattern, conclusionPattern) ->
  premiseReq = convertTextToRequirementIfNecessary(premisePattern)
  conclusionReq = convertTextToRequirementIfNecessary(conclusionPattern)
  
  baseCheck = (subproof, priorMatches) ->
    premiseLine = subproof.getFirstLine()
    conclusionLine = subproof.getLastLine()
    currentMatches = priorMatches
    testPremise1 = premiseReq.check(premiseLine, currentMatches)
    # First try testing the premise and then then the conclusion:
    if testPremise1 isnt  false
      currentMatches = testPremise1
      testConculsion1 = conclusionReq.check(conclusionLine, currentMatches)
      if testConculsion1 isnt false
        newMatches = testConculsion1
        return newMatches
    # Try testing the conclusion and then the premise:
    currentMatches = priorMatches
    testConclusion2  = conclusionReq.check(conclusionLine, currentMatches)
    return false if testConclusion2 is false
    currentMatches = testConclusion2
    testPremise2 = premiseReq.check(premiseLine, currentMatches)
    return false if testPremise2 is false
    newMatches = testPremise2
    return newMatches
    
  checkFunctions = [baseCheck]
  baseToString = () ->
    "#{premiseReq.toString()} ⊢ #{conclusionReq.toString()}"
  toStringFunctions = [baseToString]
  return {
    type : 'subproof'
    
    check : (subproof, priorMatches) ->
      currentMatches = priorMatches
      for f in checkFunctions
        test = f(subproof, currentMatches)
        return false if test is false
        currentMatches = test
      return currentMatches
    
    # Use like `rule.subproof('not φ', 'φ2').contains('ψ', 'not ψ')`
    contains : (listOfSentencesThatMustBeInSubproof...) ->
      listOfSentencesThatMustBeInSubproof = (parseAndDecorateIfNecessary(x) for x in listOfSentencesThatMustBeInSubproof)
      newCheck = (subproof, priorMatches) ->
        # First define two helper functions:
        # Do any of theLines match pattern
        doesPatternMatchAnyLines = (pattern, theLines, priorMatches) ->
          for line in theLines
            sentence = line.sentence
            test = sentence.findMatches(pattern, priorMatches)
            # test = @_checkOneLine(aReq, line, priorMatches)
            # console.log "tested req #{pattern.toString()} against #{line.sentence}, res is #{test}, newMatches contains entries for #{(x.toString() for x in _.keys(test)).join(', ')} with newMatches.ψ = #{fol._decorate(test.ψ).toString() if test.ψ}"
            return test unless test is false
          # We didn’t find any lines that matche pattern.
          return false

        # Are all thePatterns matched in theLines?
        allPatternsAreMatched = (thePatterns, theLines, priorMatches) ->
          newMatches = priorMatches
          for pattern in thePatterns
            test = doesPatternMatchAnyLines(pattern, theLines, newMatches)
            return false if test is false
            newMatches = test
          return newMatches
        
        # Get the lines of proof against which we will match:
        linesOfProof = []
        for item in subproof.content
          if item.type is 'line'
            unless item.isPremise()  # we aren’t allowed to match premises
              linesOfProof.push(item) 
        # consider all permutations of `theReqs`:
        patternsPerms = _permutations(listOfSentencesThatMustBeInSubproof)
        for thePatterns in patternsPerms
          test = allPatternsAreMatched(thePatterns, linesOfProof, priorMatches)
          return test if test isnt false
        return false
      checkFunctions.push newCheck
      newToString = () ->
        ", where this subproof contains #{(x.toString() for x in listOfSentencesThatMustBeInSubproof).join(' and ')}"
      return @
    
    toString : () ->
      res = ""
      for f in toStringFunctions
        res += f()
      return res
  }
exports.subproof = subproof




# All ways of describing a `rule` use this class 
# (including `rule.premise` below).
class _From
  constructor: (requirement) ->
    requirement = convertTextToRequirementIfNecessary(requirement)
    @_requirements = {
      from : ([requirement] if requirement?) or []
      to : undefined
    }

  type : 'rule'

  'and' : (requirement) ->
    requirement = convertTextToRequirementIfNecessary(requirement)
    @_requirements.from.push requirement
    return @ 

  to : (requirement) ->
    if @_requirements.to
      throw new Error "You cannot specify `.to` more than once in a single rule."
    requirement = convertTextToRequirementIfNecessary(requirement)
    @_requirements.to = requirement
    return @

  check : (line) ->
    # return new LineChecker(line, @_requirements).check()
    return checkRequirementsMet(line, @_requirements)


# `from` is the main entry point for this module.  Use it
# like: `rule.from('φ and ψ').to('φ')`. 
from = (requirement) ->
  return new _From(requirement)
exports.from = from


# This allows you to create a rule without any `.from` clause,
# as in `rule.to('α=α')` (for identity introduction).
to = (requirement) ->
  return from().to(requirement)
exports.to = to



checkRequirementsMet = (line, theReqs) ->
  preliminaryTest = checkCorrectNofLinesAndSubproofsCited(line, theReqs)
  return false unless preliminaryTest
  
  citedLines = []
  # We make sure that each thing cited is a distinct object (which it need
  # not be since the same line can be cited twice).  This will make it simpler
  # to keep track of which lines have been matched later.
  for l in line.getCitedLines()
    if l in citedLines
      citedLines.push(_.clone(l))
    else
      citedLines.push(l)
  # Don’t do the same for citedBlocks because _.clone removes some functions
  # we will need to call.  
  # TODO: find a way around this!  (Maybe need more elegant method to keep
  # track of what has been cited.)
  citedBlocks= line.getCitedBlocks()
  # console.log "Start checking #{ruleName} at line #{line.number} ..."
  
  # We may have to consider any permutation of the order of the lines and blocks
  # (as well as permutations of the order of the rules later):
  # TODO: check whether this is really necessary.
  citedLinesPerms = _permutations citedLines
  citedBlocksPerms = _permutations citedBlocks
  for citedLineOrdering in citedLinesPerms
    for citedBlockOrdering in citedBlocksPerms
      test = areRequirementsMetByTheseLinesAndBlocks(theReqs, line, citedLineOrdering, citedBlockOrdering)
      return true if test isnt false
  
  # The rule was not used correctly so update status message:
  
  # This method is called if it has been established that there is no 
  # path along which all requirements can be met.
  ruleName = line.getRuleName()
  msg = []
  if theReqs.to?
    msg.push "on a line with the form #{theReqs.to}"
  for r in theReqs.from
    if r.type is 'subproof'
      msg.push " citing a subproof of the form #{r}"
    else
      msg.push " citing a line of the form #{r}"
  line.status.addMessage "you can only use #{ruleName} #{msg.join('; ')}."
  return false

areRequirementsMetByTheseLinesAndBlocks = (theReqs, line, citedLineOrdering, citedBlockOrdering) ->
  checkList = []
  if theReqs.to?
    checkList.push {
      req : theReqs.to
      linesOrBlocks : [line]
    }
    
  for aReq in theReqs.from
    checkList.push {
      req : aReq
      linesOrBlocks : (citedBlockOrdering if aReq.type is 'subproof') or citedLineOrdering
    }
  
  # If possible we will start with the `.to` requirement and then check 
  # the `.from` requirements in the order they were given.  (This allows rule 
  # writers to optimise by writing the rule in an intuitive way.)
  # checkList.reverse()
  
  # Cycle through all possible orderings of rules
  # (This matters because in cases like a=c, b=c therefore a=b there may
  # be multiple ways of meeting any single requirement.)
  checkListPermutations = _permutations(checkList)
  for thingsToCheck in checkListPermutations
    test = areAllRequirementsMet(thingsToCheck)
    return true if test isnt false

  return false

checkCorrectNofLinesAndSubproofsCited = (line, theReqs) ->
  citedLines = line.getCitedLines()
  nofCitedLines = citedLines.length
  citedBlocks = line.getCitedBlocks()
  nofCitedBlocks = citedBlocks.length
  
  nofLinesNeeded = 0
  nofSubproofsNeeded = 0
  for r in theReqs.from
    if r.type is 'subproof'
      nofSubproofsNeeded += 1
    else
      nofLinesNeeded += 1

  test = (nofLinesNeeded is nofCitedLines) and (nofSubproofsNeeded is nofCitedBlocks)
  return true if test is true
  
  # From here, we are just creating a message for the proof writer.
  expectedLinesTxt = numberToWords nofLinesNeeded, 'line'
  expectedBlocksTxt = numberToWords nofSubproofsNeeded, 'subproof'
  expectedAndText = \
    ("and " if expectedLinesTxt and expectedBlocksTxt) \
    or ("nothing" if not expectedLinesTxt and not expectedBlocksTxt) \
    or ""
  actualLinesTxt = numberToWords nofCitedLines, 'line'
  actualBlocksTxt = numberToWords nofCitedBlocks, 'subproof'
  actualAndText = \
    ("and " if actualLinesTxt and actualBlocksTxt) \
    or ("nothing" if not actualLinesTxt and not actualBlocksTxt) \
    or ""
  ruleName = line.getRuleName()
  line.status.addMessage "you must cite #{expectedLinesTxt} #{expectedAndText}#{expectedBlocksTxt} when using the rule #{ruleName} (you cited #{actualLinesTxt} #{actualAndText}#{actualBlocksTxt}).".replace /\s\s+/g, ' ' 
  return false

areAllRequirementsMet = (thingsToCheck) ->
  # console.log "  Start checking all requirements from scratch ..."
  matchedLinesAndBlocks = []
  currentMatches = {}
  for checkThis in thingsToCheck
    req = checkThis.req
    candidates = []
    for c in checkThis.linesOrBlocks
      unless c in matchedLinesAndBlocks
        candidates.push(c)
    # candidates = checkThis.linesOrBlocks
    test = doAnyCandidatesMeetThisReq(req, candidates, currentMatches)
    return false if test is false
    {newMatches, matchedLineOrBlock} = test
    currentMatches = newMatches
    matchedLinesAndBlocks.push(matchedLineOrBlock)
  return true

# Returns false or the new matches made in meeting the requirement.
doAnyCandidatesMeetThisReq = (req, candidates, priorMatches) ->
  for lineOrBlock in candidates
    test = req.check(lineOrBlock, priorMatches)
    if test isnt false 
      return {
        newMatches : test
        matchedLineOrBlock : lineOrBlock
      }
  # console.log "  failed to satisfy #{req}"
  return false
        


# Use `rule.premise()` when the line in question
# must be a premise or assumption.
# TODO: can we not just use `line.isPremise()`?
premise = () ->
  # We start with the empty rule (which checks that no
  # lines are cited for us) and elaborate its check method.
  premiseRule = from()
  baseCheck = premiseRule.check.bind(premiseRule)
  
  premiseRule.check = (line) ->
    result = baseCheck(line)
    return result if result isnt true
    
    # The first line of any proof or subproof can be a premise.
    return true if not line.prev
    
    # From now on we know that this is not the first line of a proof or subproof.
    
    lineIsInASubproof = line.parent.parent?
    if lineIsInASubproof
      line.status.addMessage "only the first line of a subproof may be a premise."
      return false
    
    # From this point on, we are in the main proof (not in a subproof).
    
    # Is there a non-premise or subproof above line?
    isNeitherAPremiseNorASubproof = (item) ->
      if item.type is 'line'
        thisIsAPremise = item.justification?.rule.connective is 'premise'
        return false if thisIsAPremise 
        return true if not thisIsAPremise
      if item.type is 'block'   # A block is a subproof.
        return true
      # We don't care about dividers, blank lines and whatever else.
      return false
    thereIsANonPremiseAbove = line.findAbove( isNeitherAPremiseNorASubproof )
    if thereIsANonPremiseAbove
      line.status.addMessage  "premises may not occur after non-premises."
      return false
    return true
    
  return premiseRule
exports.premise = premise      


_notImplementedYet = (line) ->
  throw new Error "the rule `#{line.justification.rule.connective}` (or some part of it) is not implemented yet!"
exports._notImplementedYet = _notImplementedYet


parseAndDecorateIfNecessary = (sentence) ->
  if _.isString sentence
    sentence = fol.parse sentence, parser
  return sentence

_parseNameIfNecessaryAndDecorate = (name) ->
  return name unless _.isString(name)
  sentence = parseAndDecorateIfNecessary("F(#{name})")
  return sentence.termlist[0]
  


# helper : create all permutations involving every element of `list`
# modified from https://gist.github.com/md2perpe/8210411
# (Different from the `permutations` function below which gives numbered lists.)
_permutations = (list) ->
  # Empty list has one permutation
  return [ [] ] if list.length is 0
    
  result = []
  for i in [0..(list.length-1)]
    copy = _.clone(list)
    # Cut one element from list
    head = copy.splice(i, 1)
    # Permute rest of list
    rest = _permutations(copy)
    # Add head to each permutation of rest of list
    for j in [0..(rest.length-1)]
      next = head.concat(rest[j])
      result.push next
  result
# exported for testing only
exports._permutations = _permutations



numberToWords = (num, type) ->
  return '' if num is 0
  return "1 #{type}" if num is 1
  return "#{num} #{type}s" if num > 1


