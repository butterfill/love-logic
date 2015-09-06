# Module for creating requirements on lines of a proof expressed like this:
#     rule.from('not not φ').to('φ') ]
#     'intro' : [ rule.from( rule.subproof('φ','contradiction') ).to('not φ') ]
#
# Use like rule.from( rule.subproof('φ','contradiction') ).to('not φ').check(line)

nodeutil = require 'util'

_ = require 'lodash'

util = require '../util'
fol = require '../parser/awFOL'

class _From
  constructor: (requirement) ->
    requirement = parseIfNecessary requirement
    @_requirements = {
      from : ([requirement] if requirement) or []
      to : undefined
    }

  type : 'rule'

  and : (requirement) ->
    requirement = parseIfNecessary requirement
    @_requirements.from.push requirement
    return @ 

  to : (requirement) ->
    if @_requirements.to
      throw new Error "You cannot specify .to more than once."
    requirement = parseIfNecessary requirement
    @_requirements.to = requirement
    return @

  check : (line) ->
    return new LineChecker(line, @_requirements).check()
    
from = (requirement) ->
  return new _From(requirement)
exports.from = from


# Allow user to create a rule without any .from clause.
to = (requirement) ->
  return from().to(requirement)
exports.to = to


subproof = (startReq, endReq) ->
  startReq = parseIfNecessary startReq
  endReq = parseIfNecessary endReq
  return { 
    type : 'subproof'
    startReq
    endReq
  }
exports.subproof = subproof


parseIfNecessary = (requirement) ->
  if _.isString requirement
    return fol.parse requirement
  return requirement



class LineChecker
  constructor : (@line, @requirements) ->
    @citedLines = @line.getCitedLines()
    @citedLinesUsed = []
    @citedBlocks = @line.getCitedBlocks()
    @citedBlocksUsed = []

    # The @message will provide an explanation of any mistakes for
    # the person writing a proof.
    @message = ''

    @ruleName = @line.getRuleName()
    
    # This property is used to keep track of `substitute.findMacthes` that
    # will constrain test of the requirements.
    @matches = null
    
  check : () ->
    return @ unless @citedTypesAreCorrect()
    #return @ unless @toRequirementIsMet()
    if not @toRequirementIsMet()
      console.log "LineChecker instance, checked toRequirement, @getMessage() = #{@getMessage()}"
      return @
    # return @ unless @fromRequirementsAreMet()
    if not @fromRequirementsAreMet()
      console.log "LineChecker instance, checked fromRequirements, @getMessage() = #{@getMessage()}"
      return @
    return true
  
  addMessage : (text) ->
    @message = "#{@message} #{text}"

  # An 'although' message is one that describes something correct about the
  # use of the rule. (e.g. 'although your conclusion has the right form ...')
  addAlthoughMessage : (text) ->
    if @_addedAlthough?
      @addMessage "and although #{text}"
    else
      @addMessage "although #{text}"
      @_addedAlthough = true
      
  getMessage : () ->
    return "You cannot do this because #{@message.trim()}"

  citedTypesAreCorrect : () ->
    expected = @whatToCite()
    actual = 
      lines : @citedLines.length
      subproofs : @citedBlocks.length
    if expected.lines is actual.lines and expected.subproofs is actual.subproofs
      return true
    expectedLinesTxt = numberToWords expected.lines, 'line'
    expectedBlocksTxt = numberToWords expected.subproofs, 'subproof'
    expectedAndText = ("and " if expectedLinesTxt and expectedBlocksTxt) or ""
    expectedAndText = ("nothing" if not expectedLinesTxt and not expectedBlocksTxt) or expectedAndText
    actualLinesTxt = numberToWords actual.lines, 'line'
    actualBlocksTxt = numberToWords actual.subproofs, 'subproof'
    actualAndText = ("and " if actualLinesTxt and actualBlocksTxt) or ""
    actualAndText = ("nothing" if not actualLinesTxt and not actualBlocksTxt) or actualAndText
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
  
  fromRequirementsAreMet : () ->
    for req in @requirements.from
      return false if @checkRequirement(req) is false
    # All requirements met
    return true 
  
  # Check whether the specified requirement is met by the line.
  checkRequirement : (req) ->
    # We're going to handle requirements on subproofs and lines separately.
    # Subproofs first.
    if req.type? and req.type is 'subproof'
      for block in @citedBlocks when not (block in @citedBlocksUsed)
        if @subproofMeetsRequirement block, req
          # TODO: temporarily disabled because it prevents proofs
          # being able to cite the same line twice.
          # @citedBlocksUsed.push block
          return true 
      console.log "\n\n req.endReq = #{JSON.stringify req.endReq,null,4}"
      console.log "\n\n @matches.apply(req.endReq) = #{JSON.stringify @matches.apply(req.endReq),null,4}"
      expressionsAsMatched = "#{util.expressionToString @matches.apply(req.startReq)} ... #{util.expressionToString @matches.apply(req.endReq)}"
      @addMessage "you must cite a subproof whose premise is of the form #{util.expressionToString(req.startReq)}  and whose conclusion is of the form #{util.expressionToString(req.endReq)} (which would be #{expressionsAsMatched} in this case) when using the rule #{@ruleName}."
      return false 
    
    # `req` is a requirement on a line
    for aLine in @citedLines when not (aLine in @citedLinesUsed)
      if @lineMeetsRequirement aLine, req
        # TODO: temporarily disabled because it prevents proofs
        # being able to cite the same line twice.
        # @citedLinesUsed.push aLine
        return true
    # We have found an error.  Try to explain what went wrong.
    expressionAsMatched = @matches.apply(req)
    @addMessage "you must cite a line with the form #{util.expressionToString req} (#{util.expressionToString expressionAsMatched} in this case) when using the rule #{@ruleName}."
    return false
  
  subproofMeetsRequirement : (block, req) ->
    firstLine = block.getFirstLine()
    return false if firstLine.type isnt 'line'
    lastLine = block.getLastLine()
    return false if lastLine.type isnt 'line'
    # We don't yet know whether we will want to update @matches with 
    # these matches (it depends on the last line of the subproof matching too).
    tempMatches = _.cloneDeep @matches
    firstLineMatches = firstLine.sentence.matches req.startReq, tempMatches
    return false if firstLineMatches is false
    
    # Here we want to impose the `firstLineMatches` on subsequent matches.
    # But we don't want to add these to `@matches` yet in case this
    # subproof fails and we have to try another one.
    tempMatches.addMatches firstLineMatches
    lastLineMatches = lastLine.sentence.matches req.endReq, tempMatches
    if lastLineMatches is false
      return false 
    else
      @addMatches firstLineMatches
      @addMatches lastLineMatches
      expressionsAsMatched = "#{util.expressionToString @matches.apply(req.startReq)} ... #{util.expressionToString @matches.apply(req.endReq)}"
      @addAlthoughMessage "although you correctly cited a subproof with the form '#{util.expressionToString req.startReq} ... #{util.expressionToString req.endReq}' (#{expressionsAsMatched} in this case),"
      return true

  
  # Check whether line meets the specified requirement, `req`.
  # `req` is a pattern suitable for use with `substitute.findMatch`.
  lineMeetsRequirement : (aLine, req) ->
    # console.log "Checking #{util.expressionToString(aLine.sentence)} against #{util.expressionToString(req)} with matches #{nodeutil.inspect(@matches)}"
    newMatches = aLine.sentence.matches req, @matches
    if newMatches isnt false
      @addMatches newMatches
      
      # We didn't find an error yet, but add a message that will help to 
      # explain any subsequent error.
      expressionAsMatched = @matches.apply(req)
      @addAlthoughMessage "you correctly cited a line with the form '#{util.expressionToString req}' (namely #{util.expressionToString expressionAsMatched}),"
      
      return true
    return false
  
  # Update `@matches` if it exists, otherwise set it to `newMatches`
  addMatches : (newMatches) ->
    @matches?.addMatches newMatches
    @matches ?= newMatches
  
  toRequirementIsMet : () ->
    # If no requirement is specified, the test passes.
    return true if not @requirements.to
    newMatches = @line.sentence.matches(@requirements.to, @matches)
    if newMatches isnt false
      @addMatches newMatches
      # In case there is an error later, adding this clause to the message 
      # explaining the error will make the explanation clearer later.
      @addAlthoughMessage "although your conclusion has the correct form ('#{util.expressionToString @requirements.to}'),"
      return true 
    @addMessage "your sentence must have the form #{util.expressionToString @requirements.to} when using the rule #{@ruleName}."
    return false
    
numberToWords = (num, type) ->
  return '' if num is 0
  return "1 #{type}" if num is 1
  return "#{num} #{type}s" if num > 1


