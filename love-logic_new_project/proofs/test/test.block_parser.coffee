util = require 'util'

_ = require 'lodash'

chai = require('chai')
assert = chai.assert
expect = chai.expect

bp = require '../block_parser'

# For tests
INPUT = "1 A\n 2.1 A     \n 2.2 A\n\n 3.1 A\n 3.2 A\n  3.2.1 A\n4 A"
INPUT_LIST = (t.trim() for t in INPUT.split('\n'))
INPUT_WITH_DIVIDER = "1 A\n 2.1 A\n---\n 2.2 A\n\n 3.1 A\n 3.2 A\n  3.2.1 A\n4 A"

describe "block_parser", ->
  describe "`areLinesFormattedIndentationFirst`", ->
    it "recognises indentation first formatting", ->
      lines = "a\n  b".split('\n')
      expect(bp.areLinesFormattedIndentationFirst(lines)).to.be.true
    it "recognises number-first formatting", ->
      lines = "1. a\n2.    b".split('\n')
      expect(bp.areLinesFormattedIndentationFirst(lines)).to.be.false
    it "recognises number-first formatting when all lines are uniformly indented", ->
      lines = "  1. a\n  2.    b".split('\n')
      expect(bp.areLinesFormattedIndentationFirst(lines)).to.be.false
    it "defaults to indentation first formatting when styles are mixed", ->
      lines = "1. a\n2.   b\n    3.  c".split('\n')
      expect(bp.areLinesFormattedIndentationFirst(lines)).to.be.true

  describe ".split ", ->
    it "works when a line is indentation first", ->
      line = "    1. a"
      indentationFirst = true
      {indentation, content} = bp.split line, indentationFirst
      expect(content.trim()).to.equal("1. a")
      expect(indentation).to.equal("    ")
    it "works when a line is indentation first using |", ->
      line = "| |   1. a"
      indentationFirst = true
      {indentation, content} = bp.split line, indentationFirst
      expect(content.trim()).to.equal("1. a")
      expect(indentation).to.equal("| |   ")
    it "works when a line is not indented", ->
      line = "line"
      indentationFirst = true
      {indentation, content} = bp.split line, indentationFirst
      expect(content.trim()).to.equal("line")
      expect(indentation).to.equal("")
    it "works when a line is indented and has no number", ->
      line = " | line"
      indentationFirst = true
      {indentation, content} = bp.split line, indentationFirst
      expect(content.trim()).to.equal("line")
      expect(indentation).to.equal(" | ")

    it "works when a line is not indented and `indentationFirst` is false", ->
      line = "line"
      indentationFirst = false
      {indentation, content} = bp.split line, indentationFirst
      expect(content.trim()).to.equal("line")
      expect(indentation).to.equal("")
    it "works when a line contains only a number and `indentationFirst` is false", ->
      line = "3."
      indentationFirst = false
      {indentation, content} = bp.split line, indentationFirst
      expect(content.trim()).to.equal("3.")
      expect(indentation).to.equal("")
    it "works when `indentationFirst` is false", ->
      line = "1. | a"
      indentationFirst = false
      {indentation, content} = bp.split line, indentationFirst
      expect(content.trim()).to.equal("1. a")
      expect(indentation).to.equal(" | ")
    it "works when a line is indented and has no number, and `indentationFirst` is false", ->
      line = " | line"
      indentationFirst = false
      {indentation, content} = bp.split line, indentationFirst
      expect(content.trim()).to.equal("line")
      expect(indentation).to.equal(" | ")
  
  describe ".isDivider ", ->
    it "recognises a simple divider ---", ->
      r = bp._isDivider("---")
      expect(r).to.be.true
    it "recognises a simple divider __", ->
      r = bp._isDivider("__")
      expect(r).to.be.true
    it "recognises a number followed by divider ", ->
      r = bp._isDivider("1. __")
      expect(r).to.be.true
    it "does not treat blank lines as dividers ", ->
      r = bp._isDivider("")
      expect(r).to.be.false
    it "does not treat lines with numbers that are otherwise blank as dividers ", ->
      r = bp._isDivider("1.")
      expect(r).to.be.false
    it "does not treat lines with numbers and whitespace only as dividers ", ->
      r = bp._isDivider("1.  ")
      expect(r).to.be.false
    it "allows whitespace after a divider ", ->
      r = bp._isDivider("1. __  ")
      expect(r).to.be.true
      r = bp._isDivider("---   ")
      expect(r).to.be.true
    it "allows whitespace before a divider ", ->
      r = bp._isDivider("   ---   ")
      expect(r).to.be.true
    it "allows whitespace before a divider with a number", ->
      r = bp._isDivider("  1. __  ")
      expect(r).to.be.true
    it "doesn't treat non-dividers as dividers", ->
      r = bp._isDivider("hello")
      expect(r).to.be.false
    it "doesn't treat non-dividers as dividers even when they start with numbers", ->
      r = bp._isDivider("1. hello")
      expect(r).to.be.false
      
  describe ".isBlank ", ->
    it "recognises empty lines as blank", ->
      r = bp._isBlank('')
      expect(r).to.be.true
    it "recognises blank lines", ->
      r = bp._isBlank('    ')
      expect(r).to.be.true
    it "recognises blank lines with numbers", ->
      r = bp._isBlank('1.   ')
      expect(r).to.be.true
      r = bp._isBlank('   1.   ')
      expect(r).to.be.true
      r = bp._isBlank('   1.')
      expect(r).to.be.true
    it "does not treat dividers as blank lines", ->
      r = bp._isBlank('   1. ---')
      expect(r).to.be.false
      r = bp._isBlank('--')
      expect(r).to.be.false
    it "does not treat lines with content as blank lines", ->
      r = bp._isBlank('hello')
      expect(r).to.be.false
      
  
  describe "Block", ->
    it "enables us to create blocks", ->
      b = new bp.Block()
      expect(b.type).to.equal('block')
    it "enables us to add lines to blocks", ->
      b = new bp.Block()
      l = b.newLine({content:'hello',indentation:' ',idx:1})
      expect(l.parent).to.equal(b)
      expect(b.getLastLine()).to.equal(l)
    it "enables us to add blocks to blocks", ->
      b1 = new bp.Block()
      b2 = b1.newBlock()
      expect(b2.parent).to.equal(b1)
      expect(b2).to.not.equal(b1)
      expect(b1.getLastLine()).to.equal(b2)
    it "enables us to add multiple lines to blocks", ->
      b = new bp.Block()
      l1 = b.newLine({content:'hello',indentation:' ',idx:1})
      l2 = b.newLine({content:'again',indentation:' ',idx:1})
      expect(b.getLastLine()).to.equal(l2)
      expect(l2.prev).to.equal(l1)
    it "closing a block returns its parent", ->
      b1 = new bp.Block()
      b2 = b1.newBlock()
      b3 = b2.close()
      b4 = b3.close()
      expect(b3).to.equal(b1)
      expect(b4?).to.be.false
    it "the top block has no parent", ->
      b = new bp.Block()
      expect(b.parent?).to.be.false
    it "allows us to test whether a line is the first line in a block", ->
      b = new bp.Block()
      l1 = b.newLine({content:'hello',indentation:' ',idx:1})
      l2 = b.newLine({content:'again',indentation:' ',idx:1})
      expect( l1.parent.content[0] is l1 ).to.be.true
      expect( l1.parent.content[0] is l2 ).to.be.false
    
    describe ".walk", ->
      it "visits every item in the order of lines", ->
        input = INPUT
        block = bp.parse input
        walker =
          last : "0"
          seen : []
          visit : (item) ->
            return undefined if item.type isnt 'line'
            if not item.content > @last and item.content isnt ""
              throw new Error "Walker got lost: last = #{@last}, current = #{item.content}; seen = #{@seen}."
            @seen.push item.content.trim()
            last = item.content
            return undefined 
        block.walk walker
        expect( walker.seen ).to.deep.equal( (x for x in INPUT_LIST when x isnt '') )

    describe ".getLine", ->
      it "will go to a line", ->
        block = bp.parse INPUT
        #console.log block.toString()
        line = block.getLine(3)
        expect(line.content).to.equal(INPUT_LIST[2])

    describe ".find", ->
      it "finds things in earlier lines of the proof", ->
        block = bp.parse INPUT
        line = block.getLine(3)
        finder = (item) ->
          return true if item.content.trim() is INPUT_LIST[1]
        result = line.find(finder)
        expect(result.content.trim()).to.equal(INPUT_LIST[1])
        
      it "finds things in the first line of the proof", ->
        block = bp.parse INPUT
        # Note: in this case, the last line is INPUT_LIST.length-1
        # because INPUT contains one blank line.
        line = block.getLine(INPUT_LIST.length-1)

        finder = (item) ->
          #console.log "item.content = #{item.content}"
          return true if _.isString(item.content) and item.content.trim() is INPUT_LIST[0]
        result = line.find(finder)
        expect(result.content).to.equal(INPUT_LIST[0])
        
      it "doesn't look in lines below the current one", ->
        block = bp.parse INPUT
        line = block.getLine(2)
        finder = (item) ->
          return true if item.content is '2.2'
        result = line.find(finder)
        expect(result).to.equal(false)
        
      it "doesn't look into closed blocks", ->
        block = bp.parse INPUT
        line = block.getLine(INPUT_LIST.length-1)
        finder = (item) ->
          return true if _.isString(item.content) and item.content.trim() is INPUT_LIST[2]
        result = line.find(finder)
        expect(result).to.equal(false)
        
      
  describe ".parse", ->
    it "parses a one line input", ->
      input = "hello"
      out = bp.parse input
      expect(out.type).to.equal('block')
      line1 = out.getLastLine()
      expect(line1.content).to.equal('hello')
      expect(line1.type).to.equal('line')
    
    it "parses two lines (no indentation yet)", ->
      input = "hello\nthere"
      block = bp.parse input
      expect(block.getLastLine().content).to.equal('there')      
      expect(block.getLastLine().type).to.equal('line')      
      expect(block.getLastLine().prev.type).to.equal('line')      
      expect(block.content.length).to.equal(2)
      
    it "has a string representation", ->
      input = "hello\nthere"
      block = bp.parse input
      #console.log block.toString()
      expect(block.toString()).not.to.equal(undefined)
      
    it "parses two lines with indentation", ->
      input = "hello\n  there"
      block = bp.parse input
      expect(block.content[0].content).to.equal('hello')
      expect(block.content[1].type).to.equal('block')
      block2 = block.getLastLine()
      expect(block2.getLastLine().content).to.equal('there')

    it "parses two numbered lines with indentation", ->
      input = "1. hello\n  2. there"
      block = bp.parse input
      expect(block.content[0].content).to.equal('1. hello')
      expect(block.content[1].type).to.equal('block')
      block2 = block.getLastLine()
      expect(block2.getLastLine().content).to.equal('2. there')

    it "parses two numbered lines with indentation where indentation occurs before numbers", ->
      input = "1. hello\n2.    there"
      block = bp.parse input
      expect(block.content[0].content).to.equal('1. hello')
      expect(block.content[1].type).to.equal('block')
      block2 = block.getLastLine()
      expect(block2.getLastLine().content).to.equal('2. there')

    it "parses three lines with indentation", ->
      input = "in\n  out\nback in"
      # lastLine.prev.prev.parent [block]
      #   lastLine.prev.prev ['in']
      #   lastLine.prev [subBlock]
      #   subBlock.getLastLine() ['out']
      # lastLine ['back in']
      block = bp.parse input 
      lastLine = block.getLastLine()
      expect(lastLine.content).to.equal('back in')
      subBlock = lastLine.prev
      expect(subBlock.type).to.equal('block')
      expect(subBlock.getLastLine().content).to.equal('out')
      firstLine = lastLine.prev.prev
      expect(firstLine.type).to.equal('line')
      expect(firstLine.content).to.equal('in')
      expect(firstLine.parent).to.equal(block)
      
    it "parses with  | for indentation", ->
      input = "| in\n| |out\n| back in"
      # lastLine.prev.prev.parent [block]
      #   lastLine.prev.prev ['in']
      #   lastLine.prev [subBlock]
      #   subBlock.getLastLine() ['out']
      # lastLine ['back in']
      block = bp.parse input 
      lastLine = block.getLastLine()
      expect(lastLine.content).to.equal('back in')
      subBlock = lastLine.prev
      expect(subBlock.type).to.equal('block')
      expect(subBlock.getLastLine().content).to.equal('out')
      firstLine = lastLine.prev.prev
      expect(firstLine.type).to.equal('line')
      expect(firstLine.content).to.equal('in')
      expect(firstLine.parent).to.equal(block)
      
    it "parses several lines with multiple indentation levels", ->
      input = "1\n  2.1\n  2.2\n\n  3.1\n  3.2\n    3.2.1\n    3.2.2\n4"
      block = bp.parse input 
      #console.log block.toString()

    it "throws when indentation is invalid", ->
      expect( -> bp.parse("a\n    b\n c") ).to.throw(Error)
    
    it "identifies dividers as dividers", ->
      block_div    = bp.parse "1 A\n 2.1 A\n---\n 2.2 A\n\n 3.1 A\n 3.2 A\n  3.2.1 A\n4 A"
      block_no_div = bp.parse "1 A\n 2.1 A     \n 2.2 A\n\n 3.1 A\n 3.2 A\n  3.2.1 A\n4 A"
      line3_div = block_div.getLine(3)
      line3_nodiv = block_no_div.getLine(3)
      expect(line3_div.content).to.equal(line3_nodiv.content)
      expect(line3_div.prev.type).to.equal('divider')
    
    it "parses a proof with numbers first and indentation", ->
      proofText = '''
        1. hello
        2.    block start
        3.    block end
        4. cite block and line  // exists elim 1, 2-3
      '''
      block = bp.parse proofText
      subBlock = block.content[1]
      expect(subBlock.type).to.equal('block')
      expect(block.indentation.length < subBlock.indentation.length)
      
    it "parses a proof with numbers first and multiple blocks", ->
      proofText = '''
        1. hello
        2.    block start
        3.    block end
        4.
        5.    block2 start
        6.    block2 end
        7. cite block and line  // exists elim 2-3, 5-6
      '''
      block = bp.parse proofText
      subBlock2 = block.content[3]
      expect(subBlock2.type).to.equal('block')
      expect(block.indentation.length < subBlock2.indentation.length)
  
  describe "in some tricky cases", ->
    it "does ok with blank line first followed by a subblock", ->
      proof = '''
           | 
        1. | | A              // assumption
        2. | | contradiction  // contradiction intro 1,2
        3. | not A            // not intro 1-2
      '''
      block = bp.parse proof
      subBlock = block.content[1]
      expect(subBlock.type).to.equal('block')
      expect(subBlock.content.length).to.equal(2)
      
    it "does ok with blank line first followed by a subblock (indentation with spaces)", ->
      # Note: the spaces on the first line are critical here!
      proof = '''
        1. 
        2.    A               // assumption
        3.    contradiction   // contradiction intro 1,2
        4. not A              // not intro 1-2
      '''
      block = bp.parse proof
      subBlock = block.content[1]
      expect(subBlock.type).to.equal('block')
      expect(subBlock.content.length).to.equal(2)

    it "deals with dividers that run the length of a line", ->
      proof = '''
        1. | 
        2. | | A              // assumption
        -------------
        3. | | contradiction  // contradiction intro 1,2
        4. | not A            // not intro 1-2
      '''
      block = bp.parse proof
      subBlock = block.content[1]
      expect(subBlock.type).to.equal('block')
      expect(subBlock.content.length).to.equal(3)

    it "deals with dividers that come after indentation", ->
      proof = '''
        1. | 
        2. | | A              // assumption
        3. | | ----------
        4. | | contradiction  // contradiction intro 1,2
        5. | not A            // not intro 1-2
      '''
      block = bp.parse proof
      subBlock = block.content[1]
      expect(subBlock.type).to.equal('block')
      expect(subBlock.content.length).to.equal(3)

    it "deals with dividers that come after indentation (divider is not numbered)", ->
      proof = '''
        1. | 
        2. | | A              // assumption
           | | ----------
        4. | | contradiction  // contradiction intro 1,2
        5. | not A            // not intro 1-2
      '''
      block = bp.parse proof
      subBlock = block.content[1]
      expect(subBlock.type).to.equal('block')
      expect(subBlock.content.length).to.equal(3)

    it "deals with dividers that come after indentation (using spaces for indentation)", ->
      # Note: the spaces on the first line are critical here!
      proof = '''
        1. 
        2.   A              // assumption
        3.   ----------
        4.   contradiction  // contradiction intro 1,2
        5. not A            // not intro 1-2
      '''
      block = bp.parse proof
      subBlock = block.content[1]
      expect(subBlock.type).to.equal('block')
      expect(subBlock.content.length).to.equal(3)

    it "deals with dividers that come after indentation (using spaces for indentation and no number on the divider line)", ->
      # Note: the spaces on the first line are critical here!
      proof = '''
        1. 
        2.   A              // assumption
             ----------
        4.   contradiction  // contradiction intro 1,2
        5. not A            // not intro 1-2
      '''
      block = bp.parse proof
      subBlock = block.content[1]
      expect(subBlock.type).to.equal('block')
      expect(subBlock.content.length).to.equal(3)
