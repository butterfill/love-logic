# Parse a string into blocks, treating spaces and | as significant.
# Use: call `parse` on a string to get a `Block`.
# `Block` provides functions for walking and finding things.
#
# Example input (ignore the numbers):
# ```
# block       17
#   line      16
#   line      15
#   block     3
#     line    14
#     line    13
#     line    12
#     block   9
#       line  11
#       line  10
#     block   6
#       line  8
#       line  7
#     line    5
#     line    4
#   line      2
#   line      1
# ```
#
# To have two blocks at the same level in sequence, leave a blank line:
# ```
#     line 1
#       line 2.1
#       line 2.2
#
#       line 3.1
#       line 3.2
#     line 4
# ```
#
# Any line starting with -- or __ (after any amount of indentation) is considered to be 
# at the same indentation level as the previous line.  (This is specified by `isDivider`.)
#
# This is work towards a proof parser.  
# The idea is to start by getting the proof into a `Block`, then gradually enriching it
# by adding line numbers, parsing the expressions, and parsing the justification.
#
# This module ignores numbers because we're going to use numbers on the inside, like this:
# 
# | 1. exists x F(x)    // premise
# | 1b. all x not F(x)  // premise
# | ---
# | | 2. consider a. suppose F(a), then ...
# | | --- 
# | | 3. not F(a)       // from 1b. using universal-elim
# | | 4. contradiction  // applying contradiction-intro to 2, 3
# | 5. contradiction      //  universal-elim applied to 1, 2-4
#
# Tricky cases ...
# line 4 should be the first line in the second subblock of a's block,
# and line 3 should be a line in a's block:
#   1. a
#   2.    b
#   3. <blank line>
#   4.    c
# line 5 should be the first line in the second subblock of a's block,
# and line 3 and 4 should lines in a's block::
#   1. a
#   2.    b
#   3. <blank line>
#   4. <blank line>
#   5.    c
# line 4 should be the first line in the first subblock of b's block,
# and line 3 should be the last line of b's block:
#   1. a
#   2.    b
#   3. <blank line>
#   4.        c
# line 4 should cause an 'invalid indentation' error:
#   1. a
#   2.     b
#   3. <blank line>
#   4.   c

  


_ = require 'lodash'

util = require '../util'

  




parse = (lines) ->
  if _.isString lines
    lines = lines.split('\n')
    
  if lines.length is 0
    return new Block("")

  clean lines
  
  lines = extractIndentationAndContentFrom lines
  
  firstLine = lines[0]
  topBlock = new Block(firstLine.indentation)
  block = topBlock
  
  while lines.length > 0
    line = lines.shift()
    
    # Do we need to start a new block, or to close one?
    
    # Case 1 : ordinary line (not a divider or blank line).
    if line.type is 'line'
      # Increasing the indentation means starting a new block.
      if line.indentation.length > block.indentation.length
        block = block.newBlock(line.indentation)
      # Decreasing the indentation means closing one or more blocks.
      while block and line.indentation.length < block.indentation.length 
        block = block.close()
      if not block or line.indentation.length isnt block.indentation.length
        throw new Error "Bad indentation at line #{line.idx} (#{line.originalText}). (It is indented to a level to which no earlier line is indented.)"
      block.newLine(line)
      continue
      
    # Case 2 : divider
    if line.type is 'divider'
      block.newLine(line)
      continue
      
    # Case 3 : blank line.  
    if line.type is 'blank_line' 
      # In case there is a sequence of blank lines, we want to get all of them.
      blankLines = [line]
      while lines.length > 0 and lines[0].type is 'blank_line'
        blankLines.push( lines.shift() )
      
      # What to do with the blank lines?
      if block is topBlock
        # Just add the blank lines to the top block and move on (they don't mean anything).
        ( block.newLine(l) for l in blankLines ) 
        continue

      # We are in a subblock.  What to do depends on the indentation of the 
      # next (non-blank) line and of current block.
      nextLineIndentation = lines[0].indentation
      
      if nextLineIndentation.length is block.indentation.length
        # Add blank lines to parent of current block.
        previousBlock = block
        parentBlock = block.close()
        ( parentBlock.newLine(l) for l in blankLines ) 
        # Create a sibling of the previous block that has the same indentation as the previous block.
        block = parentBlock.newBlock(previousBlock.indentation)
        continue
      
      if nextLineIndentation.length > block.indentation.length
        # Add blank lines to the current block.
        ( block.newLine(l) for l in blankLines ) 
        # Create a subblock of the current block; in the next loop, future lines will
        # be added to this new subblock.
        block = block.newBlock(nextLineIndentation)
        continue
        
      # We know that nextLineIndentation.length < block.indentation.length.
      # Close blocks until we find a block with indentation matching nextLineIndentation.length.
      # The blank lines will be added to this block.
      while block and nextLineIndentation.length < block.indentation.length
        block = block.close()
      if not block or nextLineIndentation.length isnt block.indentation.length
        throw new Error "Bad indentation at line #{line.idx} (#{line.originalText}). (It is indented to a level to which no earlier line is indented.)"
      ( block.newLine(l) for l in blankLines )
      continue
          
  # The last line we've parsed might be more indented than the first.  
  # We want to return the top-level block.
  while block isnt topBlock
    block = block.close()
  
  return block
exports.parse = parse      


clean = (lines) ->
  # TODO replace \n\r etc
  # TODO replace ' ' with | if there are no | at the start of a line
  # TODO remove spaces at the start of a line.

# This regular expression matches |s and whitespace at the start of a line.
_INDENTATION_AT_START_OF_LINE = /^([|\s]+)/ 


extractIndentationAndContentFrom = (lines) ->
  # How are the lines formatted, number then indentation or
  # indentation then number?
  indentationFirst = areLinesFormattedIndentationFirst lines
  
  result = []
  for line,idx in lines
    {indentation, content} = split line, indentationFirst
    type = 'line'
    if isBlank(content)
      type = 'blank_line'
    if isDivider(content)
      type = 'divider'
    result.push( { indentation, content, idx:idx+1, type, originalText : line })
  
  return result




# Return true for:
# ```
#   1. line
#       2. indented
# ```
# Return false for:
# ```
#   1. line
#   2.    indented
# ```
# Note: If any line has indentation before a number, this returns true.
areLinesFormattedIndentationFirst = (lines) ->
  return true if not lines or lines.length is 0
  indentationAtStartOfFirstLine = (lines[0].match _INDENTATION_AT_START_OF_LINE)?[1]
  for line in lines
    m = line.match _INDENTATION_AT_START_OF_LINE
    indent = m?[1]
    if m isnt null and indent isnt indentationAtStartOfFirstLine
      return true
  return false
# This is only exported for testing.
exports.areLinesFormattedIndentationFirst = areLinesFormattedIndentationFirst


# These regular expressions are used to split a line into indentation and content.
# It is assumed below that this expression always matches.
_SPLIT_LINE_WHEN_INDENTATION_FIRST = /^([|\s]*)([\s\S]*)/ 

# This says:
#   ^               --- match start of line
#   ([|\s]*)        --- capture any indentation at start of line
#   \(?             --- match an optional bracket
#   ([0-9][^|\s]*)? --- match a number (if present: note the final '?'), 
#                       where a number is a digit followed by non-spaces and non-|s
#   ([|\s]*)        --- match any indentation
#   ([\s\S]*)       --- match everything else
# It is assumed below that this expression always matches.
_SPLIT_LINE_WHEN_NUMBER_FIRST = /^([|\s]*)\(?([0-9][^|\s]*)?([|\s]*)([\s\S]*)/

split = (line, indentationFirst) ->
  if indentationFirst
    m = line.match _SPLIT_LINE_WHEN_INDENTATION_FIRST
    # Note that `_SPLIT_LINE_WHEN_INDENTATION_FIRST` always matches, even if line is ""
    return { indentation:m[1], content:m[2] }
  else 
    m = line.match _SPLIT_LINE_WHEN_NUMBER_FIRST
    preLineNumberIndentation = m[1] or ""
    lineNumber = m[2]
    postLineNumberIndentation = m[3] or ""
    everythingElse = m[4] or ""
    # Does the line contain a number?
    if lineNumber 
      return { indentation:postLineNumberIndentation, content:"#{lineNumber} #{everythingElse}" }
    else
      # When there is no number, we need to return the pre-number indentation.
      # (Note: there is no post-number indentation ni this case.)
      return { indentation:preLineNumberIndentation, content:"#{everythingElse}" }
# This is only exported for testing.
exports.split = split


removeNumberFrom = (line) ->
  return line.replace /[0-9]\S*/, ''

removeIndentationFrom = (line) ->
  return line.replace /\|/g, ''
  
isDivider = (line) ->
  # Whether a line contains a number doesn't affect whether it is a divider.
  # So strip out the first number (if any) before doing the tests.
  line = removeNumberFrom line

  # Whether a line contains indentation markers doesn't affect whether it is a divider.
  # So strip out all of these before doing the tests.
  line = removeIndentationFrom line
  
  # A line that starts with -- or __ (after any indentation or whitespace) is a divider.
  m = line.match /^\s*[(--)(__)]/
  return true if m isnt null
  
  # Nothing else is a divider.
  return false
exports._isDivider = isDivider

isBlank = (line) ->
  # We don't count line numbers as content.
  line = removeNumberFrom line

  # Whether a line contains indentation markers doesn't affect whether it is blank.
  # So strip out all of these before doing the tests.
  line = removeIndentationFrom line

  return ( line.trim() is "" )  
exports._isBlank = isBlank


class Block
  # Only call the constructor once, for the root block.
  # Further blocks should be added by calling .newBlock(indentation) on a block
  # (which calls this with some parameters filled in).
  constructor : (@indentation, @parent, @prev) ->
    @type = 'block'
    @content = []
    
    # This is just to help with testing (makes sense of circular references).
    if not @parent?
      @_depth = 1
    else
      @_depth = @parent._depth+1
    
  getLastLine : ->
    return _.last @content if @content.length>0
    return null
    
  newLine : (lineObject) ->
    lineObject.parent = @
    lineObject.prev = @getLastLine()
    lineObject.lineNumberInSource = lineObject.idx

    # Works up the proof from the current line
    # checking every line, block, divider and blank_line visible from here until
    # `matcher` returns true; at this point, the matched line or block is returned.
    # (It will not enter closed blocks.)
    # `matcher` is a function that will be fed a line or block.
    lineObject.find = (matcher) ->
      current = @
      while current?
        console.log "found line : #{current.content}" if matcher(current)
        return current if matcher(current)
        if not current.prev? and current.parent?
          # Move on to the parent if there's no previous item.
          current = current.parent
        else
          # Move on to previous item (even if there isn't one -- this will terminate the loop).
          current = current.prev
      return false

    @content.push(lineObject)
    return lineObject
    
  newBlock : (indentation) ->
    b = new Block(indentation, @, @getLastLine())
    @content.push(b)
    return b
  
  close : () ->
    return @parent
  
  walk : (walker) ->
    result = walker.visit(@)
    return result if result?
    for item in @content
      if item.type is 'line'
        result = walker.visit(item)
      if item.type is 'block'
        result = item.walk(walker)
      # Stop walking as soon as `walker.walk` gives us a result.
      return result if result?
    return undefined
  
  # Returns the 1-based lineNumber-th line in this block.
  # (This is mainly (or only?) used for testing.)
  goto : (lineNumber) ->
    walker = {
      onLine : 0
      visit : (item) ->
        return undefined if item.type isnt 'line'
        @onLine += 1
        return item if @onLine is lineNumber
        return undefined
    }
    result = @walk walker
    if not result?
      throw new Error "Could not get line number #{lineNumber}"
    return result
  
  toString : () ->
    # return util.inspect @
    _replacer = (key, value) ->
      if value and (key is 'prev' or key is 'parent')  # Ignore this value.
        return "[circular reference to #{value?.type}, depth #{value?._depth}]"
      if key is 'sentence'
        return util.expressionToString(value)
      return undefined if _.isFunction value  # Ignore functions.
      return value
    return JSON.stringify @, _replacer, 4
          
# This is only exported for testing.
exports.Block = Block

