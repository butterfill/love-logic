# Takes a `block_parser.Block` with and adds methods by which
# lines and blocks can record and store their status (e.g.
# errors concering parsing a sentence or justification, or 
# errors in verifying a rule of proof).
#
# As it stands, it is designed to be used AFTER `add_sentences` and
# `add_justification`.
#

_ = require 'lodash'

fol = require '../fol'
substitute = require '../substitute'
util = require '../util'


# Add a `.status` property to lines, which is a `LineStatus` object.
to = (block) ->
  
  walker = 
    visit : (item) ->
      return undefined unless item?.type?
      if item.type isnt 'block'
        item.status = new LineStatus(item)
        # This might seem a bit pointless, but the idea is that
        # only modules concerned with checking the proof need to
        # access `line.status`; the UI just needs to know abotu
        # `aLine.getErrorMessage()`.
        item.getErrorMessage = () ->
          return item.status.getMessage()
          
      
      return undefined  # Keep walking.
  block.walk walker

  return block
  
exports.to = to


class LineStatus
  constructor : (@line) ->
    @messages = []
    @verified = false 
    @verificationAttempted = false
    @sentenceParsed = @line.sentence?
    @justificationParsed = @line.justification?
    if @line.sentenceErrors?
      languageNames = util.getLanguageNames()
      @addMessage "the sentence you wrote (‘#{@line.sentenceText.trim()}’) is not a sentence or well-formed formula of #{languageNames.join(' or ')}."
    if @line.justificationErrors?
      # console.log @line.justificationErrors
      @addMessage "the justification you supplied (#{@line.justificationText?.trim()}) either mentions a rule you can't use here or doesn't make sense."
    if @line.type is 'line' and not @line.justification? and not @line.justificationErrors?
      @addMessage "you supplied no justification for this line."
      
  
  addMessage : (text) -> 
    # console.log "adding #{text}"
    # console.log @line
    @messages.push text
  addMessageIfNoneAlready : (text) -> 
    if @messages.length is 0
      @messages.push text
  clearMessages : () ->
    @messages = []
  popMessage : () ->
    if @messages.length > 0
      return @messages.pop()
    return ''
  # An 'although' message is one that describes something correct about the
  # use of the rule. (e.g. 'although your conclusion has the right form ...')
  addAlthoughMessage : (text) ->
    if @_addedAlthough?
      @addMessage "and although #{text}"
    else
      @addMessage "although #{text}"
      @_addedAlthough = true
  getMessage : () ->
    return "" if @messages.length is 0
    # @messages = _.uniq(@messages)
    isCorrectText = ("not correct because" unless @verified) or ("correct but")
    msg = "This line is #{isCorrectText} #{@messages[0]}"
    if @messages.length > 1
      msg += " And also #{@messages[1]}"
    if @messages.length > 2
      msg += " Further, #{@messages[2]}"
    if @messages.length > 3
      msg += " And, for another thing, #{@messages[3]}"
    if @messages.length > 4
      ((msg += " And #{x}") for x in @messages.splice(4))
    return msg
  