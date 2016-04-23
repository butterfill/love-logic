# This module provides the main point of entry.
# Use it like:
# ```
#     proof = '''
#       1. A      // premise
#       2. A and B
#     '''
#     result = proof.parse(proof)
#     if _.isString(result)
#       # There was an error parsing the proof (e.g. duplicate line numbers)
#     else
#       theProof = result
#       if theProof.verify()
#         # Everything checked out with your proof
#       else
#         errorList = theProof.listErrorMessages()
#       # You can also verify individual lines:
#       # Note: here the number 1 refers to the line of the text,
#       # not the label the proof writer might have assigned to the line.
#       aLine = theProof.getLine(1)   
#       isLineOk = aLine.verify()
#       if not isLineOk
#         errors = aLine.getErrorMessage()
# ```
_ = require 'lodash'

blockParser = require './block_parser'
addLineNumbers = require './add_line_numbers'
addJustification = require './add_justification'
addSentences = require './add_sentences'
addStatus = require './add_status'
addVerification = require './add_verification'
dialectManager = require('../dialect_manager/dialectManager')


# Thankyou http://stackoverflow.com/questions/10073699/pad-a-number-with-leading-zeros-in-javascript
padRight = (n, len) ->
  n = "#{n}" unless _.isString(n)
  return n if n.length >= len
  return n+new Array(len - n.length + 1).join(' ') 

# Add some convenience functions to a proof 
_decorate = (proof) ->
  
  # TODO: modify to cope with  different
  # proof dialects (e.g. copi)
  proof.toString = (o) ->
    o ?= {}
    walker = 
      result : []
      lineNumber : 0
      addLineNumbers : true
      needLineNumbers : false
      lookBackTwo : []
      getAndIncLineNumber : (line) ->
        walker.lineNumber += 1
        if line.number? or walker.addLineNumbers is false
          theNum = parseInt(line.number.replace?('x','') or line.number)
          walker.needLineNumbers = true unless theNum is walker.lineNumber
          walker.addLineNumbers = false 
          return padRight(line.number,3)
        return padRight(walker.lineNumber,3)
        
      visit : (item) ->
        # insert a divider if necessary
        if item.type isnt 'divider'
          if walker.lookBackTwo[0]?.type is 'block' and walker.lookBackTwo[1]?.type is 'line'
            block = walker.lookBackTwo[0]
            if block.parent?
              prevLine = walker.lookBackTwo[1]
              if prevLine.parent is item.parent
                walker.result.push 
                  number:padRight("#{walker.getAndIncLineNumber(prevLine).trim()}y",3)
                  indentation: "#{prevLine.indentation.trim()}---"
                  sentence : ""
                  justification: ""
        walker.lookBackTwo.push(item)
        walker.lookBackTwo.shift() if walker.lookBackTwo.length > 2
          
        if item.type is 'blank_line'
          line = item
          walker.result.push 
            number:"#{walker.getAndIncLineNumber(line)}"
            indentation: "#{line.indentation.trim()}"
            sentence : ""
            justification: ""
        if item.type is 'divider'
          line = item
          walker.result.push 
            number:"#{walker.getAndIncLineNumber(line)}"
            indentation: "#{line.indentation.trim()}---"
            sentence : ""
            justification: ""
        if item.type is 'close_branch'
          line = item
          walker.result.push 
            number:"#{walker.getAndIncLineNumber(line)}"
            indentation: "#{line.indentation.trim()}"
            sentence : "X"
            justification: ""
        if item.type is 'open_branch'
          line = item
          walker.result.push 
            number:"#{walker.getAndIncLineNumber(line)}"
            indentation: "#{line.indentation.trim()}"
            sentence : "O"
            justification: ""
        if item.type is 'line'
          line = item
          if line.getRuleName() is 'premise'
            justification = ''
          else
            if line.justification?
              justification = "#{line.getRuleName()} #{line.justification?.numbers?.join(', ') or ''}"
            else
              # There was an error parsing the justification
              justification = line.justificationText?.trim() or ''
          walker.result.push 
            number:"#{walker.getAndIncLineNumber(line)}"
            indentation: "#{line.indentation}"
            sentence : "#{line.sentence}"
            justification: justification
            ticked : line.justification?.ticked
        return undefined  # Keep walking.
    proof.walk walker
    txt = ""
    maxSentenceLength = _.max( ((x.sentence?.length + x.indentation?.length) for x in walker.result)  )
    symbols = dialectManager.getSymbols()
    tickSymbol = symbols.tick or '✓'
    tickSymbol = "#{tickSymbol} "
    for line in walker.result
      tick = (tickSymbol if line.ticked) or ''
      indentationSentence = padRight("#{line.indentation} #{line.sentence}",maxSentenceLength+1)
      if walker.needLineNumbers or o.numberLines is true
        txt += "#{line.number} "
      txt += "#{indentationSentence}   #{tick}#{line.justification}\n"
    return txt.trim()
    

parse = (proofText) ->
  try
    block = blockParser.parse proofText
    addLineNumbers.to block
    addJustification.to block
    addSentences.to block
    addStatus.to block
    addVerification.to block
  catch e
    return e.message
  
  proof = block
  
  # Only call this after verifying the proof
  proof.listErrorMessages = () ->
    errorMessages = []
    walker = 
      visit : (item) ->
        return undefined unless item?.type in ['line', 'close_branch', 'open_branch']
        if item.status.verified is false
          lineName = item.number
          errorMsg = item.status.getMessage()
          errorMessages.push "#{lineName}: #{errorMsg}"
    proof.walk walker
    return errorMessages.join('\n')
  
  _decorate(proof)
  return proof
  
exports.parse = parse