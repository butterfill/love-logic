chai = require('chai')
assert = chai.assert
expect = chai.expect

fol = require '../tellerFOL'
util = require '../../util'

# Below we are going to want to compare components of an expression with
# the result of parsing just that expression, as in:
#   `assert.deepEqual fol.parse("A and B").left, fol.parse("A")`
# The problem is that `fol.parse` returns location information which will differ.
# This function deletes the location information.
# So we can get around the above by doing:
#   `assert.deepEqual util.delExtraneousProperties(fol.parse("A and B").left), util.delExtraneousProperties(fol.parse("A"))`
#


describe 'tellerFOL', ->
  describe 'parse', ->
    it 'should parse sentence letter "A"', ->
      res = fol.parse("A")
      assert.equal res.type, "sentence_letter"
      assert.equal res.letter, "A"

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

    it '"A arrow B arrow C" should throw', ->
      expect( -> fol.parse "A arrow B arrow C").to.throw
            
    it 'should parse "A arrow B and C" so that arrow has widest scope', ->
      res = fol.parse("A arrow B and C")
      assert.equal res.type, "arrow"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse "A")
      assert.deepEqual util.delExtraneousProperties(res.right), util.delExtraneousProperties(fol.parse "B and C")

  describe 'parse (predicates)', ->
    it 'should parse  "Fa"', ->
      res = fol.parse("Fa")
      assert.equal res.type, "predicate"
      assert.equal res.name, "F"
      assert.equal res.termlist.length, 1
      assert.equal res.termlist[0].type, 'name' 
      assert.equal res.termlist[0].name, 'a' 
      
    it 'should parse  "Fx"', ->
      res = fol.parse("Fx")
      assert.equal res.type, "predicate"
      assert.equal res.name, "F"
      assert.equal res.termlist.length, 1
      assert.equal res.termlist[0].type, 'variable' 
      assert.equal res.termlist[0].name, 'x' 
      
    it 'should parse  "Rxyz", i.e. three-place predicates', ->
      res = fol.parse("Rxyz")
      assert.equal res.type, "predicate"
      assert.equal res.name, "R"
      assert.equal res.termlist.length, 3
      assert.equal res.termlist[1].type, 'variable' 
      assert.equal res.termlist[1].name, 'y' 

    it 'should parse "Fa and Lab"', ->
      res = fol.parse("Fa and Lab")
      assert.equal res.type, 'and'
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse("Fa"))
      assert.deepEqual util.delExtraneousProperties(res.right), util.delExtraneousProperties(fol.parse("Lab"))


  describe 'parse (distinguishing predicates from sentence variables)', ->
    it "should identify Rab as a predicate", ->
      result = fol.parse "Rab"
      expect(result.type).to.equal("predicate")
      
    it "should identify R as a sentence variable", ->
      result = fol.parse "R"
      expect(result.type).to.equal("sentence_letter")
      
    it "should deal with 'R and Ra'", ->
      result = fol.parse "R and Ra"
      expect(result.left.type).to.equal("sentence_letter")
      expect(result.right.type).to.equal("predicate")


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

    it 'should parse  "(all x) ( Fx arrow x=a )"', ->
      res = fol.parse("(all x) ( Fx arrow x=a )")
      res = util.delExtraneousProperties(res)
      expect(res.type).to.equal('universal_quantifier')
      left = util.delExtraneousProperties(fol.parse("Fx arrow x=a"))
      expect(res.left).to.deep.equal(left)
      expect(res.right).to.be.null
      # 
      # right = util.delExtraneousProperties(fol.parse("b"))


  describe 'parse (quantifiers)', ->
    it 'should parse  "(exists x) Fx"', ->
      res = fol.parse("(exists x) Fx")
      res = util.delExtraneousProperties(res)
      variant = util.delExtraneousProperties fol.parse("(exists x) Fx")
      expect(res).to.deep.equal(variant)

    it 'should parse  "(all y) Wy"', ->
      res = fol.parse("(all y) Wy")
      res = util.delExtraneousProperties(res)
      variant = util.delExtraneousProperties fol.parse("(all y) Wy")
      expect(res).to.deep.equal(variant)

    it 'should parse  "(all y) Fy and Da" so that and has widest scope', ->
      res = fol.parse("(all y) Fy and Da")
      assert.equal res.type, "and"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse("(all y) Fy"))
      assert.deepEqual util.delExtraneousProperties(res.right), util.delExtraneousProperties(fol.parse("Da"))

    it 'should parse  "(all y) (exists x) ( Lxy )"', ->
      res = fol.parse("(all y) (exists x) ( Lxy )")
      assert.equal res.type, "universal_quantifier"
      assert.equal res.boundVariable.name, "y"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse("(exists x) ( Lxy )"))
      assert.equal res.right, null
    
    it 'should parse  "not (all y) (exists x) ( Lxy )"', ->
      res = fol.parse("not (all y) (exists x) ( Lxy )")
      assert.equal res.type, "not"
      assert.deepEqual util.delExtraneousProperties(res.left), util.delExtraneousProperties(fol.parse("(all y) (exists x) ( Lxy )"))
      assert.equal res.right, null

    it 'should parse  "¬(∀x)(∀y) Lxy"', ->
      result = fol.parse "¬(∀x)(∀y) Lxy"
      expect(result.type).to.equal('not')
      expect(result.left.type).to.equal('universal_quantifier')
      expect(result.left.boundVariable.name).to.equal('x')
      expect(result.right).to.equal(null)
      expect(result.left.left.type).to.equal('universal_quantifier')
      expect(result.left.left.boundVariable.name).to.equal('y')
      expect(result.left.right).to.equal(null)

  describe 'square brackets in expressions', ->
    it "allows square brackets around expressions are ok, eg `(all x)[Cx arrow (Lcx or Lex)]`", ->
      e = fol.parse("(all x)[Cx arrow (Lcx or Lex)]")
      expect(e.left.type).to.equal('arrow')

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
    it 'should parse  "Lαβ"', ->
      result = fol.parse("Lαβ")
      expect(result.type).to.equal("predicate")
      expect(result.name).to.equal("L")
      expect(result.termlist[0].name).to.equal('α')
      expect(result.termlist[1].name).to.equal('β')
      
  describe "parse (don't interfere with assumptions needed elsewhere)", ->
    it "should not recognise xx1 as a variable in predicates", ->
      expect(-> fol.parse "Fxx1").to.throw
    it "should not recognise xx1 as a variable in quantifier expressions", ->
      expect(-> fol.parse "(all xx1) P").to.throw
    
  describe "boxes at the start of expressions", ->
    it "recognises boxes", ->
      result = fol.parse("Fa")
      expect(result.box?).to.be.false
      result = fol.parse("[a] Fa")
      expect(result.box?).to.be.true
      
    it "recognises boxes with term metavariables", ->
      result = fol.parse("[τ] Fa")
      expect(result.box?).to.be.true
      
    it "records what is in the box (for names)", ->
      result = fol.parse("[a] Fa")
      console.log "#{JSON.stringify result.box, null, 4}"
      expect(result.box.term.type).to.equal('name')
      expect(result.box.term.name).to.equal('a')

    it "records what is in the box (for τ)", ->
      result = fol.parse("[τ] Fa")
      expect(result.box.term.type).to.equal('term_metavariable')
      expect(result.box.term.name).to.equal('τ')

    it "adding a box should not change how an expression is parsed", ->
      noBox = fol.parse("(exists x) (Fa and Fx)")
      expect(noBox.box?).to.be.false
      withBox = fol.parse("[a] (exists x) (Fa and Fx)")
      expect(withBox.box?).to.be.true
      delete withBox.box
      util.delExtraneousProperties noBox
      util.delExtraneousProperties withBox
      expect(noBox).to.deep.equal(withBox)
    
    it "allows an expression to consist of just a box", ->
      onlyBox = fol.parse '[a]'
      expect(onlyBox.type).to.equal('box')
      

      
  describe "substitutions like φ[τ-->α]", ->
    it "recognises substitutions for terms", ->
      noSub = fol.parse("φ")
      expect(noSub.substitutions?).to.be.false
      withSub = fol.parse("φ[τ-->a]")
      expect(withSub.substitutions?).to.be.true
    it "each substitution has type set to 'substitution'", ->
      withSub = fol.parse("φ[τ-->a]")
      expect(withSub.substitutions[0].type).to.equal('substitution')
    it "each substitution has `.from` and `.to` properties", ->
      withSub = fol.parse("φ[τ-->a]")
      expect(withSub.substitutions[0].from?).to.be.true
      expect(withSub.substitutions[0].to?).to.be.true
    it "recognises substitutions for expressions", ->
      withSub = fol.parse("(A and φ)[φ-->B and C]")
      expect(withSub.substitutions?).to.be.true
    it "recognises substitutions for `sentence_letter`s", ->
      withSub = fol.parse("(A and B)[A-->B and C]")
      expect(withSub.substitutions?).to.be.true
    it "recognises multiple substitutions (alternative comma notation)", ->
      withSub = fol.parse("(φ and ψ)[φ-->B and C,ψ-->A]")
      expect(withSub.substitutions.length).to.equal(2)
      # console.log "\n\n\n.substitutions[0]: #{JSON.stringify withSub,null,4}"
      expect(withSub.substitutions[0].from.letter).to.equal('φ')
      expect(withSub.substitutions[0].to.type).to.equal('and')
      expect(withSub.substitutions[1].from.type).to.equal('expression_variable')
      expect(withSub.substitutions[1].from.letter).to.equal('ψ')
      expect(withSub.substitutions[1].to.type).to.equal('sentence_letter')
      
    it "treats ψ[sub1][sub1] and ψ[sub1,sub2]as equivalent", ->
      toCheck = fol.parse "ψ[φ-->B and C][ψ-->A]"
      expect(toCheck.substitutions.length).to.equal(2)
      expected = fol.parse "ψ[φ-->B and C,ψ-->A]" 
      expect(expected.substitutions.length).to.equal(2)
      util.delExtraneousProperties toCheck
      util.delExtraneousProperties expected
      expect(toCheck).to.deep.equal(expected)
    it "treats ψ[sub1][sub1] (ψ[sub1])[sub2] as equivalent", ->
      toCheck = fol.parse "ψ[φ-->B and C][ψ-->A]"
      expect(toCheck.substitutions.length).to.equal(2)
      expected = fol.parse "(ψ[φ-->B and C])[ψ-->A]"
      expect(expected.substitutions.length).to.equal(2)
      util.delExtraneousProperties toCheck
      util.delExtraneousProperties expected
      expect(toCheck).to.deep.equal(expected)
      
    it "recognises multiple substitutions", ->
      # This test also confirms that 
      #       `(φ and ψ)[φ-->B and C][ψ-->A]`
      # is interpreted as 
      #       `(φ and ψ)([φ-->B and C][ψ-->A])`
      # rather than as 
      #       `((φ and ψ)[φ-->B and C])[ψ-->A]`
      withSub = fol.parse("(φ and ψ)[φ-->B and C][ψ-->A]")
      expect(withSub.substitutions.length).to.equal(2)

    it "records what the substitution is (when substituting terms)", ->
      withSub = fol.parse("φ[τ-->a]")
      theSub = withSub.substitutions[0]
      expect(theSub.from.type).to.equal('term_metavariable')
      expect(theSub.from.name).to.equal('τ')
      expect(theSub.to.type).to.equal('name')
      expect(theSub.to.name).to.equal('a')
    it "records what the substitution is (when substituting expressions)", ->
      withSub = fol.parse("(A and φ)[φ-->B and C]")
      theSub = withSub.substitutions[0]
      expect(theSub.from.type).to.equal('expression_variable')
      expect(theSub.from.letter).to.equal('φ')
      expect(theSub.to.type).to.equal('and')
      # This last one is fragile as it depends on how `util.expressionToString`
      # represents things:
      expect(util.expressionToString(theSub.to)).to.equal('B and C')
    it "treats substitutions as having high precedence", ->
      expression = fol.parse("Fa[a-->α] arrow B[B-->B and C]")
      # console.log "expression: #{JSON.stringify expression,null,4}"
      # console.log "expression.substitutions : #{JSON.stringify expression.substitutions,null,4}"
      # console.log "expression.left.substitutions[0] #{JSON.stringify expression.left.substitutions[0],null,4}"
      # console.log "expression.right.substitutions[0] #{JSON.stringify expression.right.substitutions[0],null,4}"
      expect(expression.substitutions?).to.be.false
      expect(expression.left.substitutions[0].from.type).to.equal("name")
      expect(expression.left.substitutions[0].from.name).to.equal("a")
      expect(expression.right.substitutions[0].from.type).to.equal("sentence_letter")

    it "copes with nested substitutions", ->
      expression = fol.parse("A[A-->B[B-->C]]")
      expect(expression.substitutions.length).to.equal(1)
      expect(expression.substitutions[0].to.substitutions.length).to.equal(1)
      
    it "doesn't overwrite substitutions when brackets are involved",->
      expression = fol.parse "((A and D)[A-->B])[B-->C]"
      expect(expression.substitutions.length).to.equal(2)

  describe "substitutions with null like φ[τ-->null]", ->
    it "recognises term->null", ->
      e = fol.parse("φ[τ-->null]")
      expect(e.substitutions[0].to).to.equal(null)
    it "recognises PROP->null", ->
      e = fol.parse("φ[φ-->null]")
      expect(e.substitutions[0].to).to.equal(null)
      
  describe "hats (for universal intro rule)", ->
    it 'should parse  "Fa^"', ->
      res = fol.parse("Fa^")
      assert.equal res.type, "predicate"
      assert.equal res.name, "F"
      assert.equal res.termlist.length, 1
      assert.equal res.termlist[0].type, 'name_hat' 
      assert.equal res.termlist[0].name, 'a^' 
    it 'should parse  "Ra^b^"', ->
      res = fol.parse("Ra^b^")
      assert.equal res.type, "predicate"
      assert.equal res.name, "R"
      assert.equal res.termlist.length, 2
      assert.equal res.termlist[0].type, 'name_hat' 
      assert.equal res.termlist[0].name, 'a^' 
      assert.equal res.termlist[1].type, 'name_hat' 
      assert.equal res.termlist[1].name, 'b^' 
    it 'should parse  "a^ = b^"', ->
      res = fol.parse("a^ = b^")
      assert.equal res.type, "identity"
      assert.equal res.termlist.length, 2
      assert.equal res.termlist[0].type, 'name_hat' 
      assert.equal res.termlist[0].name, 'a^' 
      assert.equal res.termlist[1].type, 'name_hat' 
      assert.equal res.termlist[1].name, 'b^' 
    it 'should parse  "Fα^"', ->
      res = fol.parse("Fα^")
      assert.equal res.type, "predicate"
      assert.equal res.name, "F"
      assert.equal res.termlist.length, 1
      assert.equal res.termlist[0].type, 'term_metavariable_hat' 
      assert.equal res.termlist[0].name, 'α^' 
    it 'should parse  "φ[τ-->α^]"', ->
      e = fol.parse('φ[τ-->α^]')
      expect(e.substitutions[0].from?).to.be.true
      expect(e.substitutions[0].to?).to.be.true
      assert.equal e.substitutions[0].from.type, 'term_metavariable' 
      assert.equal e.substitutions[0].to.type, 'term_metavariable_hat' 
      
