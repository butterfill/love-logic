# Takes a `block_parser.Block` with and adds methods by which
# lines and blocks can record and store their status (e.g.
# errors concering parsing a sentence or justification, or 
# errors in verifying a rule of proof).
#
# As it stands, it is designed to be used AFTER `add_sentences` and
# `add_justification`.
#

fol = require '../fol'
substitute = require '../substitute'
util = require '../util'


# Add a `.status` property to lines, which is a `LineStatus` object.
to = (block) ->
  
  walker = 
    visit : (item) ->
      if item.type is 'line'
        aLine = item
        aLine.status = new LineStatus(aLine)
        aLine.getErrorMessage = () ->
          return aLine.status.getMessage()

      if item.type is 'block'
        aBlock = item
        aBlock.listErrorMessages = () ->
          # Walk lines collecting messages.
          throw "Not implemented yet!"
      
      return undefined  # Keep walking.
  block.walk walker

  return block
  
exports.to = to


class LineStatus
  constructor : (@line) ->
    @verified = false 
    @verificationAttempted = false
    @sentenceParsed = @line.sentence?
    @justificationParsed = @line.justification?
    if @line.sentenceErrors?
      @addMessage "the sentence you wrote (#{@line.sentenceText}) is not a sentence of awFOL."
    if @line.justificationErrors?
      @addMessage "the justification your supplied (#{@line.justificationText}) either mentions a rule you can't use here or doesn't make sense."
    
    
  messages : []
  
  addMessage : (txt) -> 
    @messages.push txt
  popMessage : () ->
    if @messages.length > 0
      return @messages.pop()
    return ''
  getMessage : () ->
    return "" if messages.length is 0
    msg = "This line is not correct because #{@messages[0]}"
    if messages.length > 1
      msg += "And also #{@messages[1]}"
    if messages.length > 2
      msg += "Further, #{@messages[2]}"
    if messages.length > 3
      msg += "And, for another thing, #{@messages[3]}"
    if messages.length > 4
      ((msg += "And #{x}") for x in @messages.splice(4))
    return msg
  