chai = require('chai')
assert = chai.assert
expect = chai.expect

util = require 'util'

bp = require '../block_parser'
ln = require '../add_line_numbers'

# For tests
INPUT = "1 A\n 2.1 A     \n 2.2 A\n\n 3.1 A\n 3.2 A\n  3.2.1 A\n4 A"
INPUT_LIST = (t.trim() for t in INPUT.split('\n'))
INPUT_NO_NUMBERS = "a1\n a2.1\n a2.2\n\n a3.1\n a3.2\n  a3.2.1\na4"

describe "add_line_numbers", ->
  describe "addNumbers", ->
    it "can add line numbers to a block with no line numbers", ->
      block = bp.parse INPUT_NO_NUMBERS
      ln.addNumbers block
      # console.log block.toString()
      expect(block.goto(3).number).to.equal("3")
      expect(block.goto(3).parent.number).to.equal("2-3")
    it "can add line numbers to a block with no line numbers", ->
      block = bp.parse INPUT_NO_NUMBERS
      ln.addNumbers block
      expect(block.goto(3).number).to.equal("3")
    it "removes line numbers from line.content", ->
      block = bp.parse INPUT
      ln.addNumbers block
      expect(block.goto(3).content).to.equal('A')
    it "throws on duplicate line numbers", ->
      block = bp.parse "1. A\n 2. A\n 1. A"
      expect( -> ln.addNumbers block ).to.throw(Error)
    