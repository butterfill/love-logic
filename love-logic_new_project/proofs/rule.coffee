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

parser = undefined 
exports.setParser = (parser) ->
  parser = parser

# All ways of describing a `rule` use this class.
class _From
  constructor: (requirement) ->
    requirement = _parseIfNecessaryAndDecorate requirement
    @_requirements = {
      from : ([requirement] if requirement) or []
      to : undefined
    }

  type : 'rule'

  'and' : (requirement) ->
    requirement = _parseIfNecessaryAndDecorate requirement
    @_requirements.from.push requirement
    return @ 

  to : (requirement) ->
    if @_requirements.to
      throw new Error "You cannot specify `.to` more than once in a single rule."
    requirement = _parseIfNecessaryAndDecorate requirement
    @_requirements.to = requirement
    return @

  check : (line) ->
    return new LineChecker(line, @_requirements).check()


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


# When the prerequisites for a rule include subproofs,
# specify them using `rule.subproof` as in:
# `rule.from( rule.subproof('φ','contradiction') ).to('not φ')`.
subproof = (startReq, endReq) ->
  startReq = _parseIfNecessaryAndDecorate startReq
  endReq = _parseIfNecessaryAndDecorate endReq
  return { 
    type : 'subproof'
    startReq 
    endReq 
    
    # Some methods allow us to treat lines and subproofs interchangeably.
    listMetaVariableNames : () ->
      result = @startReq.listMetaVariableNames()
      result = _.defaults( result, @endReq.listMetaVariableNames() )
      return result
    
    toString : () ->
      return "#{startReq.toString()} ⊢ #{endReq.toString()}"
    
  }
exports.subproof = subproof


# Use `rule.premise()` when the line in question
# must be a premise or assumption.
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


_parseIfNecessaryAndDecorate = (requirement) ->
  return requirement if not requirement   # Using `.to` creates undefined requirements.
  return requirement if requirement.type is 'subproof'
  if _.isString requirement
    requirement = fol.parse requirement, parser
  fol._decorate requirement
  return requirement



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

# ------------------
# The following provide a way of checking whether a line citing
# a rule is correct.  (You should only need to use these via `rule.from`.)
# ------------------


# Objects of this class (a) check whether the right number of lines and subproofs 
# have been cited; and (b) transform the requirements into `RequirementChecker`
# objects to pass on to a `Pathfinder`.
# TODO: simplify this and the rest into a chain of functions (don't need classes!).
class LineChecker
  constructor : (@line, @requirements) ->
    @citedLines = @line.getCitedLines()
    @citedBlocks = @line.getCitedBlocks()

    @ruleName = @line.getRuleName()
    
    # This property is used to keep track of `substitute.findMacthes` that
    # will constrain test of the requirements.
    @matches = null
    
  check : () ->
    return @ unless @citedTypesAreCorrect()
    
    reqCheckList = []
    if @requirements.to
      reqCheckList.push( new RequirementChecker(@requirements.to, [@line]) )
    for aReq in @requirements.from
      if aReq?.type? and aReq.type is 'subproof'
        reqCheckList.push( new RequirementChecker(aReq, @citedBlocks) )
      else
        reqCheckList.push( new RequirementChecker(aReq, @citedLines) )
    
    # If possible we will start with the `.to` requirement and then check 
    # the `.from` requirements in the order they were given.  (This allows rule 
    # writers to optimise by writing the rule in an intuitive way.)
    # (Note that the `Pathfinder` may need to change the order.)
    # (TODO: the `Pathfinder` does still need to change the order, but why?)
    reqCheckList.reverse()
    
    # Cycle through all possible orderings of rules
    # (This matters because in cases like a=c, b=c therefore a=b there may
    # be multiple ways of meeting any single requirement.)
    reqCheckListPermutations = _permutations(reqCheckList)
    pathFound = false
    while not pathFound and reqCheckListPermutations.length > 0
      toCheck = reqCheckListPermutations.shift()
      path = new Pathfinder( toCheck, @line )
      pathFound = path.find()
      # console.log "#{reqCheckListPermutations.length} #{pathFound}"
    
    if pathFound
      return true
    else 
      # console.log "\tLineChecker instance, checked toRequirement, getMessage() = #{@line.status.getMessage()}"
      return @
  
  citedTypesAreCorrect : () ->
    expected = @whatToCite()
    actual = 
      lines : @citedLines.length
      subproofs : @citedBlocks.length
    if expected.lines is actual.lines and expected.subproofs is actual.subproofs
      return true

    # From here, we are just creating a message for the proof writer.
    expectedLinesTxt = numberToWords expected.lines, 'line'
    expectedBlocksTxt = numberToWords expected.subproofs, 'subproof'
    expectedAndText = \
      ("and " if expectedLinesTxt and expectedBlocksTxt) \
      or ("nothing" if not expectedLinesTxt and not expectedBlocksTxt) \
      or ""
    actualLinesTxt = numberToWords actual.lines, 'line'
    actualBlocksTxt = numberToWords actual.subproofs, 'subproof'
    actualAndText = \
      ("and " if actualLinesTxt and actualBlocksTxt) \
      or ("nothing" if not actualLinesTxt and not actualBlocksTxt) \
      or ""
    @line.status.addMessage "you must cite #{expectedLinesTxt} #{expectedAndText}#{expectedBlocksTxt} when using the rule #{@ruleName} (you cited #{actualLinesTxt} #{actualAndText}#{actualBlocksTxt}).".replace /\s\s+/g, ' ' 

    return false

  whatToCite : () ->
    result = lines: 0, subproofs: 0
    for r in @requirements.from
      if r.type is 'subproof'
        result.subproofs += 1
      else
        result.lines += 1
    return result
  

class RequirementChecker
    # Param `@matches` is an object containing the prior matches that must be respected
    # in checking whether this requirement is met.
    # param `@matches` will not be mutated.
    # `candidateLinesOrSubproofs` is a list of lines or subproofs against
    # which to check the requirement.
    constructor : (@theRequirement, @candidateLinesOrSubproofs, @matches={}) ->
      # This clones `@matches`, ensuring it will not be mutated.
      @saveMatches(@matches)
      
      # Store names of metavariables (such as α and ψ)  in the 
      # requirement to be checked.
      @metaVariableNames = @theRequirement.listMetaVariableNames()
    
    setMatches : (@matches) ->
      @saveMatches(@matches)
    
    # These methods allow the `Pathfinder` to try out different possibilities,
    # saving and then restoring the matches between attempts.
    # TODO: this is a bit fragile (setting `@matches` directly could cause
    # subtle errors).  
    _matchesStack : []
    saveMatches : () ->
      newMatches = _.cloneDeep( @matches )
      @_matchesStack.push(newMatches)
      @matches = newMatches
      return undefined
    restoreMatches : () ->
      @_matchesStack.pop()
      [..., @matches] = @_matchesStack
      return undefined
   
    tempRemovedCandidates : {}
    temporarilyRemoveCandidate : (lineNumber) ->
      _toRemove = (x for x in @candidateLinesOrSubproofs when x.number is lineNumber)
      if _toRemove.length is 1
        @tempRemovedCandidates[lineNumber] = _toRemove[0]
        @candidateLinesOrSubproofs = (x for x in @candidateLinesOrSubproofs when x.number isnt lineNumber)
    restoreCandidate : (lineNumber) ->
      if lineNumber of @tempRemovedCandidates
        @candidateLinesOrSubproofs.push( @tempRemovedCandidates[lineNumber] )
        delete @tempRemovedCandidates[lineNumber] 
   
    # Check whether this requirement can be checked yet.
    # (Testing it may depend on what is in @matches).
    canCheckAlready : () ->
      mustBeInMatches = @metaVariableNames.inSub.left
      for varName in mustBeInMatches
        if not (varName of @matches)
          # console.log "... fail #{varName} not of @matches"
          return false 
      return true
    
    # At this stage, there may be several lines or subproofs 
    # that meet a requirement.
    # Test the requirement against each candidate line or subproof;
    # and, where the requirement could be met by one or more candidates, 
    # return a map from the names of the lines to the matches needed 
    # to meet the requirement.
    check : () ->
      results = false
      for candidate in @candidateLinesOrSubproofs
        newMatches = @_checkOne candidate      
        if newMatches isnt false
          results = results or {}
          results[candidate.number] = newMatches 
      return results
    
    _checkOne : (candidate) ->
      if @theRequirement.type? and @theRequirement.type is 'subproof'
        # If the candidate isn’t a subproof, the requirement can’t be met
        return false unless candidate.type is 'block'
        
        newMatches = @_checkOneLine @theRequirement.startReq, candidate.getFirstLine(), @matches
        return false if newMatches is false
        moreNewMatches = @_checkOneLine @theRequirement.endReq, candidate.getLastLine(), newMatches
        return moreNewMatches
      
      # @theRequirement just concerns a line, not a subproof.
      # If the candidate is a block, the requirement can’t be met
      return false unless candidate.type isnt 'block'
      newMatches = @_checkOneLine(@theRequirement, candidate, @matches)
      # console.log @matches
      # console.log "checked #{@theRequirement.toString({replaceSymbols:true})} against #{candidate.sentence.toString({replaceSymbols:true})}"
      return newMatches
    
    _checkOneLine : (aReq, aLine, priorMatches) ->
      reqClone = aReq.clone().applyMatches(priorMatches)
      
      # Special case: there was a subsutition like `[a-->null]` which
      # results in `e` being null.  This indicates a requirement has 
      # not been met.
      testVerbotenName = reqClone.applySubstitutions()
      if testVerbotenName is null
        return false

      # Note: We must NOT apply substitutions before doing `.findMatches`.
      # (Because `.findMatches` needs to selectively apply substitutions,
      # whereas `.applySubstitutions` replaces all matches indiscriminately.)
      aSentence = aLine.sentence
      # We might in principle be citing a blank line or something:
      return false unless aSentence?
      if not reqClone.box? and aSentence.box?
        aSentence = aSentence.clone()
        delete aSentence.box
      # console.log "#{reqClone.toString({replaceSymbols:true})}"
      newMatches = aSentence.findMatches reqClone, priorMatches
        
      # console.log "_checkOneLine sentence = #{aLine.sentence.toString()}"
      # console.log "_checkOneLine aReq = #{aReq.toString()}"
      # console.log "_checkOneLine reqClone = #{reqClone.toString()}"
      # console.log "_checkOneLine priorMatches = #{util.matchesToString priorMatches}"
      # console.log "_checkOneLine newMatches = #{util.matchesToString newMatches}"
      
      return newMatches if (newMatches is false)
      
      # Special case: if `aReq` involves a box, we need to apply the requirement
      # that the name in the box must not already occur in the proof.
      if reqClone.box? or (reqClone.type is 'box')
        aBox = (reqClone if reqClone.type is 'box') or (reqClone.box if reqClone.box?)
        
        # Do this or fail test `454092AA-57A4-11E5-9C09-B0C78BD11E5D`.
        # (It's necessary because the box may contain a `term_metavariable` which
        # we have only now just matched.)
        aBox = aBox.applyMatches(newMatches).applySubstitutions()
        
        # The name in the box must not occur on a line earlier in the proof
        # (although it may appear in earlier subproofs).
        theName = aBox.term.name
        iSALineContainingTheName = (lineOrBlock) ->
          # Note: we don't care if the name occurs in closed subproofs
          # as long as it doesn't occur in any line above this one.
          return false if lineOrBlock.type isnt 'line'
          return true if (theName in lineOrBlock.sentence.getNames())
          return false
        nameInBoxIsAlreadyUsedInProof = aLine.findAbove( iSALineContainingTheName )
        newMatches = false if nameInBoxIsAlreadyUsedInProof
      
      return newMatches

      
# Some requirements can sometimes be met in multiple ways (by matching 
# different lines), as for example in the rule for contradiction 
# introduction applied to `not not A` and `not A`.
# The `Pathfinder` explores different paths through which requirements 
# could be met: if there is a way of meeting the requirements in `reqCheckList`,
# it will be found.  
class Pathfinder
  constructor : ( reqCheckList, @line, @matches = {} ) ->
    # We will make a copy of `reqCheckList` to avoid mutating our parameters
    # (which is essential given that we'll use this class recursively).
    @reqCheckList = (x for x in reqCheckList)
    @line.status.clearMessages()
    
  find : () ->
    # If there are no more requirements to meet, we have found a 
    # path along which all requirements can be met.
    if @reqCheckList.length is 0
      return true
    
    reqChecker = @reqCheckList.pop()
    # Note that we must `.setMatches` before testing `.canCheckAlready()`.
    reqChecker.setMatches(@matches)
    
    # Find the first item in `reqCheckList` that we can already check;
    numChecked = 0
    # Note: the limit is `(@reqCheckList.length+1)` because we already popped one from `@reqCheckList`.
    while ( not reqChecker.canCheckAlready() ) and (numChecked < (@reqCheckList.length+1))
      @reqCheckList.unshift(reqChecker)
      reqChecker = @reqCheckList.pop()
      reqChecker.setMatches(@matches)
      numChecked += 1
    
    if numChecked is (@reqCheckList.length+1) 
      # We couldn't find a `req` with `.canCheckAlready()` true.
      # Unless there is an error with the rule, this should not happen.
      throw new Error "Rule problem!  I can’t start checking any of the conditions in the rule." 
    
    results = reqChecker.check()
    if results is false
      @writeMessage(reqChecker)
      return false
    
    # From here on, the `reqChecker` found one or more lines where the 
    # requirement was met.

    # Now explore whether the other requirements can be met starting with
    # any of these lines and matches.
    for lineNumber, aMatches of results
      # Do not allow the requirements in @reqCheckList to further consider `lineNumber`.
      (x.temporarilyRemoveCandidate(lineNumber) for x in @reqCheckList)
      newPath = new Pathfinder( @reqCheckList, @line, aMatches )
      result =  newPath.find()
      (x.restoreCandidate(lineNumber) for x in @reqCheckList)
      return true if result is true
    
    # So none of the `newPath`s provided a route to meeting all the `reqCheckList`
    # requirements.
    return false
  
  # This method is called if it has been established that there is no 
  # path along which all requirements can be met.
  # Param `reqChecker` is the last in `reqCheckList` for which there is no path.
  writeMessage : (reqChecker) ->
    # `reqChecker.theRequirement.type` is 'subproof' or the type of the awFOL sentence (e.g. `not` or `or`)
    requirementConcernsCurrentLine = @line.number is reqChecker.candidateLinesOrSubproofs[0]?.number
    if requirementConcernsCurrentLine
      # TODO: replaceSymbols needs to take into account the user’s preferred symbols
      @line.status.addMessage("You can only use #{@line.getRuleName()} on a line with the form ‘#{reqChecker.theRequirement.toString({replaceSymbols:true})}’.")
    else
      thingToCite = reqChecker.theRequirement.type
      thingToCite = 'line' unless thingToCite is 'subproof'
      # TODO: replaceSymbols needs to take into account the user’s preferred symbols
      @line.status.addMessage("to apply #{@line.getRuleName()} you need to cite a #{thingToCite} with the form ‘#{reqChecker.theRequirement.toString({replaceSymbols:true})}’.")
    # console.log @line.status.getMessage()




numberToWords = (num, type) ->
  return '' if num is 0
  return "1 #{type}" if num is 1
  return "#{num} #{type}s" if num > 1



permutations = (n) ->
  return [[0]] if n is 1
  base = permutations(n-1)
  result = []
  for i in [0..n-1]
    for p in base
      l = _.clone p
      l.unshift(n-1)
      old = l[i]
      l[i] = n-1
      l[0] = old
      result.push(l)
  return result
    

truthtable = (nofLetters) ->
  return combinations(nofLetters, 2).reverse()

combinations = (length, max) ->
  if length is 1
    return ([x-1] for x in [1..max])
  r = (([x,y] for x in [1..max]) for y in [1..max])
  base = combinations(length-1,max)
  result = []
  for p in base
    for i in [1..max]
      l = _.clone(p)
      l.push(i-1)
      result.push(l)
  return result
  
# These exports are for testing only
exports.RequirementChecker = RequirementChecker  
exports.Pathfinder = Pathfinder
exports.LineChecker = LineChecker