chai = require('chai')
assert = chai.assert
expect = chai.expect
fol_parser = require('../fol')


describe 'fol_parser', ->
  describe 'parse', ->
    it 'should parse sentence letter "A"', ->
      assert.deepEqual fol_parser.parse("A"), [  'PROP', 'A' ] 
    it 'should parse sentence letter "P2"', ->
      assert.deepEqual fol_parser.parse("P2"), [  'PROP', 'P2' ] 
    it 'should parse "A and B"', ->
      assert.deepEqual fol_parser.parse("A and B"), [ 'and',  [ 'PROP', 'A' ],  [ 'PROP', 'B' ] ]
    it 'should parse "A & B"', ->
      assert.deepEqual fol_parser.parse("A & B"), [ 'and',  [ 'PROP', 'A' ],  [ 'PROP', 'B' ] ]
    it 'should parse "A and B" (2)', ->
      expect(fol_parser.parse "A and B").to.not.deep.equal([ 'and',  [ 'PROP', 'B' ],  [ 'PROP', 'A' ] ])
    it 'should parse "A arrow B"', ->
      expect( fol_parser.parse "A arrow B").to.deep.equal [ 'arrow',  [ 'PROP', 'A' ],  [ 'PROP', 'B' ] ]
    it '"A arrow B arrow C" should throw', ->
      expect( -> fol_parser.parse "A arrow B arrow C").to.throw()
    it 'should parse "true and (A arrow false)"', ->
      expect( fol_parser.parse "true and (A arrow false)").to.deep.equal [ 'and', [ 'VAL', true ], [ 'arrow', [ 'PROP', 'A' ], [ 'VAL', false ] ] ]
    it 'should parse "not not P1"', ->
      expect( fol_parser.parse "not not P1").to.deep.equal [ 'not', [ 'not', [ 'PROP', 'P1' ] ] ]

describe 'fol_parser', ->
  describe 'parse (predicates)', ->
    it 'should parse  "Fish(a)"', ->
      assert.deepEqual fol_parser.parse("Fish(a)"), [  'PRED', 'Fish', [['NAME', 'a']] ] 
    it 'should parse  "Fish(x)"', ->
      assert.deepEqual fol_parser.parse("Fish(x)"), [  'PRED', 'Fish', [['VARIABLE', 'x']] ] 
    it 'should parse  "F(x) [i.e. single letter predicates]"', ->
      assert.deepEqual fol_parser.parse("F(x)"), [  'PRED', 'F', [['VARIABLE', 'x']] ] 
    it 'should parse  "R(x,y,z) [i.e. three-place predicates]"', ->
      assert.deepEqual fol_parser.parse("R(x,y,z)"), [  'PRED', 'R', [['VARIABLE', 'x'],['VARIABLE', 'y'],['VARIABLE', 'z']] ] 
    it 'should parse "Fish(a) and LeftOf(a,b)"', ->
      assert.deepEqual fol_parser.parse("Fish(a) and LeftOf(a,b)"), [ 'and', [ 'PRED', 'Fish', [ ['NAME','a'] ] ], [ 'PRED','LeftOf',[ ['NAME','a'], ['NAME','b'] ] ] ]
      






    # todo: next step
    # it 'should parse "Square(a)"', ->
    #   expect( fol_parser.parse "Square(a)").to.deep.equal [ 'predicate', 'Square', [ 'name', 'a' ]]