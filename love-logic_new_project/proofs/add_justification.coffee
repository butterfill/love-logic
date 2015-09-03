# Takes a `block_parser.Block` with unprocessed strings of a yaFOL proof
# as its lines, extracts and parses the justification (using `justification_parser`),
# and adds the justification objects to the lines of the `Block`.
#
# Currently we take justification to start with '//', '\\' or '--'.
# So a line should look like `<yaFOL expression> // <justification>`
#
# After `addJustification`, a `Block.line` should have:
#     `.justification`        -- the object produced by `justification_parser`
#     `.justificationErrors`  -- a string, or null.
#     `.justificationText`    -- the text that was parsed (might be useful if errors occur).
#
#

jp = require './justification_parser'


# This will be useful later in case we have to add it to any lines
# above a divider where no justification is given explicitly. 
PREMISE_JUSTIFICATION = jp.parse "premise"

# This is the main function.
# Add justification to the lines of `block`.
to = (block) ->
  
  # First pass: extract the justification and add it to the lines.
  # Also add some functions to help later.
  walker = 
    visit : (item) ->
      return undefined if item.type isnt 'line'
      return undefined if item.justification? or item.justificationErrors?
      line = item
      r = split line.content
      line.justification = r.justification
      line.content = r.rest
      line.justificationErrors = r.justificationErrors
      line.justificationText = r.justificationText
      line.getRuleName = getRuleName
      line.getReferencedLine = getReferencedLine
      line.getReferencedBlock = getReferencedBlock
      return undefined  # Keep walking.
  block.walk walker

  # Second pass: fill in premise justifications for any premises.
  walker = 
    visit : (item) ->
      return undefined if item.type isnt 'line'
      return undefined if item.justification? or item.justificationErrors?
      line = item
      if isPremise line
        line.justification = PREMISE_JUSTIFICATION
      return undefined  # Keep walking.
  block.walk walker

  return block
  
exports.to = to







# Split the `text` (content of a line) into justification and non-
# justification parts, returning the parsed justification.
_FIND_JUSTIFICATION = /(\/\/)|(\\)|(--)/
split = (text) ->
  m = text.match _FIND_JUSTIFICATION
  if not m
    # No justification found
    return { justification: null, rest: text, justificationErrors:null }
  rest = text.slice(0, m.index)
  justificationText = text.slice(m.index+2)
  try 
    justification = jp.parse justificationText
  catch e 
    # console.log "caught error #{e.message}"
    # console.log "justificationText #{justificationText}"
    return { justification: null, rest, justificationErrors:e.message, justificationText }
  return { justification, rest, justificationErrors:null }


# Return true if line is a premise.
isPremise = (line) ->
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


# ---
# Some functions that are added to lines for convenience later.
# Note that these will be called in the context of a line, so 
# `@` refers to the line.

getRuleName = ->
  connective = @justification.rule.connective
  # `intronation` is 'elim' or 'intro'
  intronation = @justification.rule.variant.intronation or ''
  # `side` is 'left' or 'right'
  side = @justification.rule.variant.side or ''
  return "#{connective} #{intronation} #{side}".trim()

# This should only be used if this line references a single line.
getReferencedLine = ->
  targetNumber = @justification.numbers[0]
  return @find( (item) ->
    return undefined if item.type isnt 'line'
    return true if item.number is targetNumber
    return undefined
  )

# This should only be used if this line references a single block.
getReferencedBlock = ->
  targetNumber = @justification.numbers[0]
  return @find( (item) ->
    return undefined if item.type isnt 'block'
    return true if item.number is targetNumber
    return undefined
  )

