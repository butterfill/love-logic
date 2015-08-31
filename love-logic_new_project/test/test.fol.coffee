chai = require('chai')
assert = chai.assert
expect = chai.expect
fol = require('../fol')
util = require('../util')

# Below we are going to want to compare components of an expression with
# the result of parsing just that expression, as in:
#   `assert.deepEqual fol.parse("A and B").left, fol.parse("A")`
# The problem is that `fol.parse` returns location information which will differ.
# This function deletes the location information.
# So we can get around the above by doing:
#   `assert.deepEqual util.delExtraneousProperties(fol.parse("A and B").left), util.delExtraneousProperties(fol.parse("A"))`
#


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
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse "A")
      assert.deepEqual util.delExtraneousProperties(res.right), util.delExtraneousProperties(fol.parse "B")
      
    it 'should parse "A & B"', ->
      res = fol.parse("A & B")
      assert.equal res.type, "and"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse "A")
      assert.deepEqual util.delExtraneousProperties(res.right), util.delExtraneousProperties(fol.parse "B")
      
    it 'should parse "not not P1"', ->
      res = fol.parse("not not P1")
      assert.equal res.type, "not"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse "not P1")
      assert.equal res.right, null

    it 'should parse "not A & B" so that & has widest scope', ->
      res = fol.parse("not A & B")
      assert.equal res.type, "and"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse "not A")
      assert.deepEqual util.delExtraneousProperties(res.right), util.delExtraneousProperties(fol.parse "B")

    it 'should parse "A & not B" so that & has widest scope', ->
      res = fol.parse("A & not B")
      assert.equal res.type, "and"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse "A")
      assert.deepEqual util.delExtraneousProperties(res.right), util.delExtraneousProperties(fol.parse "not B")

    it 'should parse "A arrow B"', ->
      res = fol.parse("A arrow B")
      assert.equal res.type, "arrow"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse "A")
      assert.deepEqual util.delExtraneousProperties(res.right), util.delExtraneousProperties(fol.parse "B")
      
    it 'should parse "A → B"', ->
      result = fol.parse("A → B")
      expectedResult = fol.parse("A arrow B")
      expect( util.areIdenticalExpressions(result,expectedResult) ).to.be.true

    it 'should record the symbols used in "A → B" and "A arrow B"', ->
      result1 = fol.parse("A → B")
      result2 = fol.parse("A arrow B")
      expect(result1.symbol).to.equal('→')
      expect(result2.symbol).to.equal('arrow')
      expect( util.areIdenticalExpressions(result1,result2) ).to.be.true

    it 'should parse "A ↔ B"', ->
      result = fol.parse("A ↔ B")
      expect(result.type).to.equal('double_arrow')
      expectedLeft = fol.parse('A')
      expectedRight = fol.parse('B')
      expect( util.areIdenticalExpressions(result.left,expectedLeft) ).to.be.true
      expect( util.areIdenticalExpressions(result.right,expectedRight) ).to.be.true
      
    it '"A arrow B arrow C" should throw', ->
      expect( -> fol.parse "A arrow B arrow C").to.throw()
      
    it 'should parse "A arrow B and C" so that arrow has widest scope', ->
      res = fol.parse("A arrow B and C")
      assert.equal res.type, "arrow"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse "A")
      assert.deepEqual util.delExtraneousProperties(res.right), util.delExtraneousProperties(fol.parse "B and C")

    it 'should parse "true and (A arrow false)"', ->
      res = fol.parse("true and (A arrow false)")
      assert.equal res.type, "and"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse "true")
      assert.deepEqual util.delExtraneousProperties(res.right), util.delExtraneousProperties(fol.parse "A arrow false")


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
      assert.equal res.termlist[0].name, 'x' 
      
    it 'should parse  "F(x) [i.e. single letter predicates]"', ->
      res = fol.parse("F(x)")
      assert.equal res.type, "predicate"
      assert.equal res.name, "F"
      assert.equal res.termlist.length, 1
      assert.equal res.termlist[0].type, 'variable' 
      assert.equal res.termlist[0].name, 'x' 
      
    it 'should parse  "R(x,y,z)", i.e. three-place predicates', ->
      res = fol.parse("R(x,y,z)")
      assert.equal res.type, "predicate"
      assert.equal res.name, "R"
      assert.equal res.termlist.length, 3
      assert.equal res.termlist[1].type, 'variable' 
      assert.equal res.termlist[1].name, 'y' 

    it 'should parse "Fish(a) and LeftOf(a,b)"', ->
      res = fol.parse("Fish(a) and LeftOf(a,b)")
      assert.equal res.type, 'and'
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse("Fish(a)"))
      assert.deepEqual util.delExtraneousProperties(res.right), util.delExtraneousProperties(fol.parse("LeftOf(a,b)"))


  describe 'parse (identity)', ->
    it 'should parse  "a=b"', ->
      res = fol.parse("a=b")
      res = util.delExtraneousProperties(res)
      expect(res.type).to.equal('identity')
      expect(res.termlist[0]).to.deep.equal({type:'name',name:'a'})
      expect(res.termlist[1]).to.deep.equal({type:'name',name:'b'})
      
    it 'should parse  "x=b"', ->
      res = fol.parse("x=b")
      res = util.delExtraneousProperties(res)
      expect(res.type).to.equal('identity')
      expect(res.termlist[0]).to.deep.equal({type:'variable',name:'x'})
      expect(res.termlist[1]).to.deep.equal({type:'name',name:'b'})

    it 'should parse  "not a=b"', ->
      res = fol.parse("not a=b")
      res = util.delExtraneousProperties(res)
      left = util.delExtraneousProperties(fol.parse("a=b"))
      expect(res.type).to.equal('not')
      expect(res.left).to.deep.equal(left)
      expect(res.right).to.be.null

    it 'should parse  "all x ( F(x) arrow x=a )"', ->
      res = fol.parse("all x ( F(x) arrow x=a )")
      res = util.delExtraneousProperties(res)
      expect(res.type).to.equal('universal_quantifier')
      left = util.delExtraneousProperties(fol.parse("F(x) arrow x=a"))
      expect(res.left).to.deep.equal(left)
      expect(res.right).to.be.null
      # 
      # right = util.delExtraneousProperties(fol.parse("b"))


  describe 'parse (quantifiers)', ->
    it 'should parse  "exists(x) Fish(x)"', ->
      res = fol.parse("exists(x) Fish(x)")
      assert.equal res.type, "existential_quantifier"
      assert.equal res.variable.name, "x"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse("Fish(x)"))
      assert.equal res.right, null

    it 'should parse  "(exists x) Fish(x)" [alternative notation]', ->
      res = fol.parse("(exists x) Fish(x)")
      res = util.delExtraneousProperties(res)
      variant = util.delExtraneousProperties fol.parse("exists(x) Fish(x)")
      expect(res).to.deep.equal(variant)

    it 'should parse  "exists x Fish(x)" [alternative notation]', ->
      res = fol.parse("exists x Fish(x)")
      res = util.delExtraneousProperties(res)
      variant = util.delExtraneousProperties fol.parse("exists(x) Fish(x)")
      expect(res).to.deep.equal(variant)
      
    it 'should parse  "all(y) Why(y)"', ->
      res = fol.parse("all(y) Why(y)")
      assert.equal res.type, "universal_quantifier"
      assert.equal res.variable.name, "y"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse("Why(y)"))
      assert.equal res.right, null

    it 'should parse  "(all y) Why(y)" [alternative notation]', ->
      res = fol.parse("(all y) Why(y)")
      res = util.delExtraneousProperties(res)
      variant = util.delExtraneousProperties fol.parse("all(y) Why(y)")
      expect(res).to.deep.equal(variant)

    it 'should parse  "all y Why(y)" [alternative notation]', ->
      res = fol.parse("all y Why(y)")
      res = util.delExtraneousProperties(res)
      variant = util.delExtraneousProperties fol.parse("all(y) Why(y)")
      expect(res).to.deep.equal(variant)

    it 'should parse  "all(y) Fish(y) and Daughter(a)" so that and has widest scope', ->
      res = fol.parse("all(y) Fish(y) and Daughter(a)")
      assert.equal res.type, "and"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse("all(y) Fish(y)"))
      assert.deepEqual util.delExtraneousProperties(res.right), util.delExtraneousProperties(fol.parse("Daughter(a)"))

    it 'should parse  "all(y) exists(x) ( Loves(x,y) )"', ->
      res = fol.parse("all(y) exists(x) ( Loves(x,y) )")
      assert.equal res.type, "universal_quantifier"
      assert.equal res.variable.name, "y"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse("exists(x) ( Loves(x,y) )"))
      assert.equal res.right, null
    
    it 'should parse  "not all(y) exists(x) ( Loves(x,y) )"', ->
      res = fol.parse("not all(y) exists(x) ( Loves(x,y) )")
      assert.equal res.type, "not"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse("all(y) exists(x) ( Loves(x,y) )"))
      assert.equal res.right, null

    it 'should parse  "¬∀x∀y Loves(x,y)"', ->
      result = fol.parse "¬∀x∀y Loves(x,y)"
      expect(result.type).to.equal('not')
      expect(result.left.type).to.equal('universal_quantifier')
      expect(result.left.variable.name).to.equal('x')
      expect(result.right).to.equal(null)
      expect(result.left.left.type).to.equal('universal_quantifier')
      expect(result.left.left.variable.name).to.equal('y')
      expect(result.left.right).to.equal(null)


  describe 'parse (expression variables and term metavariables)', ->
    it 'should parse  "φ"', ->
      res = fol.parse("φ")
      expect(res.type).to.equal("expression_variable")
      expect(res.letter).to.equal("φ")
    it 'should parse  "φ1"', ->
      res = fol.parse("φ1")
      expect(res.type).to.equal("expression_variable")
      expect(res.letter).to.equal("φ1")
    it 'should parse  "φ and ψ1"', ->
      res = fol.parse("φ and ψ1")
      expect(res.type).to.equal("and")
      res = util.delExtraneousProperties(res)
      left = util.delExtraneousProperties(fol.parse("φ"))
      right = util.delExtraneousProperties(fol.parse("ψ1"))
      expect(res.left).to.deep.equal(left)
      expect(res.right).to.deep.equal(right)
    it 'should parse  "a=τ"', ->
      result = fol.parse("a=τ")
      expect(result.type).to.equal("identity")
      expect(result.termlist[1].type).to.equal('term_metavariable')
      expect(result.termlist[1].name).to.equal('τ')
    it 'should parse  "τ1=τ3"', ->
      result = fol.parse("τ1=τ3")
      expect(result.termlist[0].name).to.equal('τ1')
      expect(result.termlist[1].name).to.equal('τ3')
    it 'should parse  "Loves(α,β)"', ->
      result = fol.parse("Loves(α,β)")
      expect(result.type).to.equal("predicate")
      expect(result.name).to.equal("Loves")
      expect(result.termlist[0].name).to.equal('α')
      expect(result.termlist[1].name).to.equal('β')
      
    
    
    
