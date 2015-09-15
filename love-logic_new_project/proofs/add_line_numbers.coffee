# Take a `block_parser.Block` and add line numbers to each line.
# Line numbers are optional: if none are used, missing line numbers will be filled in.
# But if some lines are numbered, no numbers will be added.
# Line number ranges are added to blocks.
# 
# It ignores everything other than `item.type in ['block','line'], so
# introducing comments and dividers later will be fine.

_ = require 'lodash'

# Identifies a number:
#   ^           --- match from the start of input
#   ([|\s])*    --- there may be |s and whitespace
#   \(?         --- there may be a bracket
#   ([0-9]\S*)  --- a number is a digit followed by non-spaces
#   ([|\s]*)    --- match and group any |s and whitespace after the number
#   ([\s\S]*)   --- match and group everything after the number  
_GET_NUMBER = /^([|\s])*\(?([0-9]\S*)([|\s]*)([\s\S]*)/

_DROP_TRAILING_DOTS_AND_BRACKET = /\.*\)?$/

cleanNumber = (lineNumber) ->
  return lineNumber.replace _DROP_TRAILING_DOTS_AND_BRACKET, ''
exports.cleanNumber = cleanNumber

split = (line) ->
  m = line.content.match _GET_NUMBER
  if m
    lineNumber = m[2]
    lineNumber = cleanNumber lineNumber
    return { lineNumber, rest:m[4] } 
  return { lineNumber:null, rest: line.content }
  

to = (block) -> 
  # Do this in two passes.
  # First pass: add numbers to lines.
  walker = { 
    usedLineNumbers : []
    lineCounter : 0
    userNumberedLines : false
    
    visit : (item) ->
      # Blocks will be numbered later.
      return undefined if item.type is 'block'
      line = item
      @lineCounter += 1
      {lineNumber, rest} = split line
      @userNumberedLines = true if lineNumber or lineNumber is 0
      if lineNumber is null 
        if item.type is 'line' 
          lineNumber = "#{@lineCounter}"
        else
          # Protect the user from duplicates in case they are only numbering lines 
          # that contain sentences
          lineNumber = "#{@lineCounter}x"
      if lineNumber in @usedLineNumbers
        throw new Error "Duplicate line number '#{lineNumber}' used for the second time at line #{@lineCounter}.  Line numbers must be unique."
      @usedLineNumbers.push lineNumber
      line.number = lineNumber
      line.content = rest
      return undefined # keep walking
  }
  block.walk walker

  # Second pass: add number ranges to blocks.
  anotherWalker = { 
    visit : (item) ->
      return undefined if item.type isnt 'block'
      block = item
      
      # We can't label a block with no lines in it.
      return undefined if block.content.length is 0
      
      firstLine = block.content[0]
      lastLine = _.last block.content
      
      # A block that isn't yet closed finishes with a block.
      # We will count to the end of that block
      while lastLine.type is 'block'
        subBlock = lastLine
        lastLine = _.last subBlock.content
      
      # We won't label a block if for some reason its first or last line 
      # didn't get a number.
      return undefined if not (firstLine.number? and lastLine.number?)
      
      lineNumber = "#{firstLine.number}-#{lastLine.number}"
      block.number = lineNumber
      return undefined # keep walking
  }
  block.walk anotherWalker
  
  return block


exports.to = to