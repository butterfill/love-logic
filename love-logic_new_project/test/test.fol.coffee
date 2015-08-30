chai = require('chai')
assert = chai.assert
expect = chai.expect
fol = require('../fol')

# Below we are going to want to compare components of an expression with
# the result of parsing just that expression, as in:
#   `assert.deepEqual fol.parse("A and B").left, fol.parse("A")`
# The problem is that `fol.parse` returns location information which will differ.
# This function deletes the location information.
# So we can get around the above by doing:
#   `assert.deepEqual delLocation(fol.parse("A and B").left), delLocation(fol.parse("A"))`
#
delLocation = (expression) ->
  delete expression.location if expression?.location
  delLocation(expression.left) if expression?.left
  delLocation(expression.right) if expression?.right
  

describe 'fol', ->
  describe 'parse', ->
    it 'should parse sentence  "true"', ->
      res = fol.parse("true")
      assert.equal res.type, "value"
      assert.equal res.value, true
      
    it 'should parse sentence letter "A"', ->
      res = fol.parse("A")
      assert.equal res.type, "sentence_letter"
      assert.equal res.letter, "A"
      
    it 'should parse sentence letter "P2"', ->
      res = fol.parse("P2")
      assert.equal res.type, "sentence_letter"
      assert.equal res.letter, "P2"
      
    it 'should parse "A and B"', ->
      res = fol.parse("A and B")
      assert.equal res.type, "and"
      assert.deepEqual delLocation(res.left), delLocation(fol.parse "A")
      assert.deepEqual delLocation(res.right), delLocation(fol.parse "B")
      
    it 'should parse "A & B"', ->
      res = fol.parse("A & B")
      assert.equal res.type, "and"
      assert.deepEqual delLocation(res.left), delLocation(fol.parse "A")
      assert.deepEqual delLocation(res.right), delLocation(fol.parse "B")
      
    it 'should parse "not not P1"', ->
      res = fol.parse("not not P1")
      assert.equal res.type, "not"
      assert.deepEqual delLocation(res.left), delLocation(fol.parse "not P1")
      assert.equal res.right, null

    it 'should parse "not A & B" so that & has widest scope', ->
      res = fol.parse("not A & B")
      assert.equal res.type, "and"
      assert.deepEqual delLocation(res.left), delLocation(fol.parse "not A")
      assert.deepEqual delLocation(res.right), delLocation(fol.parse "B")

    it 'should parse "A & not B" so that & has widest scope', ->
      res = fol.parse("A & not B")
      assert.equal res.type, "and"
      assert.deepEqual delLocation(res.left), delLocation(fol.parse "A")
      assert.deepEqual delLocation(res.right), delLocation(fol.parse "not B")

    it 'should parse "A arrow B"', ->
      res = fol.parse("A arrow B")
      assert.equal res.type, "arrow"
      assert.deepEqual delLocation(res.left), delLocation(fol.parse "A")
      assert.deepEqual delLocation(res.right), delLocation(fol.parse "B")
      
    it '"A arrow B arrow C" should throw', ->
      expect( -> fol.parse "A arrow B arrow C").to.throw()
      
    it 'should parse "A arrow B and C" so that arrow has widest scope', ->
      res = fol.parse("A arrow B and C")
      assert.equal res.type, "arrow"
      assert.deepEqual delLocation(res.left), delLocation(fol.parse "A")
      assert.deepEqual delLocation(res.right), delLocation(fol.parse "B and C")

    it 'should parse "true and (A arrow false)"', ->
      res = fol.parse("true and (A arrow false)")
      assert.equal res.type, "and"
      assert.deepEqual delLocation(res.left), delLocation(fol.parse "true")
      assert.deepEqual delLocation(res.right), delLocation(fol.parse "A arrow false")


describe 'fol', ->
  describe 'parse (predicates)', ->
    it 'should parse  "Fish(a)"', ->
      res = fol.parse("Fish(a)")
      assert.equal res.type, "predicate"
      assert.equal res.name, "Fish"
      assert.equal res.termlist.length, 1
      assert.equal res.termlist[0].type, 'name' 
      assert.equal res.termlist[0].name, 'a' 
      
    it 'should parse  "Fish(x)"', ->
      res = fol.parse("Fish(x)")
      assert.equal res.type, "predicate"
      assert.equal res.name, "Fish"
      assert.equal res.termlist.length, 1
      assert.equal res.termlist[0].type, 'variable' 
      assert.equal res.termlist[0].variable_name, 'x' 
      
    it 'should parse  "F(x) [i.e. single letter predicates]"', ->
      res = fol.parse("F(x)")
      assert.equal res.type, "predicate"
      assert.equal res.name, "F"
      assert.equal res.termlist.length, 1
      assert.equal res.termlist[0].type, 'variable' 
      assert.equal res.termlist[0].variable_name, 'x' 
      
    it 'should parse  "R(x,y,z)", i.e. three-place predicates', ->
      res = fol.parse("R(x,y,z)")
      assert.equal res.type, "predicate"
      assert.equal res.name, "R"
      assert.equal res.termlist.length, 3
      assert.equal res.termlist[1].type, 'variable' 
      assert.equal res.termlist[1].variable_name, 'y' 

    it 'should parse "Fish(a) and LeftOf(a,b)"', ->
      res = fol.parse("Fish(a) and LeftOf(a,b)")
      assert.equal res.type, 'and'
      assert.deepEqual delLocation(res.left), delLocation(fol.parse("Fish(a)"))
      assert.deepEqual delLocation(res.right), delLocation(fol.parse("LeftOf(a,b)"))
      

describe 'fol', ->
  describe 'parse (quantifiers)', ->
    it 'should parse  "exists(x) Fish(x)"', ->
      res = fol.parse("exists(x) Fish(x)")
      assert.equal res.type, "existential_quantifier"
      assert.equal res.variable.variable_name, "x"
      assert.deepEqual delLocation(res.left), delLocation(fol.parse("Fish(x)"))
      assert.equal res.right, null
      
    it 'should parse  "all(y) Why(y)"', ->
      res = fol.parse("all(y) Why(y)")
      assert.equal res.type, "universal_quantifier"
      assert.equal res.variable.variable_name, "y"
      assert.deepEqual delLocation(res.left), delLocation(fol.parse("Why(y)"))
      assert.equal res.right, null

    it 'should parse  "all(y) Fish(y) and Daughter(a)" so that and has widest scope', ->
      res = fol.parse("all(y) Fish(y) and Daughter(a)")
      assert.equal res.type, "and"
      assert.deepEqual delLocation(res.left), delLocation(fol.parse("all(y) Fish(y)"))
      assert.deepEqual delLocation(res.right), delLocation(fol.parse("Daughter(a)"))

    it 'should parse  "all(y) exists(x) ( Loves(x,y) )"', ->
      res = fol.parse("all(y) exists(x) ( Loves(x,y) )")
      assert.equal res.type, "universal_quantifier"
      assert.equal res.variable.variable_name, "y"
      assert.deepEqual delLocation(res.left), delLocation(fol.parse("exists(x) ( Loves(x,y) )"))
      assert.equal res.right, null
    
    it 'should parse  "not all(y) exists(x) ( Loves(x,y) )"', ->
      res = fol.parse("not all(y) exists(x) ( Loves(x,y) )")
      assert.equal res.type, "not"
      assert.deepEqual delLocation(res.left), delLocation(fol.parse("all(y) exists(x) ( Loves(x,y) )"))
      assert.equal res.right, null
    
    
    
