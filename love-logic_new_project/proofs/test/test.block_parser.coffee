chai = require('chai')
assert = chai.assert
expect = chai.expect


bp = require '../block_parser'

# For tests
INPUT = "1\n 2.1\n 2.2\n\n 3.1\n 3.2\n  3.2.1\n4"
INPUT_LIST = (t.trim() for t in INPUT.split('\n'))
INPUT_WITH_DIVIDER = "1\n 2.1\n---\n 2.2\n\n 3.1\n 3.2\n  3.2.1\n4"

describe "block_parser", ->
  describe "Block", ->
    it "enables us to create blocks", ->
      b = new bp.Block()
      expect(b.type).to.equal('block')
    it "enables us to add lines to blocks", ->
      b = new bp.Block()
      l = b.newLine('hello')
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
      l1 = b.newLine('hello')
      l2 = b.newLine('again')
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
      l1 = b.newLine('hello')
      l2 = b.newLine('again')
      expect( l1.parent.content[0] is l1 ).to.be.true
      expect( l1.parent.content[0] is l2 ).to.be.false
    
    describe ".walk", ->
      it "visits every item in the order of lines", ->
        input = "1\n 2.1\n 2.2\n\n 3.1\n 3.2\n  3.2.1\n4"
        block = bp.parse input
        walker =
          last : "0"
          seen : []
          visit : (item) ->
            return undefined if item.type isnt 'line'
            if not item.content > @last and item.content isnt ""
              throw new Error "Walker got lost: last = #{@last}, current = #{item.content}; seen = #{@seen}."
            @seen.push item.content
            last = item.content
            return undefined 
        block.walk walker
        expect( walker.seen ).to.deep.equal( t.trim() for t in input.split("\n"))

    describe ".goto", ->
      it "will go to a line", ->
        block = bp.parse INPUT
        line = block.goto(3)
        expect(line.content).to.equal(INPUT_LIST[2])

    describe ".find", ->
      it "finds things in earlier lines of the proof", ->
        block = bp.parse INPUT
        line = block.goto(3)
        finder = (item) ->
          return true if item.content is '2.1'
        result = line.find(finder)
        expect(result.content).to.equal('2.1')
        
      it "finds things in the first line of the proof", ->
        block = bp.parse INPUT
        line = block.goto(INPUT_LIST.length)
        finder = (item) ->
          return true if item.content is '1'
        result = line.find(finder)
        expect(result.content).to.equal('1')
        
      it "doesn't look in lines below the current one", ->
        block = bp.parse INPUT
        line = block.goto(2)
        finder = (item) ->
          return true if item.content is '2.2'
        result = line.find(finder)
        expect(result).to.equal(false)
        
      it "doesn't look into closed blocks", ->
        block = bp.parse INPUT
        line = block.goto(INPUT_LIST.length)
        finder = (item) ->
          return true if item.content is '2.2'
        result = line.find(finder)
        expect(result).to.equal(false)
        
      
  describe "parse", ->
    it "parses a one line input", ->
      input = "hello"
      out = bp.parse input
      expect(out.type).to.equal('block')
      expect(out.getLastLine().content).to.equal('hello')
    
    it "parses two lines (no indentation yet)", ->
      input = "hello\nthere"
      block = bp.parse input
      expect(block.getLastLine().content).to.equal('there')      
      expect(block.content.length).to.equal(2)
      
    it "has a string representation", ->
      input = "hello\nthere"
      block = bp.parse input
      console.log block.toString()
      expect(block.toString()).not.to.equal(undefined)
      
    it "parses two lines with indentation", ->
      input = "hello\n  there"
      block = bp.parse input
      expect(block.content[0].content).to.equal('hello')
      expect(block.content[1].type).to.equal('block')
      #expect(block.getLastLine().type).to.equal('block')
      block2 = block.getLastLine()
      expect(block2.getLastLine().content).to.equal('there')

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
      block_div = bp.parse INPUT_WITH_DIVIDER
      block_no_div = bp.parse INPUT
      line3_div = block_div.goto(3)
      line3_nodiv = block_no_div.goto(3)
      expect(line3_div.content).to.equal(line3_nodiv.content)
      expect(line3_div.prev.type).to.equal('divider')
      