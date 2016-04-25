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
substitute = require '../substitute'
fol = require '../fol'


# Rules can be written using any parser.
# (Note that the parser in which the rules are written doesn’t have to be
# the parser in which proofs are written).
parser = undefined 
exports.setParser = (aParser) ->
  parser = aParser



tickIf = {}
exports.tickIf = tickIf
_allRulesUsedInThisBlock = (candidateLines, block, ruleSet) ->
  rulesUsed = []
  for l in candidateLines
    if l.parent is block
      for ruleAndMatches in l.rulesChecked
        r = ruleAndMatches.rule
        rulesUsed.push(r)
  rulesStillToUse = []
  for r in ruleSet
    rulesStillToUse.push(r) unless r in rulesUsed
  return true if rulesStillToUse.length is 0
  children = block.getChildren()
  return false unless children?.length > 0
  for childBlock in children
    test = _allRulesUsedInThisBlock(candidateLines, childBlock, rulesStillToUse)
    return false if test is false
  return true
tickIf.allRulesAppliedInEveryBranch = ( ruleSet ) ->
  return (line) ->
    candidateLines = line.getLinesThatCiteMe()
    return _allRulesUsedInThisBlock(candidateLines, line.parent, ruleSet)

_someRulesUsedInThisBlock = (candidateLines, block, ruleSet) ->
  for l in candidateLines
    if l.parent is block
      for ruleAndMatches in l.rulesChecked
        r = ruleAndMatches.rule
        return true if r in ruleSet
  children = block.getChildren()
  return false unless children?.length > 0
  for childBlock in children
    test = _someRulesUsedInThisBlock(candidateLines, childBlock, ruleSet)
    return false if test is false
  return true
tickIf.someRuleAppliedInEveryBranch = ( ruleSet ) ->
  return (line) ->
    candidateLines = line.getLinesThatCiteMe()
    return _someRulesUsedInThisBlock(candidateLines, line.parent, ruleSet)

tickIf.ruleAppliedAtLeastOnceAndAppliedToEveryExistingConstant = ( rule ) ->
  return (line) -> 
    # Is the rule applied at least once?:
    test1 = tickIf.someRuleAppliedInEveryBranch([rule])
    result1 = test1(line)
    return false unless result1
      

# All ways of describing a `rule` do and *MUST* use this class 
# (see `rule.premise` below for how to use this class).
class _From
  constructor: (requirement) ->
    requirement = convertTextToRequirementIfNecessary(requirement)
    @_requirements = {
      from : ([requirement] if requirement?) or []
      to : undefined
    }
    @whereReqs = []
    @andAlso = @
  
  type : 'rule'

  'and' : (requirement) ->
    requirement = convertTextToRequirementIfNecessary(requirement)
    @_requirements.from.push requirement
    return @ 

  to : (requirement) ->
    if @_requirements.to?
      throw new Error "You cannot specify `.to` more than once in a single rule."
    requirement = convertTextToRequirementIfNecessary(requirement)
    @_requirements.to = requirement
    if requirement.isBranchingRule
      @isBranchingRule = true
    return @

  where : (requirement) ->
    @whereReqs.push requirement
    return @ 

  check : (line) ->
    # First test `.from` and `.to` requirements
    test = checkRequirementsMet(line, @_requirements)
    return false if test is false
    # Store info about the rule and matches in the line
    # (this is useful for tree proofs):
    currentMatches = test
    # Test the `.where` requirements
    for req in @whereReqs
      test = req.check(line, currentMatches, @)
      return false if test is false
      currentMatches = test
    # All tests passed:
    line.rulesChecked ?= []
    line.rulesChecked.push({rule:@, matches:currentMatches})
    return true
  

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


# A `.where` check function
exports.previousLineMatches = (pattern) ->
  if _.isString(pattern)
    pattern = fol.parse(pattern)
  return check:(line, priorMatches, rule)->
    previousLine = line.prev
    # The line immediately above may be a divider or blank:
    while not previousLine.sentence? and previousLine.prev?
      previousLine = previousLine.prev
    return false unless previousLine?.sentence?
    # console.log previousLine.sentence.toString()
    # console.log pattern.toString()
    # console.log "#{_matchesToString(priorMatches)}"
    return doesLineMatchPattern(previousLine, pattern, priorMatches)
  

exports.previousLineCitesSameLines = () ->
  return check:(line, priorMatches, rule)->
    previousLine = line.prev
    # The line immediately above may be a divider or blank:
    while not previousLine.sentence? and previousLine.prev?
      previousLine = previousLine.prev
    # They must cite the same number of lines:
    return false unless line.getCitedLines().length is previousLine.getCitedLines().length
    # They must cite the same lines:
    linesCitedByBoth = _.intersection( line.getCitedLines(), previousLine.getCitedLines() )
    return linesCitedByBoth.length is line.getCitedLines().length

# A `.where` check function.
# Use like `rule.from('exists τ φ').to( rule.matches('φ[τ-->α]').and.branches() ).where( rule.ruleIsAppliedToEveryExistingConstantAndANewConstant('α') )`
exports.ruleIsAppliedToEveryExistingConstantAndANewConstant = (termMetaVarName) ->
  return check:(line, priorMatches, rule)->
    # Have all siblings been checked already?
    # The test passes if not.
    sisterBranches = line.parent.parent.getChildren()
    siblings = (x.getFirstLine() for x in sisterBranches)
    for sib in siblings
      # ignore this line:
      continue if sib is line
      return priorMatches unless sib.rulesChecked?.length > 0
      rules = (x.rule for x in sib.rulesChecked)
      return priorMatches unless rule in rules
      
    # Get a list of all names ocurring in the branch above:
    namesInBranch = []
    walker = (item) ->
      if item.sentence?
        namesInBranch.push(item.sentence.getNames())
      return undefined # keep walking
    line.findAbove(walker)
    namesInBranch = _.uniq(_.flatten(namesInBranch))
    
    # Get a list of names matched in applying the rule:
    namesMatchedInApplyingTheRule = []
    for sib in siblings
      rulesChecked = sib.rulesChecked or [{rule, matches:priorMatches}]
      for ruleAndMatch in rulesChecked
        if ruleAndMatch.rule is rule
          theMatches = ruleAndMatch.matches
          nameMatch = theMatches[termMetaVarName]
          namesMatchedInApplyingTheRule.push(nameMatch.name)
    
    for name in namesInBranch
      unless name in namesMatchedInApplyingTheRule
        line.status.addMessage("you don’t have a branch for the name ‘#{name}’")
        return false 
    # One of the names to which the rule is applied must be a name
    # that doesn’t feature anywhere above:
    for name in namesMatchedInApplyingTheRule
      if not (name in namesInBranch)
        return priorMatches 
    line.status.addMessage("you don’t branch for a new name")
    return false
  


# For testing only:
_matchesToString = (priorMatches) ->
  res = ""
  for key of priorMatches
    res += "#{key} : #{fol._decorate(priorMatches[key]).toString()} ; "
  return res

# for trees
branch = (sentence) ->
  return matches(sentence).isFirstLineOfASubproof()
exports.branch = branch

# Use like rule.from( rule.matches('ψ[τ-->α]').and.isNewName('α') ).to(...
matches = (sentence) ->
  pattern = parseAndDecorateIfNecessary(sentence)
  # All check functions must return (1) false if check fails, or 
  # the new matches involved in applying the rule if check succeeds
  # (if there are no new matches, just return `priorMatches`)
  baseCheck = (line, priorMatches) ->
    test = doesLineMatchPattern(line, pattern, priorMatches)
    return test
  checkFunctions = [baseCheck]
  rulePart = {
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
    
    # Use like `matches('phi').and.branches()
    branches : () ->
      @isBranchingRule = true
      newCheck = (line, priorMatches) ->
        block = line.parent
        # This must be a subproof (not the main proof):
        unless block.parent?
          line.status.addMessage('to use this rule you must branch')
          return false
        unless block.getFirstLine() is line
          line.status.addMessage('to use this rule you must branch')
          return false 
        return priorMatches
      checkFunctions.push newCheck
      return @
      
    # Use like `matches('phi').and.doesntBranch()
    doesntBranch : () ->
      newCheck = (line, priorMatches) ->
        block = line.parent
        # Fine unless we are the first line of a subproof:
        if block?.getFirstLine() is line
          line.status.addMessage('you cannot use this rule to branch')
          return false
        return priorMatches
      checkFunctions.push newCheck
      return @
  }
  rulePart.and = rulePart
  return rulePart
exports.matches = matches


# Supports rules of replacement (see Magnus or Bergmann et al).
# Use like: rule.from('φ').to( rule.replace('φ', {from:'ψ or χ', to:'χ or ψ'}) )
# Does not support substitutions in any params (because no need).
# Also does not support matching the expression meta variables in 
# the subsitution ` {from:'ψ or χ', to:'χ or ψ'}` (because no need).
exports.replace = (sentence, sub) ->
  pattern = parseAndDecorateIfNecessary(sentence)
  sub.from = parseAndDecorateIfNecessary(sub.from)
  sub.to = parseAndDecorateIfNecessary(sub.to)
  baseCheck = (line, priorMatches) ->
    # First check that `priorMatches` contains matches for 
    # everything in `pattern`:
    metaVariableNames = pattern.listMetaVariableNames()
    for varName in metaVariableNames.inExpression
      if not (varName of priorMatches)
        # console.log "    fail check because #{varName} not of priorMatches, #{_matchesToString(priorMatches)}"
        return false
    
    patternClone = pattern.clone().applyMatches(priorMatches)
    
    aSentence = line.sentence
    if not patternClone.box? and aSentence.box?
      aSentence = aSentence.clone()
      delete aSentence.box
    return substitute.isOneASubstitutionInstanceOfTheOther(aSentence, patternClone, sub)

    patternAfterSubs = substitute.doSubRecursive(patternClone, sub)
    fol._decorate patternAfterSubs
    return doesLineMatchPattern(line, patternAfterSubs, priorMatches)
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
      return "#{pattern.toString()}[#{sub.from.toString()}-->#{sub.to.toString()}]"
  }
    
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
  return matches(requirement) if _.isString(requirement)
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
        # Get the lines of proof against which we will match:
        linesOfProof = []
        for item in subproof.content
          if item.type is 'line'
            unless item.isPremise()  # we aren’t allowed to match premises
              linesOfProof.push(item) 
        return linesContainPatterns(linesOfProof, listOfSentencesThatMustBeInSubproof, priorMatches)
      checkFunctions.push newCheck
      newToString = () ->
        ", where this subproof contains #{(x.toString() for x in listOfSentencesThatMustBeInSubproof).join(' and ')}"
      toStringFunctions.push newToString
      return @
    
    toString : () ->
      res = ""
      for f in toStringFunctions
        res += f()
      return res
  }
exports.subproof = subproof


# Attempt to find matches for each of `listOfPatterns (e.g. `['φ', 'not φ']`)
# in `listOfLines`.  Return new matches if success; otherwise return false.
# TODO: permuting order of lines is a bit suboptimal!
# TODO: don’t need to permuate order of patterns if we optimise order by
# considering whether one pattern matches another (e.g. 'φ' matches 'not φ' but
# not conversely).
linesContainPatterns = (listOfLines, listOfPatterns, priorMatches) ->
  patternsPerms = _permutations(listOfPatterns)
  linesPerms = _permutations(listOfLines)
  for thePatterns in patternsPerms
    for someLines in linesPerms
      test = _allPatternsAreMatched(someLines, thePatterns, priorMatches)
      return test if test isnt false
  return false
# Are all thePatterns matched in theLines?
_allPatternsAreMatched = (listOfLines, thePatterns, priorMatches) ->
  newMatches = priorMatches
  for pattern in thePatterns
    test = _doesPatternMatchAnyLines(listOfLines, pattern, newMatches)
    return false if test is false
    newMatches = test
  return newMatches
# Do any of `theLines` match `pattern`?
_doesPatternMatchAnyLines = (listOfLines, pattern, priorMatches) ->
  for line in listOfLines
    sentence = line.sentence
    test = sentence.findMatches(pattern, priorMatches)
    # console.log "tested req #{pattern.toString()} against #{line.sentence}, res is #{test}, newMatches contains entries for #{(x.toString() for x in _.keys(test)).join(', ')} with newMatches.ψ = #{fol._decorate(test.ψ).toString() if test.ψ}"
    return test unless test is false
  # We didn’t find any lines that match pattern:
  # console.log "didn’t find #{pattern} with #{_matchesToString(priorMatches)}"
  return false
# For testing only :
exports.linesContainPatterns = linesContainPatterns


# Return false if not; matches made if yes.
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
      if test isnt false
        theMatches = test
        return theMatches
  
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
    if test isnt false
      theMatches = test
      return theMatches

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
  return currentMatches

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
# Use like `rule.from().to( rule.premise() )`
# Note: we cannot just use `line.isPremise()` because we do not
# want to allow that a subproof can have more than one premise?
# TODO: should be used like rule.from().to( rule.premise() )
premise = () ->
  premiseRule = (line, priorMatches) ->
    # The first line of any proof or subproof can be a premise.
    return priorMatches if not line.prev
    
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
    return priorMatches
    
  return {check:premiseRule}
exports.premise = premise      

phi = fol.parse('φ')
notPhi = fol.parse('not φ')
notAIsA = fol.parse('not α=α')

closeBranch = () ->
  return {
    check : (line, priorMatches) ->
      # Nothing can come after the closure of a branch!
      if line.next?
        line.status.addMessage "You can only close on the final line of a branch."
        return false 
      lines = line.findAllAbove( (item) -> item.type is 'line' )
      # console.log "lines.length = #{lines.length}"
      test = linesContainPatterns(lines, [phi, notPhi], {})
      return priorMatches if test isnt false
      test2 = linesContainPatterns(lines, [notAIsA], {})
      return priorMatches if test2 isnt false
      # Failed to close:
      line.status.addMessage "You can only close a branch if it contains either a sentence like ‘¬α=α’, or two sentences like ‘φ’ and ¬‘φ’."
      return false
  }
exports.closeBranch = closeBranch

openBranch = () ->
  return {
    check : (line, priorMatches) ->
      # Nothing can come after marking a branch open!
      if line.next?
        line.status.addMessage "You can only put a ‘branch open’ marker on the final line of a branch."
        return false 
      lines = line.findAllAbove( (item) -> item.type is 'line' )
      test = linesContainPatterns(lines, [phi, notPhi], {})
      test2 = linesContainPatterns(lines, [notAIsA], {})
      unless ((test is false) and (test2 is false))
        line.status.addMessage "You can only mark a branch open if it contains neither a sentence like ‘¬α=α’, nor two sentences like ‘φ’ and ¬‘φ’."
        return false
      # Basic tests passed.
      # TODO: Must now check that the branch is complete
      return priorMatches
      
  }
exports.openBranch = openBranch

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


