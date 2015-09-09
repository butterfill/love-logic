# Module for creating requirements on lines of a proof expressed like this:
#     rule.from('not not φ').to('φ') ]
#     'intro' : [ rule.from( rule.subproof('φ','contradiction') ).to('not φ') ]
#
# Use like rule.from( rule.subproof('φ','contradiction') ).to('not φ').check(line)

nodeutil = require 'util'

_ = require 'lodash'

util = require '../util'
fol = require '../fol'


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
  }
exports.subproof = subproof


# Use `rule.premise()` when the line in question
# must be a premise or assumption.
premise = () ->
  # We start with the empty rule (which checks that no
  # lines are cited for us) and elaborate its check method.
  emptyRule = from()
  baseCheck = emptyRule.check.bind(emptyRule)
  newCheck = (line) ->
    result = baseCheck(line)
    return result if result isnt true
    # The first line of any proof or subproof can be a premise.
    return true if not line.prev
    if line.parent.parent?
      # Line is in a subproof and not the first line of it.
      return { getMessage : () -> "only the first line of a subproof may be a premise." }
    
    # From this point on, we are in the main proof (not in a subproof).
    
    # Is there a non-premise or subproof above line?
    isNeitherAPremiseNorASubproof = (lineOrSubproof) ->
      if lineOrSubproof.type is 'block'
        thisIsASubproof = lineOrSubproof.parent?
        return true if thisIsASubproof
        return false if not thisIsASubproof
      if lineOrSubproof.type is 'line'
        thisIsAPremise = lineOrSubproof.justification?.rule.connective is 'premise'
        return false if thisIsAPremise 
        return true if not thisIsAPremise
      # We don't care about dividers, blank lines and whatever else.
      return false
    thereIsANonPremiseAbove = line.find( isNeitherAPremiseNorASubproof )
    if thereIsANonPremiseAbove
      return { getMessage : () -> "premises may not occur after non-premises." }
    return true
  emptyRule.check = newCheck
  return emptyRule
exports.premise = premise      


_notImplementedYet = (line) ->
  throw new Error "the rule `#{line.justification.rule.connective}` (or some part of it) is not implemented yet!"
exports._notImplementedYet = _notImplementedYet


_parseIfNecessaryAndDecorate = (requirement) ->
  return requirement if not requirement   # Using `.to` creates undefined requirements.
  if _.isString requirement
    requirement = fol.parse requirement
  fol._decorate requirement
  return requirement


# ------------------
# The following provide a way of checking whether a line citing
# a rule is correct.  (You should only need to use these via `rule.from`.)
# ------------------


# Objects of this class (a) check whether the right number of lines and subproofs 
# have been cited; and (b) transform the requirements into `RequirementChecker`
# objects to pass on to a `Pathfinder`.
class LineChecker
  constructor : (@line, @requirements) ->
    @citedLines = @line.getCitedLines()
    @citedBlocks = @line.getCitedBlocks()

    # The @message will provide an explanation of any mistakes for
    # the person writing a proof.
    @message = ''

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
    # (Note that the `Pathfinder` need to change the order.)
    reqCheckList.reverse()
    
    path = new Pathfinder( reqCheckList, @ )
    pathFound = path.find()
    console.log "pathFound = #{pathFound}"
    if pathFound
      return true
    else 
      console.log "LineChecker instance, checked toRequirement, @getMessage() = #{@getMessage()}"
      return @
  
  addMessage : (text) ->
    @message = "#{@message} #{text}"
  getMessage : () ->
    return "You cannot do this because #{@message.trim()}"

  # An 'although' message is one that describes something correct about the
  # use of the rule. (e.g. 'although your conclusion has the right form ...')
  addAlthoughMessage : (text) ->
    if @_addedAlthough?
      @addMessage "and although #{text}"
    else
      @addMessage "although #{text}"
      @_addedAlthough = true

  citedTypesAreCorrect : () ->
    expected = @whatToCite()
    actual = 
      lines : @citedLines.length
      subproofs : @citedBlocks.length
    if expected.lines is actual.lines and expected.subproofs is actual.subproofs
      return true
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
    @addMessage "you must cite #{expectedLinesTxt} #{expectedAndText}#{expectedBlocksTxt} when using the rule #{@ruleName} (you cited #{actualLinesTxt} #{actualAndText}#{actualBlocksTxt}).".replace /\s\s+/g, ' ' 
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
    constructor : (@req, @candidateLinesOrSubproofs, @matches={}) ->
      # This clones `@matches`, ensuring it will not be mutated.
      @saveMatches(@matches)
      
      # Store names of metavariables (such as α and ψ)  in the 
      # requirement to be checked.
      @metaVariableNames = {}
      if @req.type? and @req.type is 'subproof'
        @metaVariableNames =  @req.startReq.listMetaVariableNames()
        @metaVariableNames = _.defaults( @metaVariableNames, @req.endReq.listMetaVariableNames() )
      else
        @metaVariableNames = @req.listMetaVariableNames()
    
    clone : () ->
      return new RequirementChecker(@req, @candidateLinesOrSubproofs, @matches)
    
    setMatches : (@matches) ->
      @saveMatches(@matches)
    
    # So that we can attempt matching different lines,
    # we have a store of matches.
    # TODO: this is a bit fragile (setting `@matches` directly would cause
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
   
    # Check whether this requirement can be checked yet.
    # (Testing it may depend on what is in @matches).
    canCheckAlready : () ->
      # console.log "canCheckAlready for #{@req.toString()} ..."
      mustBeInMatches = @metaVariableNames.inSub.left
      mustBeInMatches = _.defaults mustBeInMatches, @metaVariableNames.inBox
      for varName in mustBeInMatches
        if not (varName of @matches)
          # console.log "... fail"
          return false 
        whatItMatches = @matches[varName]
        # Tricky case: `whatItMatches` may itself be a meta variable.
        # TODO: for now I'm ignoring this (it doesn't arise in current rules.)
      # console.log "... pass"
      return true
    
    check : () ->
      results = false
      for candidate in @candidateLinesOrSubproofs
        theResult = @_checkOne candidate
        if theResult isnt false
          results = results or {}
          results[candidate.number] = theResult 
      return results
    
    # In this method, the idea is to call methods that rely on, and 
    # update, `@matches`.
    _checkOne : (candidate) ->
      if @req.type? and @req.type is 'subproof'
        @saveMatches()
        @_checkOneLine @req.startReq, candidate.getFirstLine()
        if @matches isnt false
          @_checkOneLine @req.endReq, candidate.getLastLine()
        resultMatches = @matches
        @restoreMatches()
        return resultMatches
      else
        # @req just concerns a line, not a subproof.
        @saveMatches()
        @_checkOneLine @req, candidate
        resultMatches = @matches
        @restoreMatches()
        return resultMatches
    
    _checkOneLine : (aReq, aLine) ->
      fol._decorate(aReq)
      e = aReq.clone().applyMatches(@matches).applySubstitutions()
      
      # Special case: there was a subsutition like `[a->null]` which
      # results in `e` being null.  This indicates a requirement has 
      # not been met.
      if e is null
        @matches = false 
        return undefined
      
      eSubs = e.substitutions
      delete e.substitutions
      @matches = aLine.sentence.findMatches e, @matches
      console.log "_checkOneLine sentence = #{aLine.sentence.toString()}"
      console.log "_checkOneLine aReq = #{aReq.toString()}"
      console.log "_checkOneLine @matches (found) = #{util.matchesToString @matches}"
      
      if @matches isnt false
        if e.box? or e.type is 'box'
          aBox = (e if e.type is 'box') or (e.box if e.box?)
          aBox = aBox.applyMatches(@matches).applySubstitutions()
          # The name in the box must not occur on a line earlier in the proof
          # (although it may appear in earlier subproofs).
          if eSubs and  eSubs isnt null
            aBox.substitutions = eSubs
          theName = aBox.term.name
          iSALineContainingTheName = (lineOrBlock) ->
            return false if lineOrBlock.type isnt 'line'
            return true if (theName in lineOrBlock.sentence.getNames())
            return false
          youCantBoxThisName = aLine.find iSALineContainingTheName
          @matches = false if youCantBoxThisName
      
      return undefined

      
# Some requirements can be met in multiple ways (by matching multiple lines).
# The `Pathfinder` explores different paths through which requirements 
# could be met.  
class Pathfinder
  constructor : ( @reqCheckList, @lineChecker, @matches = {} ) ->
  
  find : () ->
    # If there are no more requirements to meet, we have found a 
    # path along which all requirements can be met.
    if @reqCheckList.length is 0
      return true
    
    reqChecker = @reqCheckList.pop()
    reqChecker.setMatches(@matches)
    
    # Find the first item in `reqCheckList` that we can already check;
    # or, if we can't already check any, just start with the first and hope for the best.
    numChecked = 0
    while ( not reqChecker.canCheckAlready() ) and (numChecked < @reqCheckList.length)
      reqChecker.restoreMatches(@matches)
      @reqCheckList.unshift(reqChecker)
      reqChecker = @reqCheckList.pop()
      reqChecker.setMatches(@matches)
      numChecked += 1
    
    results = reqChecker.check()
    reqChecker.restoreMatches(@matches)
    if results is false
      console.log "pathfinder says no (@reqCheckList.length = #{@reqCheckList.length})"
      @writeMessage(reqChecker)
      return false
    
    # From here on, the `reqChecker` found one or more lines where the 
    # requirement was met.

    for lineNumber, aMatches of results
      clonedReqCheckList = ( reqCheck.clone() for reqCheck in @reqCheckList )
      newPath = new Pathfinder( clonedReqCheckList, @lineChecker, aMatches )
      if newPath.find()
        return true
    
    # So none of the `newPath`s provided a route to meeting all the `reqCheckList`
    # requirements.
    return false
  
  # This method is called if it has been established that there is no 
  # path along which all requirements can be met.
  # Param `reqChecker` is the last in `reqCheckList` for which there is no path.
  writeMessage : (reqChecker) ->
    @lineChecker.addMessage("to apply this rule you need to cite a line with the form ‘#{reqChecker.req.toString()}’ (‘#{reqChecker.req.clone().applyMatches(@matches)}’ in this case).")




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