chai = require('chai')
assert = chai.assert
expect = chai.expect

util = require 'util'

bp = require '../block_parser'
ln = require '../line_numbers'

# For tests
INPUT = "1\n 2.1\n 2.2\n\n 3.1\n 3.2\n  3.2.1\n04"
INPUT_LIST = (t.trim() for t in INPUT.split('\n'))
INPUT_NO_NUMBERS = "a1\n a2.1\n a2.2\n\n a3.1\n a3.2\n  a3.2.1\na4"

describe "line_numbers", ->
  describe "addNumbers", ->
    it "can add line numbers to a block with no line numbers", ->
      block = bp.parse INPUT_NO_NUMBERS
      ln.addNumbers block
      # console.log block.toString()
      expect(block.goto(3).number).to.equal("3")
      expect(block.goto(3).parent.number).to.equal("2-3")
    it "can add line numbers to a block with no line numbers", ->
      block = bp.parse INPUT
      ln.addNumbers block
      expect(block.goto(3).number).to.equal(INPUT_LIST[2])
    it "removes line numbers from line.content", ->
      block = bp.parse INPUT
      ln.addNumbers block
      expect(block.goto(3).content).to.equal('')
    it "throws on duplicate line numbers", ->
      block = bp.parse "1.\n 2.\n 1."
      expect( -> ln.addNumbers block ).to.throw(Error)
    