# Take a `block_parser.Block` and add line numbers to each line.
# Line numbers are optional.  Any missing line numbers will be filled in.
# Line number ranges are added to blocks.
# 
# It ignores everything other than `item.type in ['block','line'], so
# introducing comments and dividers later will be fine.

_ = require 'lodash'

block_parser = require './block_parser'

_GET_NUMBER = /^\(?([0-9]\S*)([\s\S]*)/
_DROP_TRAILING_DOTS_AND_BRACKET = /\.*\)?$/
split = (line) ->
  m = line.content.match _GET_NUMBER
  if m
    lineNumber = m[1]
    lineNumber = lineNumber.replace _DROP_TRAILING_DOTS_AND_BRACKET, ''
    return { lineNumber, rest:m[2] } 
  return { lineNumber:null, rest: line.content }
  

addNumbers = (block) -> 
  # Do this in two passes.
  # First pass: add numbers to lines.
  walker = { 
    usedLineNumbers : []
    lineCounter : 0
    visit : (item) ->
      return undefined if item.type isnt 'line'
      line = item
      @lineCounter += 1
      {lineNumber, rest} = split line
      if lineNumber is null
        lineNumber = "#{@lineCounter}" 
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
      
      # We won't label a block that isn't yet closed.
      return undefined if firstLine.type isnt 'line' or lastLine.type isnt 'line'
      
      # We won't label a block if for some reason its first or last line 
      # didn't get a number (maybe one of these was a `block_parser.isDivider` line).
      return undefined if not (firstLine.number? and lastLine.number?)
      
      lineNumber = "#{firstLine.number}-#{lastLine.number}"
      block.number = lineNumber
      return undefined # keep walking
  }
  block.walk anotherWalker
  
  return block


exports.addNumbers = addNumbers