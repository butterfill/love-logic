# This module exists because the tests for substitute are too many.
# (TODO: split up the substitute module.)

_ = require 'lodash'

chai = require('chai')
assert = chai.assert
expect = chai.expect
substitute = require('../substitute')
fol = require '../parser/awFOL'
util = require('../util')


describe "substitute (module), further tests", ->
  describe "`._addSubToEveryTerm`", ->
    it "adds a (term-)substitution to every term", ->
      e = fol.parse "a=x and F(α)"
      theSub = 
        type : 'substitution'
        from : (fol.parse "F(z)").termlist[0]
        to : (fol.parse "F(c)").termlist[0]
      result = substitute._addSubToEveryTerm e, theSub
      for term in result.left.termlist.concat(result.right.termlist)
        expect(term.substitutions[0].from.name).to.equal('z')
        expect(term.substitutions[0].to.name).to.equal('c')
        expect(term.substitutions.length).to.equal(1)
    it "adds a substitution to bound variables", ->
      e = fol.parse "all x F(x)"
      theSub = 
        type : 'substitution'
        from : (fol.parse "F(x)").termlist[0]
        to : (fol.parse "F(y)").termlist[0]
      result = substitute._addSubToEveryTerm e, theSub
      # console.log "#{util.expressionToString result}"
      expect(result.boundVariable.substitutions[0].from.name).to.equal('x')
      expect(result.boundVariable.substitutions[0].to.name).to.equal('y')
      
  describe "`._moveAllSubsInwards`", ->
    it "moves term subs (like [a->b]) inwards", ->
      e = fol.parse '(c=d)[a->b]'
      e = util.delExtraneousProperties e
      result = substitute._moveAllSubsInwards(e)
      console.log "\te : #{util.expressionToString(e)}"
      console.log "\tresult : #{util.expressionToString(result)}"
      expect(result.substitutions?).to.be.false
      expect(result.termlist[0].substitutions.length).to.equal(1)
      expect(result.termlist[1].substitutions.length).to.equal(1)
    it "moves sentence subs (like [A->B]) inwards", ->
      e = fol.parse '(B and F(x))[A->D]'
      e = util.delExtraneousProperties e
      result = substitute._moveAllSubsInwards(e)
      console.log "\te : #{util.expressionToString(e)}"
      console.log "\tresult : #{util.expressionToString(result)}"
      expect(result.substitutions?).to.be.false
      expect(result.left.substitutions.length).to.equal(1)
      expect(result.right.substitutions.length).to.equal(1)
    it "moves multiple, mixed subs (like [A->B][x->y]) inwards", ->
      e = fol.parse '(a=b and C)[A->B][x->y]'
      e = util.delExtraneousProperties e
      result = substitute._moveAllSubsInwards(e)
      console.log "\te : #{util.expressionToString(e)}"
      console.log "\tresult : #{util.expressionToString(result)}"
      expect(result.substitutions?).to.be.false
      expect(result.left.substitutions.length).to.equal(1)
      expect(result.left.termlist[0].substitutions.length).to.equal(1)
      expect(result.left.termlist[1].substitutions.length).to.equal(1)
      expect(result.right.substitutions.length).to.equal(1)
    it "doesn't mind being used repeatedly", ->
      e = fol.parse '(a=a)[a->b]'
      e = util.delExtraneousProperties e
      result1 = substitute._moveAllSubsInwards(e)
      result2 = substitute._moveAllSubsInwards(result1)
      console.log util.expressionToString(result2)
      expect(result2).to.deep.equal(result1)
    it "does nothing if there are no subs", ->
      e = fol.parse '(a=a)'
      e = util.delExtraneousProperties e
      result = substitute._moveAllSubsInwards(e)
      console.log util.expressionToString(result)
      expect(e).to.deep.equal(result)
    it "preserves the order in which subs were written", ->
      results = []
      e = fol.parse '(F(a) and G(a))[a->b][b->c][c->d][d->e]'
      eFirst = e.substitutions[0].from.name
      eLast = e.substitutions[3].from.name
      result = substitute._moveAllSubsInwards(e)
      rFirstLeft = result.left.termlist[0].substitutions[0].from.name
      rLastLeft = result.left.termlist[0].substitutions[3].from.name
      rFirstRight = result.right.termlist[0].substitutions[0].from.name
      rLastRight = result.right.termlist[0].substitutions[3].from.name
      console.log "from: #{util.expressionToString e} to: #{util.expressionToString result}"
      expect(eFirst).to.equal(rFirstLeft)
      expect(eLast).to.equal(rLastLeft)
      expect(eFirst).to.equal(rFirstRight)
      expect(eLast).to.equal(rLastRight)
      
  
  describe "`.doAfterApplyingSubstitutions", ->
    it "lists possible substitutions for one substitution", ->
      results = []
      e = fol.parse '(a=a)[a->b]'
      process = (e) ->
        results.push(e)
        return undefined
      _ignore = substitute.doAfterApplyingSubstitutions e, process
      results = _.uniq((util.expressionToString(x).replace(/\s/g,'') for x in results)).sort()
      expect(results).to.deep.equal(["a=a","a=b","b=a","b=b"])
    it "lists possible substitutions for one substitution (variant with predicates)", ->
      results = []
      e = fol.parse '(F(a) and G(a))[a->b]'
      process = (e) ->
        results.push(e)
        return undefined
      _ignore = substitute.doAfterApplyingSubstitutions e, process
      console.log "\tresults.length = #{results.length}"
      results = _.uniq((util.expressionToString(x) for x in results)).sort()
      console.log "\t\t\tunique results.length = #{results.length}"
      expect(results).to.deep.equal(["F(a) and G(a)","F(a) and G(b)","F(b) and G(a)","F(b) and G(b)"])
    it "lists possible substitutions for two substitutions", ->
      results = []
      e = fol.parse '(F(a) and G(b))[a->b][b->c]'
      process = (e) ->
        results.push(e)
        # console.log "found #{util.expressionToString e}"
        return undefined
      _ignore = substitute.doAfterApplyingSubstitutions e, process
      expectedResults = ["F(a) and G(b)","F(a) and G(c)","F(b) and G(b)","F(b) and G(c)","F(c) and G(b)","F(c) and G(c)"]
      expectedResults = (util.delExtraneousProperties(fol.parse(x)) for x in expectedResults)
      console.log "\tresults.length = #{results.length}"
      results = _.uniq((util.expressionToString(x) for x in results)).sort()
      console.log "\t\t\tunique results.length = #{results.length}"
      expectedResults = _.uniq((util.expressionToString(x) for x in expectedResults)).sort()
      expect(results).to.deep.equal(expectedResults)
    it "lists possible substitutions for four substitutions", ->
      results = []
      e = fol.parse 'F(a)[a->b][b->c][c->d][d->e]'
      process = (e) ->
        results.push(e)
        return undefined
      _ignore = substitute.doAfterApplyingSubstitutions e, process
      expectedResults = ["F(a)","F(b)","F(c)","F(d)","F(e)"]
      expectedResults = (util.delExtraneousProperties(fol.parse(x)) for x in expectedResults)
      results = _.uniq((util.expressionToString(x) for x in results)).sort()
      expectedResults = _.uniq((util.expressionToString(x) for x in expectedResults)).sort()
      expect(results).to.deep.equal(expectedResults)
    it "lists possible substitutions for four substitutions (different order)", ->
      results = []
      e = fol.parse 'F(a)[a->b][b->c][d->e][c->d]'
      process = (e) ->
        results.push(e)
        return undefined
      _ignore = substitute.doAfterApplyingSubstitutions e, process
      expectedResults = ["F(a)","F(b)","F(c)","F(d)"]
      expectedResults = (util.delExtraneousProperties(fol.parse(x)) for x in expectedResults)
      results = _.uniq((util.expressionToString(x) for x in results)).sort()
      expectedResults = _.uniq((util.expressionToString(x) for x in expectedResults)).sort()
      expect(results).to.deep.equal(expectedResults)
    it "lists possible substitutions for mixed (term and sentence) substitutions", ->
      results = []
      e = fol.parse '(F(a) and A)[a->b][A->B]'
      process = (e) ->
        console.log "found #{util.expressionToString e}"
        results.push(e)
        return undefined
      _ignore = substitute.doAfterApplyingSubstitutions e, process
      expectedResults = ["F(a) and A","F(a) and B","F(b) and A","F(b) and B"]
      expectedResults = (util.delExtraneousProperties(fol.parse(x)) for x in expectedResults)
      results = _.uniq((util.expressionToString(x) for x in results)).sort()
      expectedResults = _.uniq((util.expressionToString(x) for x in expectedResults)).sort()
      expect(results).to.deep.equal(expectedResults)
    it "cares about the order in which substitutions are written", ->
      results = []
      # This is like the previous test but with subs in the opposite order.
      e = fol.parse '(F(a) and G(b))[b->c][a->b]'
      process = (e) ->
        console.log "found #{util.expressionToString e}"
        results.push(e)
        return undefined
      _ignore = substitute.doAfterApplyingSubstitutions e, process
      expectedResults = ["F(a) and G(b)","F(a) and G(c)","F(b) and G(b)","F(b) and G(c)"]
      expectedResults = (util.delExtraneousProperties(fol.parse(x)) for x in expectedResults)
      results = _.uniq((util.expressionToString(x) for x in results)).sort()
      expectedResults = _.uniq((util.expressionToString(x) for x in expectedResults)).sort()
      expect(results).to.deep.equal(expectedResults)
                        