chai = require('chai')
assert = chai.assert
expect = chai.expect
evaluate = require('../evaluate').evaluate

describe 'evaluate.evaluate', ->
  it 'should evaluate "true"', ->
    res = evaluate("true", {})
    assert.equal res, true

  it 'should evaluate "false"', ->
    res = evaluate("false", {})
    assert.equal res, false

  it 'should evaluate "true & false"', ->
    res = evaluate("true & false", {})
    assert.equal res, false

  it 'should evaluate "true or false"', ->
    res = evaluate("true or false", {})
    assert.equal res, true

  it 'should evaluate "not false"', ->
    res = evaluate("not false", {})
    assert.equal res, true

  it 'should evaluate "not (true or false)"', ->
    res = evaluate("not (true or false)", {})
    assert.equal res, false

  it 'should evaluate "true arrow false"', ->
    res = evaluate("true arrow false", {})
    assert.equal res, false

  it 'should evaluate "true ↔ false"', ->
    res = evaluate("true ↔ false", {})
    assert.equal res, false

  it 'should evaluate "true ↔ true"', ->
    res = evaluate("true ↔ true", {})
    assert.equal res, true

  it 'should evaluate "true ↓ false"', ->
    result = evaluate("true ↓ false", {})
    assert.equal result, false

  it 'should evaluate "true ↑ false"', ->
    result = evaluate("true ↑ false", {})
    assert.equal result, true

  it 'should evaluate "true ↔ true"', ->
    res = evaluate("true ↔ true", {})
    assert.equal res, true


  it 'should evaluate "A (sentence letters)"', ->
    res = evaluate("A", {A:true, B:false})
    assert.equal res, true
  
  it 'should evaluate "A and B"', ->
    res = evaluate("A and B", {A:true, B:false})
    assert.equal res, false
  
  it 'should evaluate "F(a)"', ->
    res = evaluate("F(a)", {predicates:{F:[[1],[3]]}, names:{a:1, b:2} })
    assert.equal res, true

  it 'should throw and error if given "F(b)" and b is not defined in the world', ->
    expect( -> evaluate("F(b)", {predicates:{F:[[1],[3]]}, names:{a:1}}) ).to.throw()
  
  it 'should evaluate "F(b)"', ->
    res = evaluate("F(b)", {predicates:{F:[[1],[3]]}, names:{a:1, b:2}})
    assert.equal res, false
  
  it 'should evaluate "not F(b)"', ->
    res = evaluate("not F(b)", {predicates:{F:[[1],[3]]}, names:{a:1, b:2}})
    assert.equal res, true
  
  it 'should throw and error if given "F(x)" (where x is an unbound variable)', ->
    expect( -> evaluate("F(x)", {predicates:{F:[[1],[3]]}, names:{a:1}}) ).to.throw()
  
  it 'should evaluate "R(b,c)"', ->
    res = evaluate("R(b,c)", {predicates:{R:[[1,2],[2,3]]}, names:{a:1, b:2, c:3}})
    assert.equal res, true

  it 'should evaluate "R(a,c)"', ->
    res = evaluate("R(a,c)", {predicates:{R:[[1,2],[2,3]]}, names:{a:1, b:2, c:3}})
    assert.equal res, false
  
  it 'should evaluate "some(x) F(x)"', ->
    res = evaluate("some(x) F(x)", {domain:[1,2,3], predicates:{F:[[1],[3]]}, names:{a:1, b:2}})
    assert.equal res, true

  it 'should evaluate "some(x) F(x)" (when nothing is F)', ->
    res = evaluate("some(x) F(x)", {domain:[1,2,3], predicates:{F:[]}, names:{a:1, b:2}})
    assert.equal res, false

  it 'should evaluate "all(x) F(x)"', ->
    res = evaluate("all(x) F(x)", {domain:[1,2,3], predicates:{F:[[1],[3]]}, names:{a:1, b:2}})
    assert.equal res, false

  it 'should evaluate "some(x) F(x)" (when everything is F)', ->
    res = evaluate("some(x) F(x)", {domain:[1,2,3], predicates:{F:[[1],[3],[2]]}, names:{a:1, b:2}})
    assert.equal res, true
    
  it 'should evaluate "all(x) some(y) Loves(y,x)"', ->
    res = evaluate("all(x) F(x)", {domain:[1,2,3], predicates:{Loves:[[1,2],[2,3]]}, names:{a:1, b:2}})
    expect(res).to.be.false
    
  it 'should evaluate "all(x) all(y) Loves(y,x)" (when this is true)', ->
    res = evaluate("all(x) all(y) Loves(y,x)", {domain:[1,2], predicates:{Loves:[[1,2],[2,1],[1,1],[2,2]]}, names:{a:1, b:2}})
    expect(res).to.be.true
  
  e2 = 'all(x) some(y) Loves(y,x)'
  it "should evaluate '#{e2}' (when this is true)", ->
    res = evaluate(e2, {domain:[1,2,3], predicates:{Loves:[[1,2],[2,3],[3,1]]}, names:{a:1, b:2}})
    expect(res).to.be.true
    
  e3 = 'all(x) (F(x) arrow G(x))'
  it "should evaluate '#{e3}' (when this is true)", ->
    res = evaluate(e3, {domain:[1,2,3], predicates:{F:[[1],[2]],G:[[1],[2],[3]]}, names:{a:1, b:2}})
    expect(res).to.be.true

  e4 = 'all(x) (F(x) arrow G(x))'
  it "should evaluate '#{e4}' (when this is false)", ->
    res = evaluate(e4, {domain:[1,2,3], predicates:{F:[[1],[2],[3]],G:[[1],[2]]}, names:{a:1, b:2}})
    expect(res).to.be.false

  e5 = 'some(x) (F(x) and G(x))'
  it "should evaluate '#{e5}' (when this is false)", ->
    res = evaluate(e5, {domain:[1,2,3], predicates:{F:[[1]],G:[[2]]}, names:{a:1, b:2}})
    expect(res).to.be.false
  
  e51 = 'not some(x) (F(x) and G(x))'
  it "should evaluate '#{e51}'", ->
    res = evaluate(e51, {domain:[1,2,3], predicates:{F:[[1]],G:[[2]]}, names:{a:1, b:2}})
    expect(res).to.be.true
  
  e6 = 'some(x) (F(x) and G(x))'
  it "should evaluate '#{e6}' (when this is true)", ->
    res = evaluate(e6, {domain:[1,2,3], predicates:{F:[[1],[2],[3]],G:[[1],[2]]}, names:{a:1, b:2}})
    expect(res).to.be.true

  e7 = 'some(x) (F(x) and (some(x) G(x)))'
  it "should evaluate '#{e7}' (tricky because nested quantifiers bind the same variable)", ->
    res = evaluate(e7, {domain:[1,2,3], predicates:{F:[[1]],G:[[2]]}, names:{a:1, b:2}})
    expect(res).to.be.true

  e8 = 'all(x) (F(x) and (some(x) G(x)))'
  it "should evaluate '#{e8}' (tricky because nested quantifiers bind the same variable)", ->
    res = evaluate(e8, {domain:[1,2,3], predicates:{F:[[1],[2],[3]],G:[[2]]}, names:{a:1, b:2}})
    expect(res).to.be.true
    
  e9 = 'a=b'
  it "should evaluate '#{e9}' (when true)", ->
    res = evaluate(e9, {domain:[1,2,3], predicates:{F:[[1],[2],[3]],G:[[2]]}, names:{a:1, b:1}})
    expect(res).to.be.true
  it "should evaluate '#{e9}' (when false)", ->
    res = evaluate(e9, {domain:[1,2,3], predicates:{F:[[1],[2],[3]],G:[[2]]}, names:{a:1, b:2}})
    expect(res).to.be.false
  
  e10 = 'all x x=x'
  it "should evaluate '#{e10}'", ->
    res = evaluate(e10, {domain:[1,2,3], predicates:{F:[[1],[2],[3]],G:[[2]]}, names:{a:1, b:1}})
    expect(res).to.be.true






  

