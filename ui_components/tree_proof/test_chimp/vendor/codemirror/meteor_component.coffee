# This is a collection of templates using CodeMirror editors that will save state
# It depends on `codemirror`
# Modified from https://github.com/perak/codemirror/blob/master/lib/component/component.js

# ====
# Functions used across several variants

# Provide feedback to the user.
giveFeedback = (message) ->
  $('#feedback').text(message)
giveMoreFeedback = (message) ->
  $('#feedback').text("#{$('#feedback').text()}  #{message}")



# =======
# editSentence

# Enchanced for sentences of FOL: includes a feedback line and a `convert to symbols` button.
Template.editSentence.onRendered () ->
  o = @data.options or {}
  options = _.defaults o, {
    theme : 'blackboard'
    smartIndent : true
    tabSize : 2
    lineNumbers : false
    autofocus : true
    matchBrackets : true
  }
  textarea = @find('textarea')
  editor = CodeMirror.fromTextArea(textarea, options)
  
  # TODO: this should go? (Superflous given the autorun below)
  savedAnswer = ix.getAnswer()?.sentence
  if savedAnswer? and savedAnswer.trim() isnt ''
    editor.setValue(savedAnswer)
  unless savedAnswer?
    # Ensure that there is always an answer to submit, even if blank
    ix.setAnswerKey('', 'sentence')
  
  editor.on 'change', (doc) ->
    val = doc.getValue()
    textarea.value = val
    ix.setAnswerKey(val, 'sentence')
    
  
  # Allow the value of the editor to be updated by setting the session variable
  @autorun () ->
    # We need to `watchPathChange` so that the editor gets updated.
    FlowRouter.watchPathChange()
    val = ix.getAnswer()?.sentence or ''
    if val != editor.getValue()
      # Clear feedback because the answer has been changed from outside
      giveFeedback ""     
      editor.setValue val
  
  
Template.editSentence.destroyed = () ->
  @$('textarea').parent().find('.CodeMirror').remove()
  return


Template.editSentence.helpers
  'editorId': () ->
    return @editorId or 'code-mirror-textarea'
  'defaultContent' : () ->
    return @defaultContent
  'sentenceIsAwFOL' : () ->
    # The value should be in the template data context (provided on invocation)
    return @sentenceIsAwFOL


Template.editSentence.events
  'click #convert-to-symbols' : (event, template) ->
    answer = ix.getAnswer()?.sentence
    unless answer?
      console.log "Error getting answer (ix.getAnswer()?.sentence is undefined)."
      return
    ix.setDialectFromCurrentAnswer()
    try
      answerFOL = fol.parse( answer.replace(/\n/g,' ') )
    catch error
      giveFeedback "Your answer is not a correct sentence of #{fol.getPredLanguageName()}. (#{error})"
      return
    giveFeedback ""
    ix.setAnswerKey(answerFOL.toString({replaceSymbols:true}), 'sentence')






# =======
# editProof
# TODO: reduce duplication between this and editSentence



# Extract the proof from the editor and parse it.
getProof = () ->
  proofText = ix.getAnswer()?.proof
  return "There is no proof to check yet" unless proofText?
  theProof = proof.parse(proofText)
  return theProof

getCurrentLineNumberInEditor = (editor) ->
  {line, ch} = editor.getCursor()
  lineNumber = line+1
  return lineNumber

getPrevLineIndentation = (editor) ->
  {line, ch} = editor.getCursor()
  prevLine = editor.getLine(line-1)
  indentation = prevLine?.match(/^[\s|]*/)?[0]
  return indentation or ''

autoIndent = (editor) ->
  cursor = editor.getCursor()
  indentation = getPrevLineIndentation(editor)
  editor.replaceRange(indentation, cursor)

checkLine = (lineNumber) ->
  theProof = getProof()
  if _.isString(theProof)
    # There are errors in parsing the proof
    return {
      isCorrect : false
      msg : theProof
    }
  aLine = theProof.getLine(lineNumber)
  isCorrect = aLine.verify()
  return {
    isCorrect : isCorrect
    msg : ('' if isCorrect) or aLine.status.getMessage()
  }

checkLineAndUpdateMarker = (lineNumber, editor) ->
  {isCorrect, ignore} = checkLine(lineNumber)
  if isCorrect
    addMarker(lineNumber, 'chartreuse', editor) 
  else
    addMarker(lineNumber, '#FF3300', editor)
    
checkLineAndUpdateFeedback = (lineNumber, editor) ->
  {isCorrect, msg} = checkLine(lineNumber)
  giveFeedback "Line #{lineNumber}: #{("no errors found" if isCorrect) or "not correct"}.  #{msg}"
  


# Make a dot to show whether a line of the proof is correct.
addMarker = (lineNumber, color = "#822", editor) ->
  marker = document.createElement("div")
  marker.style.color = color
  marker.style.marginLeft = '15px'
  marker.innerHTML = "●"
  # `-1` because `.setGutterMarker` expects 0-based line numbers
  editor.setGutterMarker(lineNumber-1, "error-light", marker)



# Enchanced for sentences of FOL: includes a feedback line and a `convert to symbols` button.
# Also gets editor content from URL if not stored in session
Template.editProof.onRendered () ->
  o = @data.options or {}
  options = _.defaults o, {
    theme : 'blackboard'
    smartIndent : true
    lineNumbers : true
    autofocus : true
    matchBrackets : true
    gutters : ["error-light"]
    tabSize : 4
    extraKeys :
      Tab: (cm) ->
        cm.replaceSelection('    ');
  }
  textarea = @find('textarea')
  editor = CodeMirror.fromTextArea(textarea, options)
  Template.instance().editor = editor
  savedAnswer = ix.getAnswer()?.proof
  if savedAnswer? and savedAnswer.trim() isnt ''
    editor.setValue(savedAnswer)
  
  editor.on 'change', (doc) ->
    val = doc.getValue()
    textarea.value = val
    ix.setAnswerKey(val, 'proof')
  
  editor.on "keyHandled", (instance, name, event) ->
    if name is 'Up'
      lineNumber = getCurrentLineNumberInEditor(editor) 
      checkLineAndUpdateMarker(lineNumber+1, editor)
      checkLineAndUpdateFeedback(lineNumber, editor)
    if name is 'Enter'
      autoIndent(editor)
      # update the stored answer
      val = editor.getValue()
      ix.setAnswerKey(val, 'proof')
      lineNumber = getCurrentLineNumberInEditor(editor) 
      checkLineAndUpdateMarker(lineNumber-1, editor)
      checkLineAndUpdateFeedback(lineNumber-1, editor)
    if name is 'Down'
      lineNumber = getCurrentLineNumberInEditor(editor) 
      checkLineAndUpdateMarker(lineNumber-1, editor)
      checkLineAndUpdateFeedback(lineNumber, editor)
  
  # Allow the value of the editor to be updated by setting the session variable
  @autorun ->
    # We need to `watchPathChange` so that the editor gets updated.
    FlowRouter.watchPathChange()
    val = ix.getAnswer()?.proof or ix.getProofFromParams() or ''
    if val != editor.getValue()
      # Clear feedback because the answer has been changed from outside
      giveFeedback ""
      editor.setValue val
      answer = ix.getAnswer()?.proof
      if not answer?
        ix.setAnswerKey(val, 'proof')
  
  
Template.editProof.destroyed = () ->
  @$('textarea').parent().find('.CodeMirror').remove()
  return


Template.editProof.helpers
  'editorId': () ->
    return @editorId or 'code-mirror-textarea'
  'defaultContent' : () ->
    return @defaultContent
  'sentenceIsAwFOL' : () ->
    # The value should be in the template data context (provided on invocation)
    return @sentenceIsAwFOL
    
Template.editProof.events
  'click button#checkProof' : (event, template) ->
    proofText = ix.getAnswer()?.proof
    return undefined unless proofText?
    theProof = proof.parse(proofText)
    
    if _.isString theProof
      # The proof could not be parsed.
      giveFeedback "There is a problem with the formatting of your proof.  #{theProof}"
      return
    result = theProof.verify()
    giveFeedback "Is your proof correct? #{result}!"

    # Add the red/green dots to the proof
    for lineNumber in [1..ix.getAnswer().proof.split('\n').length]
      line = theProof.getLine(lineNumber)
      lineIsCorrect = line.verify()
      addMarker(lineNumber, 'chartreuse', template.editor) if lineIsCorrect
      addMarker(lineNumber, '#FF3300', template.editor) if not lineIsCorrect
    
    # finally, check the premises and conclusion are correct
    result = ix.checkPremisesAndConclusionOfProof(theProof)
    if _.isString result
      giveMoreFeedback result
    
  'click #resetProof' : (event, template) ->
    MaterializeModal.confirm
      title : "Reset your work on this proof"
      message : "Do you want to start again?"
      callback : (error, response) ->
        if response.submit
          giveFeedback ""
          ix.setAnswerKey(ix.getProofFromParams(), 'proof')
    
  'click #convert-to-symbols' : (event, template) ->
    proofText = ix.getAnswer()?.proof
    return undefined unless proofText?
    theProof = proof.parse(proofText)
    if _.isString theProof
      Materialize.toast "Syntax error in proof [#{theProof}]", 4000
      return undefined 
    newText = theProof.toString()
    ix.setAnswerKey(newText, 'proof')
    
    
    