# Takes a `block_parser.Block` with unprocessed strings of a awFOL proof
# as its lines, extracts and parses the justification (using `justification_parser`),
# and adds the justification objects to the lines of the `Block`.
#
# Currently we take justification to start with '//', '\\' or '--' or '   ' (3 spaces).
# So a line should look like `<awFOL expression> // <justification>`
#
# After `addJustification`, a `Block.line` should have:
#     `.justification`        -- the object produced by `justification_parser`
#     `.justificationErrors`  -- a string, or null.
#     `.justificationText`    -- the text that was parsed (might be useful if errors occur).
#
#

_ = require 'lodash'

jp = require './justification_parser'
dialectManager = require('../dialect_manager/dialectManager')

# We are going to apply the same `cleanNumber` function to line number references
# that is used in parsing the line numbers at the start of lines of the proof.
cleanNumber = require('./add_line_numbers').cleanNumber

# This will be useful later in case we have to add it to any lines
# above a divider where no justification is given explicitly. 
PREMISE_JUSTIFICATION = jp.parse "premise"
CLOSE_BRANCH_JUSTIFICATION = jp.parse "close branch"
OPEN_BRANCH_JUSTIFICATION = jp.parse "open branch"

# This is the main function.
# Add justification to the lines of `block`.
to = (block) ->
  
  # First pass: extract the justification and add it to the lines.
  walker =  
    visit : (item) ->
      return undefined unless item.type in ['line', 'close_branch', 'open_branch']
      return undefined if item.justification? or item.justificationErrors?
      
      line = item
      if item.type is 'close_branch'
        line.justification = CLOSE_BRANCH_JUSTIFICATION
      if item.type is 'open_branch'
        line.justification = OPEN_BRANCH_JUSTIFICATION
      if item.type is 'line'
        r = split line.content
        line.justification = r.justification
        line.content = r.rest
        line.justificationErrors = r.justificationErrors
        line.justificationText = r.justificationText
        
      if line.justification?.numbers?
        line.justification.numbers = (cleanNumber(n) for n in line.justification.numbers)
      
      # Add some functions to help later.
      line.getRuleName = getRuleName
      line.findLine = findLine
      line.findBlock = findBlock
      line.findLineOrBlock = findLineOrBlock
      line.getCitedLines = getCitedLines
      line.getLinesThatCiteMe = getLinesThatCiteMe
      line.getCitedBlocks = getCitedBlocks
      line.isPremise = () ->
        return line.justification.rule.connective is PREMISE_JUSTIFICATION.rule.connective
      
      return undefined  # Keep walking.
  block.walk walker

  # Second pass: fill in premise justifications for any premises.
  walker =  
    visit : (item) ->
      return undefined if item.type isnt 'line'
      return undefined if item.justification? or item.justificationErrors?
      line = item
      if _isPremise(line)
        line.justification = PREMISE_JUSTIFICATION
      return undefined  # Keep walking.
  block.walk walker

  # Third pass: add some useful functions to blocks.
  walker =  
    visit : (block) ->
      return undefined if block.type isnt 'block'

      block.getConclusion = () ->
        last = _.last block.content
        if last.type is 'line' and last.sentence?
          return last.sentence
        return false # There is no conclusion
      
      block.getPremises = () ->
        premiseLines = _.filter( block.content, (item) ->
          return false unless item.type is 'line'
          return false unless item.sentence?
          return false unless item.justification?.rule?.connective is 'premise'
          return true
        )
        return (x.sentence for x in premiseLines )

      return undefined  # Keep walking.
      
  block.walk walker


  return block
  
exports.to = to







# Split the `text` (content of a line) into justification and non-
# justification parts, returning the parsed justification.
_FIND_JUSTIFICATION = /((\s)*\/\/)|(\\)|(--)/
_FIND_WHITESPACE_JUSTIFICATION = /(\S+)(\s\s\s)(?=\s*\S+)/
split = (text) ->
  m = text.match _FIND_JUSTIFICATION
  if m?
    rest = text.slice(0, m.index)
    matchLength = m[0].length
    justificationText = text.slice(m.index+matchLength)
  else
    m = text.match _FIND_WHITESPACE_JUSTIFICATION
    if m?
      preTextMatched = m[1]
      rest = text.slice(0, m.index+preTextMatched.length)
      matchLength = m[0].length
      justificationText = text.slice(m.index+matchLength)
    else
      # No justification found
      return { justification: null, rest: text, justificationErrors:null }
  try 
    justification = jp.parse justificationText
  catch e 
    return { justification: null, rest, justificationErrors:e.message, justificationText }
  return { justification, rest, justificationErrors:null }


# Return true if line is a premise.
_isPremise = (line) ->
  parent = line.parent
  # The first line in any block is a premise.
  if line is parent.content[0]
    return true

  # If not in the outer block, only the first line is a premise.
  return false if parent.parent?

  # We are in the outer block.
  # In the outer block, all lines above a divider are premises.
  # (But we don't know whether there is actually a divider, and 
  # we can't assume that there will be only one divider.)
  siblings = parent.content
  lineIsBeforeDivider = false
  thereIsADivider = false
  for aLine in siblings
    if aLine.type is 'divider'
      thereIsADivider = true
      break    # Stop at the first divider.
    if aLine is line
      lineIsBeforeDivider = true
  return true if lineIsBeforeDivider and thereIsADivider
  return false
exports._isPremise = _isPremise

# ---
# Some functions that are added to lines for convenience later.
# Note that these will be called in the context of a line, so 
# `@` refers to the line.

getRuleName = ->
  return "" unless @justification?.rule?
  symbols = dialectManager.getSymbols()
  connective = symbols[@justification.rule.connective] or @justification.rule.connective
  spaceAfterConnective = (' ' if connective?.length isnt 1) or '' 
  # `intronation` is 'elim' or 'intro'
  intronation = @justification.rule.variant.intronation or ''
  intronation = symbols[intronation] or intronation
  # `side` is 'left' or 'right'
  side = @justification.rule.variant.side or ''
  return "#{connective}#{spaceAfterConnective}#{intronation} #{side}".trim()


# TODO: the find functions should be added by `add_line_numbers`

# `targetNumber` specifies the number of a line as (typically) given by the
# user who wrote the proof.
findLine = (targetNumber) ->
  return @findAbove( (item) ->
    return undefined if item.type isnt 'line'
    return true if item.number is targetNumber
    return undefined
  )
  
# `targetNumber` specifies the number of a line as (typically) given by the
# user who wrote the proof.
findBlock = (targetNumber) ->
  return @findAbove( (item) ->
    return undefined if item.type isnt 'block'
    return true if item.number is targetNumber
    return undefined
  )

# `targetNumber` specifies the number of a line as (typically) given by the
# user who wrote the proof.
findLineOrBlock = (targetNumber) ->
  return @findAbove( (item) ->
    return undefined if (item.type isnt 'block' and item.type isnt 'line')
    return true if item.number is targetNumber
    return undefined
  )
  

# This should only be used if this line references a single line.
getCitedLines = ->
  return [] if not @justification?.numbers?
  citedLines = []
  for targetNumber in @justification.numbers
    result = @findLine( targetNumber )
    if result isnt false
      citedLines.push result
  return citedLines

# To help checking tree proofs.
# This only works for lines (not blocks).
# This assumes that a line is only cited in the block in 
# which it lives and in any child blocks (it is not cited from a parent block).
getLinesThatCiteMe = ->
  thisLine = @
  result = []
  walker = {}
  walker.visit = (item) ->
    if item.getCitedLines?
      if thisLine in item.getCitedLines()
        result.push(item)
    # keep walking
    return undefined
  @.parent.walk(walker)
  return result
  

getCitedBlocks = ->
  return [] if not @justification.numbers
  citedBlocks = []
  for targetNumber in @justification.numbers
    result = @findBlock( targetNumber )
    if result isnt false
      citedBlocks.push result
  return citedBlocks

