_ = require 'lodash'

chai = require('chai')
assert = chai.assert
expect = chai.expect
should = chai.should()

util = require '../util'
fol = require '../fol'

describe "`fol`", ->
  describe "`_decorate`", ->
    it "adds a `.toString` method that works", ->
      text = 'A ∧ B'
      e = fol.parse text
      result = e.toString()
      expect(result).to.equal(text)
    it "adds a `.toString` method to components of an expression", ->
      e = fol.parse 'A and B'
      result = e.right.toString()
      expect(result).to.equal("B")
    it "adds a `.isIdenticalTo` method that works", ->
      e = fol.parse 'A and (B or C)'
      result = e.right.isIdenticalTo fol.parse("B or C")
      expect(result).to.be.true
    it "adds `.delExtraneousProperties`", ->
      e = fol.parse 'all x (F(x) arrow G(x))'
      e2 = fol.parse 'all x (F(x) arrow G(x))'
      (x.delExtraneousProperties() for x in [e,e2])
      expect(e).to.deep.equal(e2)
    it "adds `.clone`", ->
      e = fol.parse 'exists x F(x)'
      e2 = e.clone()
      (x.delExtraneousProperties?() for x in [e,e2])
      expect(e).not.to.equal(e2)
      expect(e).to.deep.equal(e2)
      
    it "works when there are multiple expressions", ->
      text = 'A and B'
      text2 = 'C or D'
      e = fol.parse text
      expect(e.symbol).to.equal('and')
      # console.log util.expressionToString(e)
      e2 = fol.parse text2
      result = e.toString({replaceSymbols:false})
      result2 = e2.toString({replaceSymbols:false})
      expect(result).to.equal(text)
      expect(result2).to.equal(text2)

    it "adds `.findMatches`", ->
      e = fol.parse '[α]'
      matches = 
        α : (fol.parse 'F(a)').termlist[0]
      e = e.applyMatches(matches)
      expect(e.toString()).to.equal('[a]')
        
      
    it "adds `.applySubstitutions`"
    
    it "provides a method `getNames`", ->
      e = fol.parse "F(a) and b=c"
      n = e.getNames()
      expect('a' in n).to.be.true
      expect('b' in n).to.be.true
      expect('c' in n).to.be.true
      expect(n.length).to.equal(3)
    it "`getNames` returns [] if there are no names", ->
      e = fol.parse "F(x) and y=x"
      n = e.getNames()
      expect(n.length).to.equal(0)

    it "provides a method `getSentenceLetters`", ->
      e = fol.parse "A and not (not B or C)"
      n = e.getSentenceLetters()
      expect('A' in n).to.be.true
      expect('B' in n).to.be.true
      expect('C' in n).to.be.true
      expect(n.length).to.equal(3)
      
    it "`getSentenceLetters` returns [] if there are no sentence letters", ->
      e = fol.parse "F(a) and y=x"
      n = e.getSentenceLetters()
      expect(n.length).to.equal(0)

  describe ".getFreeVariableNames()", ->
    it "returns the names of free variables in an expression", ->
      e = fol.parse "( (∃x ∃y ∃z Fish(x) ∧ Between(y,x,z) ) ∧ Person(y) ) ∧ Person(z)"
      fv = e.getFreeVariableNames()
      expect(fv.length).to.equal(3)
      expect('x' in fv).to.be.true
      expect('y' in fv).to.be.true
      expect('z' in fv).to.be.true
    it "returns the names of free variables in an expression (another example)", ->
      e = fol.parse "( (∃x ∃y ∃z Fish(x) ) ∧ Person(y) ) ∧ Person(z)"
      fv = e.getFreeVariableNames()
      expect(fv.length).to.equal(2)
      expect('x' in fv).to.be.false
      expect('y' in fv).to.be.true
      expect('z' in fv).to.be.true
    it "returns an empty list if there are no free variables in  an expression", ->
      e = fol.parse "∃x ∃y ∃z (( (Fish(x) ∧ Between(y,x,z) ) ∧ Person(y) ) ∧ Person(z))"
      fv = e.getFreeVariableNames()
      expect(fv.length).to.equal(0)
    it "returns an empty list if there are no variables in  an expression", ->
      e = fol.parse "A and B"
      fv = e.getFreeVariableNames()
      expect(fv.length).to.equal(0)
  
  describe ".getPredicates()", ->
    it "gets predicates from F(a,b)", ->
      e = fol.parse "F(a,b)"
      p = e.getPredicates()
      expect(p.length).to.equal(1)
      expect(p[0].name).to.equal 'F'
      expect(p[0].arity).to.equal 2
    it "gets predicates from all x (F(x,b) arrow exists y Garage(x,y,z))", ->
      e = fol.parse "all x (F(x,b) arrow exists y Garage(x,y,z))"
      p = e.getPredicates()
      expect(p.length).to.equal(2)
      expect(p[0].name).to.equal 'F'
      expect(p[0].arity).to.equal 2
      expect(p[1].name).to.equal 'Garage'
      expect(p[1].arity).to.equal 3
    it "gets predicates from (A and F(b))", ->
      e = fol.parse " (A and F(b))"
      p = e.getPredicates()
      expect(p.length).to.equal(1)
      expect(p[0].name).to.equal 'F'
      expect(p[0].arity).to.equal 1
    it "gets unique predicates from (F(a) and F(b))", ->
      e = fol.parse " (F(a) and F(b))"
      p = e.getPredicates()
      expect(p.length).to.equal(1)
      expect(p[0].name).to.equal 'F'
      expect(p[0].arity).to.equal 1
    it "gets recognises predicates of different arities as different", ->
      e = fol.parse " (F(a) and F(b,c))"
      p = e.getPredicates()
      expect(p.length).to.equal(2)
      expect(p[0].name).to.equal 'F'
      expect(p[0].arity).to.equal 1
      expect(p[1].name).to.equal 'F'
      expect(p[1].arity).to.equal 2

  describe ".getAllSubstitutionInstances", ->
    it "works with one name", ->
      e = fol.parse "F(b)[b-->a]"
      res = e.getAllSubstitutionInstances()
      strings = (x.toString({replaceSymbols:true}) for x in res)
      console.log strings
      (res.length is 2).should.be.true
      ('F(a)' in strings).should.be.true
      ('F(b)' in strings).should.be.true
    it "works with two names", ->
      e = fol.parse "F(a,a)[a-->b]"
      res = e.getAllSubstitutionInstances()
      strings = (x.toString({replaceSymbols:true}) for x in res)
      console.log strings
      (res.length is 4).should.be.true
      ('F(a,a)' in strings).should.be.true
      ('F(b,a)' in strings).should.be.true
      ('F(a,b)' in strings).should.be.true
      ('F(b,b)' in strings).should.be.true
            