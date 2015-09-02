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


_ = require 'lodash'


# This regular expression is used to split a line into indentation and content.
_SPLIT_LINE = /^([|\s]*)([\s\S]*)/ 
split = (line) ->
  m = line.match _SPLIT_LINE
  # Note that `_SPLIT_LINE` always matches, even if line is ""
  return { indentation:m[1], content:m[2] }


# A line that starts with -- or __ (after any indentation) is a divider.
isDivider = (line) ->
  m = line.match /^[(--)(__)]/
  return false if m is null
  return true


class Block
  constructor : (@parent, @prev, @indentation) ->
    @type = 'block'
    @content = []
    
  getLastLine : ->
    return _.last @content if @content.length>0
    return null
    
  newLine : (content) ->
    theLine = {
      type : 'line'
      parent : @
      prev : @getLastLine()
      content : content
      
      # Works up the proof from the current line
      # checking every line and block visible from here until
      # `matcher` returns true; at this point, the matched line or block is returned.
      # (It will not enter closed blocks.)
      # `matcher` is a function that will be fed a line or block.
      find : (matcher) ->
        current = @
        while current?
          return current if matcher(current)
          current = current.prev
        return false
    }
    @content.push(theLine)
    return theLine
    
  newBlock : (indentation) ->
    b = new Block(@, @getLastLine(), indentation)
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
  goto : (lineNumber) ->
    walker = {
      onLine : 0
      visit : (item) ->
        return undefined if item.type isnt 'line'
        @onLine += 1
        return item if @onLine is lineNumber
        return undefined
    }
    return @walk walker
  
  toString : () ->
    # return util.inspect @
    _replacer = (key, value) ->
      if value and (key is 'prev' or key is 'parent')  # Ignore this value.
        return "[circular reference to #{value?.type}]"
      return undefined if _.isFunction value  # Ignore functions.
      return value
    return JSON.stringify @, _replacer, 4
          
# This is only exported for testing.
exports.Block = Block


clean = (lines) ->
  # TODO replace \n\r etc
  # TODO replace ' ' with | if there are no | at the start of a line
  # TODO remove spaces at the start of a line.


parse = (lines) ->
  clean lines
  topBlock = new Block()
  block = topBlock
  for line, idx in lines.split('\n')
    {indentation, content} = split line
    
    # This only occurs on the first run through the loop.
    if not block.indentation?
      block.indentation = indentation
    
    # Do we need to start a new block, or to close one?
    
    # Where a divider occurs, we ignore the indentation.
    if not (isDivider line) 
      if indentation.length > block.indentation.length
        block = block.newBlock(indentation)
      while indentation.length < block.indentation.length and block
        block = block.close()
      if indentation.length isnt block.indentation.length
        throw new Error "Bad indentation at line #{idx+1}. (It is indented to a level to which no earlier line is indented.)"
      prevIndentation = indentation
    
    newLineOfBlock = block.newLine(content)
    if (isDivider line) 
      newLineOfBlock.type = 'divider'
  
  # The last line we've parsed might be more indented than the first.  
  # We want to return the top-level block.
  while block isnt topBlock
    block = block.close()
  
  return block
exports.parse = parse      




