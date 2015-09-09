_ = require 'lodash'

util = require 'util'

chai = require('chai')
assert = chai.assert
expect = chai.expect

bp = require '../block_parser'
jp = require '../justification_parser' 
ln = require '../add_line_numbers'
addJustification = require '../add_justification'


INPUT = "1 // premise \n 2.1 no justification \n 2.2 // and elim 1\n\n 3.1 //assumption\n 3.2 // invalid justification and or elim\n  3.2.1 // and elim missing numbers\n4 //reit 1"
BLOCK = bp.parse INPUT

describe "add_justification", ->
  describe "addJustification", ->
    it "adds justification to a test block", ->
      block = addJustification.to BLOCK
      expect(block.getLastLine().justification.rule.connective).to.equal('reit')
      # console.log BLOCK.toString()
    
    it "calling it twice is not harmful", ->
      block = addJustification.to BLOCK
      block = addJustification.to BLOCK
      expect(block.getLastLine().justification.rule.connective).to.equal('reit')

    it "strips justification from `line.content`", ->
      block = addJustification.to BLOCK
      expect(block.goto(3).content).to.equal('2.2 ')

    it "records error messages where justification can't be parsed", ->
      block = addJustification.to BLOCK
      line = block.goto(5)
      #console.log util.inspect(line)
      expect(line.justificationErrors.slice(0,5)).to.equal('Parse')

    it "doesn't mess with the text of lines missing justification", ->
      block = addJustification.to BLOCK
      expect(block.goto(2).content.trim()).to.equal(INPUT.split('\n')[1].trim())

    it "adds justification to premises where necessary", ->
      block = addJustification.to BLOCK
      expect(block.goto(2).justification.rule.connective).to.equal('premise')

    it "adds doesn't add justification to non-premises", ->
      block = bp.parse "1. A\n2. A\n A"
      block = addJustification.to block
      expect(block.goto(1).justification.rule.connective).to.equal('premise')
      expect(block.goto(2).justification?).to.be.false

    it "treats everything above the divider as a premise in the outer block", ->
      block = bp.parse "1. A\n2. A\n---\n3. A"
      block = addJustification.to block
      expect(block.goto(2).justification.rule.connective).to.equal('premise')

    it "doesn't treats everything above the divider as a premise in inner blocks", ->
      block = bp.parse "1. A\n| |2. A\n| |3. A\n| |---\n| |4. A"
      block = addJustification.to block
      expect(block.goto(2).justification.rule.connective).to.equal('premise')
      expect(block.goto(3).type).to.equal('line')
      expect(block.goto(3).justification?).to.be.false
      
    it "only treats the first divider as significant in working out what's a premise in the outer block", ->
      block = bp.parse "1. A\n2. A\n---\n3. A\n---\n4. A"
      block = addJustification.to block
      expect(block.goto(2).justification.rule.connective).to.equal('premise')
      expect(block.goto(4).type).to.equal('line')
      expect(block.goto(4).justification?).to.be.false

    it "enables a line tell you the name of its rule", ->
      ln.addNumbers BLOCK
      block = addJustification.to BLOCK
      line = block.goto 3
      #console.log line.getRuleName()
      expect(line.getRuleName()).to.equal('and elim')
      
    it "enables a line to get you the block it references", ->
      input = '''
        1. A
        | 2. A
        | 3. contradiction
        4. not A // not elim 2-3
      '''
      block = bp.parse input
      ln.addNumbers block
      addJustification.to block
      expected = block.goto(2).parent
      line4 = block.goto 4
      # console.log input
      # console.log block.toString()
      expect(line4.getCitedBlock()).to.equal(expected)
    