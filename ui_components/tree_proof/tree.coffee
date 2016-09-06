# This module is made global as `tree` in `awfol.browserifyme.coffee`
# (as are `fol` and `proof`).
#
# Also depends on these (which, it is assumed, are global)
#   -  CodeMirror
#   - jQuery ($)

_ = require 'lodash'
{Treant} = require ('./Treant')

#fol = require '../../love-logic_new_project/fol' 
proof = require '../../love-logic_new_project/proofs/proof'

decorateTreeProof = (treeProof, _parent) ->
  if _parent?
    treeProof.id = "#{_parent.id}.c#{_parent.children.indexOf(treeProof)}"
    treeProof.parent = _parent
  else
    treeProof.id = "r"
  treeProof.addChild = (childProofText) ->
    child = makeTreeProof(childProofText, treeProof)
    child.id = "#{@id}.c#{@children.length}"
    child.depth = @depth+1
    child.parent = @
    @children.push(child)
    return child
  treeProof.addSib = (sibProofText) ->
    return @parent.addChild(sibProofText)
  treeProof.getSibs = () ->
    return [@] unless @parent?
    return @parent.children
  treeProof.clear = () ->
    @children = []
    @proofText = ""
    @displayEditable()
    return @
  treeProof.setProofText = (txt) ->
    @proofText = txt
    @displayEditable()
    return @
  treeProof.remove = () ->
    idx = @parent.children.indexOf(@)
    @parent.children.splice(idx,1)
    return @parent
  treeProof.walk = (fn) ->
    (c.walk(fn) for c in @children)
    fn(@)
  treeProof.setInnerHTML = (nodeToHTML) ->
    @walk (node) ->
      node.innerHTML = nodeToHTML(node)
    return @
  treeProof.getNodeLocator = () ->
    nodeLocator = {}
    @walk (node) ->
      nodeLocator[node.id] = node
    return nodeLocator
  treeProof._getLinesAndNumbers = () ->
    counter = @getFirstLineNumber()
    proofLines = []
    for line, idx in @proofText.split('\n')
      proofLines.push {indentation:'|', number:counter+idx, text:line.trim()}
    childrenProofLines = (c._getLinesAndNumbers() for c in @children) 
    for c in childrenProofLines
      continue unless c.length > 0
      line = c[0]
      priorIndentation = line.indentation
      for line in c
        line.indentation += '|'
        proofLines.push(line)
      proofLines.push({indentation:priorIndentation, number:' ', text:''})
    return proofLines
  treeProof.toSequent = () ->
    proofLines = @_getLinesAndNumbers()
    res = ""
    for l in proofLines
      res += "#{l.number} #{l.indentation} #{l.text}\n"
    return res.trim()
  treeProof.toProofObject = () ->
    txt = @toSequent()
    return proof.parse(txt, {treeProof:true})

  # line numbers for trees
  treeProof.getLastLineNumber = () ->
    nofLines = treeProof.proofText.split('\n').length
    return nofLines unless treeProof.parent?
    lengths = (sib.getLastLineNumber() for sib in treeProof.parent.getSibs())
    return _.max(lengths) + nofLines
  treeProof.getFirstLineNumber = () ->
    return 1 unless treeProof.parent?
    lengths = (sib.getLastLineNumber() for sib in treeProof.parent.getSibs())
    return  _.max(lengths)+ 1

  # This allows you to persist the tree proof
  treeProof.toBareTreeProof = () ->
    r = {
      @proofText
      @id
      @depth
      children : (c.toBareTreeProof() for c in @children)
    }
    
  treeProof.verify = () ->
    p = @toProofObject()
    isCorrect = p.verifyTree()
    errorMessages = p.listErrorMessages()
    return {isCorrect, errorMessages}
  
  # Returns a new proof, or a string explaining
  # why the proof could not be parsed.
  treeProof.convertToSymbols = () ->
    txt = @toSequent()
    p = proof.parse(txt, {treeProof:true})
    if _.isString p
      # There was an error parsing the proof (e.g. duplicate line numbers)
      return p
    newTree = convertProofToTreeProof(p)
    newTree.container = @container
    newTree.onChange = @onChange
    return decorateTreeProof(newTree)
  
  treeProof.displayEditable = (container, onChange, doAfterCreating) ->
    @container ?= container
    @onChange ?= onChange
    oldScrollLeft = $(window).scrollLeft()
    oldScrollTop = $(window).scrollTop()
    @resizeContainer(50,50)
    self = @
    whatToDoAfterCreating = (editorLocator) ->
      self.resizeContainer()
      $(window).scrollLeft(oldScrollLeft)
      $(window).scrollTop(oldScrollTop)
      doAfterCreating?(editorLocator)
    displayEditable(treeProof, @container, @onChange, whatToDoAfterCreating)
    return treeProof
  treeProof.displayStatic = (container) ->
    @container ?= container
    @resizeContainer(50,50)
    displayStatic(treeProof, container)
    @resizeContainer()
    return treeProof
  
  treeProof.resizeContainer = (width, height) ->
    $svg = $('svg', @container)
    width ?=  $svg.width()+150  
    height ?= $svg.height()+50
    $container = $(@container)
    $container.height( height )
    $container.width( width )
  
  treeProof.areAllBranchesClosed = () ->
    return @toProofObject().areAllBranchesClosed()
  treeProof.areAllBranchesClosedOrOpen = () ->
    return @toProofObject().areAllBranchesClosedOrOpen()
  treeProof.hasOpenBranch = () ->
    return @toProofObject().hasOpenBranch()
  
  treeProof.getPremises = () ->
    return @toProofObject().getPremises()
  
  newParent = treeProof
  for c in treeProof.children
    decorateTreeProof(c, newParent)
  
  return treeProof
exports.decorateTreeProof = decorateTreeProof

makeTreeProof = (rootProofText, _parent) ->
  node = {
    proofText : rootProofText.trim()
    depth : 0
    children : []
  }
  return decorateTreeProof(node, _parent)
exports.makeTreeProof = makeTreeProof

display = (treeProof, container, nodeToHTML, callback) ->
  $(container).html('')
  nodes = treeProof.setInnerHTML(nodeToHTML)
  chartCfg = 
    chart : 
      container: container
      nodeAlign : 'BOTTOM'
      connectors:
        type : 'straight'
    nodeStructure: nodes
  # console.log "chartCfg"
  # console.log chartCfg
  theTreant = new Treant(chartCfg, callback)
  global.theTreant = theTreant
  return theTreant
exports.display = display

displayStatic = ( treeProof, container ) ->
  display( treeProof, container, nodeToHTML )
exports.displayStatic = displayStatic

# `onChange` is a function called when a value in one of the editors in 
# the tree changes.
# `callback` is called after the tree DOM elements (including the editors)
# are created.
displayEditable = (treeProof, container, onChange, callback) ->
  doAfterCreatingTreant = () ->
    # Create the CodeMirror things
    options = {
      theme : 'blackboardTree'
      smartIndent : true
      lineNumbers : true
      autofocus : true
      mode : 'fol'
      matchBrackets : true
      # gutters : ["error-light"]
      tabSize : 4
      extraKeys :
        Tab: (cm) ->
          cm.replaceSelection('    ');
    }
    nodeLocator = treeProof.getNodeLocator()
    editorLocator = {}
    for t in $("#{container} textarea")
      proofId = $(t).attr('data-proofId')
      node = nodeLocator[proofId]
      options.firstLineNumber = node.getFirstLineNumber()
      editor = CodeMirror.fromTextArea(t, options)
      editorLocator[proofId] = editor
      editor.on 'change', ((node) -> (doc) ->
        txt = doc.getValue()
        node.proofText = txt
        # console.log "updated node #{node.id}, set to #{txt}"
        onChange?(node)
      )( node )
      editor.on 'keyHandled', ((node, treeProof, container) -> (instance, name, event) ->
        if name is 'Enter'
          # console.log "#treeAddChild#{node.id.replace('.','-')}"
          $("#treeAddChild#{node.id.replace('.','-')}").parent().animate({marginTop:"+=1.5em"})
          # Don’t do this because it messes up cursor position
          #treeProof.displayEditable(container)
      )(node, treeProof, container)
    
    # Bind the links for adding and removing children and siblings
    $('.treeAddChild').click ((treeProof, container, nodeLocator) -> (e) ->
      node = _getNode $(e.target), nodeLocator
      firstNewChild = node.addChild('')
      firstNewChild.addSib('')
      doAfterCreating = (editorLocator) ->
        editorToFocus = editorLocator[firstNewChild.id]
        editorToFocus.focus()
      treeProof.displayEditable(container, undefined, doAfterCreating)
      onChange?(node)
      )(treeProof, container, nodeLocator)
    $('.treeAddSib').click ((treeProof, container, nodeLocator) -> (e) ->
      node = _getNode $(e.target), nodeLocator
      node.addSib('')
      treeProof.displayEditable(container)
      onChange?(node)
      )(treeProof, container, nodeLocator)
    $('.treeRemoveNode').click ((treeProof, container, nodeLocator) -> (e) ->
      node = _getNode $(e.target), nodeLocator
      node.remove()
      treeProof.displayEditable(container)
      onChange?(node)
      )(treeProof, container, nodeLocator)
    # Finally, do whatever the caller requested:
    callback?(editorLocator)
  display( treeProof, container, nodeToTextarea, doAfterCreatingTreant )
exports.displayEditable = displayEditable

_getNode = ($el, nodeLocator) ->
  proofId = $el.attr('data-proofId')
  unless proofId?
    proofId = $el.parent().attr('data-proofId')
  return nodeLocator[proofId]
  

nodeToHTML = (node) ->
  proofText = node.proofText
  firstLineNumber = node.getFirstLineNumber()
  lines = []
  for line, idx in proofText.split('\n')
    lines.push "#{firstLineNumber+idx}.  #{line.trim()}"
  return "<div style='white-space:pre;margin-left:3em;'>#{lines.join('<br>')}"
  
nodeToTextarea = (node) ->
  proofText = node.proofText
  isLeaf = (not node.children?) or node.children.length is 0
  siblings = node.parent?.children
  isRightmostBranch = node is siblings?[siblings?.length-1]
  res = "<div style='white-space:pre;margin-left:3em;width:325px;height:#{23*(proofText.split('\n').length)}px;'><textarea data-proofId='#{node.id}'>#{proofText}</textarea></div>"
  if isLeaf
    res += "<div class='center' style='margin-left:3em;margin-top:2em;'><a id='treeAddChild#{node.id.replace('.','-')}' class='treeAddChild hint--bottom' data-hint='branch' data-proofId='#{node.id}'><i class='material-icons branch'>add_circle_outline</i></a></div>"
    if isRightmostBranch 
      linkRemoveSib = "<a class='treeRemoveNode hint--bottom' data-hint='remove rightmost node' data-proofId='#{node.id}' ><i class='material-icons'>remove_circle_outline</i></a>"
      linkAddSib = "<a class='treeAddSib hint--bottom' data-hint='add a node' data-proofId='#{node.id}' ><i class='material-icons'>add_circle_outline</i></a>"
      res = "<div style='width:300px;'><div style='float:right;'>#{linkRemoveSib}#{linkAddSib}</div>#{res}</div>"
  return res


areDistinctProofs = (t1, t2) ->
  return false if t1 is t2
  return true unless t1? and t2?
  t1 = decorateTreeProof( _.clone(t1) )
  t2 = decorateTreeProof( _.clone(t2) )
  return t1.toSequent() isnt t2.toSequent()
exports.areDistinctProofs = areDistinctProofs

# Converts a `proof` object to a `treeProof` object
convertProofToTreeProof = (theProof) ->
  {childlessProof, children} = theProof.detachChildren()
  proofText = childlessProof.removeBlankAndDividerLines().toString({treeProof:true, numberLines:false})
  proofText = (x.trim() for x in proofText.split('\n')).join('\n')
  nodes = {
    proofText : proofText
    children : (convertProofToTreeProof(c) for c in children)
  }
  return decorateTreeProof(nodes)
exports.convertProofToTreeProof = convertProofToTreeProof  

fromSequent = (sequentTxt) -> decorateTreeProof(convertProofToTreeProof(proof.parse(sequentTxt, {treeProof:true})))
exports.fromSequent = fromSequent

