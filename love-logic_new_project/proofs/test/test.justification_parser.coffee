chai = require 'chai'
expect = chai.expect

util = require 'util'

jp = require('../justification_parser')


describe "justification_parser", ->
  it "parses a simple justification", ->
    result = jp.parse "elim left conjunction"
    expect(result.rule.connective).to.equal('and')
    expect(result.rule.variant.side).to.equal('left')
    expect(result.rule.variant.intronation).to.equal('elim')
    # console.log util.inspect result

  it "doesn't require `side to be specified", ->
    result = jp.parse "conjunction elim"
    expect(result.rule.variant.side?).to.be.false

  it "throws on empty input", ->
    expect( -> jp.parse "" ).to.throw

  it "allows you to use upper case", ->
    result = jp.parse "ELIM LEFT CONJUNCTION"
    expect(result.rule.connective).to.equal('and')
    expect(result.rule.variant.side).to.equal('left')
    expect(result.rule.variant.intronation).to.equal('elim')
    # console.log util.inspect result

  it "allows you to use any case", ->
    result = jp.parse "Elim Left ConjUnCtion"
    expect(result.rule.connective).to.equal('and')
    expect(result.rule.variant.side).to.equal('left')
    expect(result.rule.variant.intronation).to.equal('elim')
    # console.log util.inspect result

  it "parses a simple justification (alternative order)", ->
    result = jp.parse "conjunction elim left "
    expect(result.rule.connective).to.equal('and')
    expect(result.rule.variant.side).to.equal('left')
    expect(result.rule.variant.intronation).to.equal('elim')
    # console.log util.inspect result

  it "allows any different way of ordering a rule", ->
    sentences = [
      jp.parse "or intro left"
      jp.parse "or left intro"
      jp.parse "intro or left"
      jp.parse "intro left or"
      jp.parse "left or intro "
      jp.parse "left intro or"
    ] 
    for sentence in sentences
      expect(sentence.rule.connective).to.equal('or')
      expect(sentence.rule.variant.intronation).to.equal('intro')
      expect(sentence.rule.variant.side).to.equal('left')

  it "allows numbers to appear before or after a rule", ->
    sentences = [
      jp.parse "or intro left 1,6-88"
      jp.parse "1,6-88 or intro left"
      jp.parse "from 1,6-88 apply the rule or intro left"
      jp.parse "using or intro left on lines 1,6-88"
    ] 
    for sentence in sentences
      expect(sentence.rule.connective).to.equal('or')
      expect(sentence.numbers).to.deep.equal(['1','6-88'])

  it "allows you to use dashes in rules (e.g. `and-elim`)", ->
    sentences = [
      jp.parse "and-elim left "
      jp.parse "and - elim left "
      jp.parse "and- elim left "
      jp.parse "and -elim left "
    ] 
    for sentence in sentences
      expect(sentence.rule.connective).to.equal('and')
      expect(sentence.rule.variant.intronation).to.equal('elim')
      expect(sentence.rule.variant.side).to.equal('left')

  it "names rules uniformly (and, conjunction, ...)", ->
    sentences = [
      jp.parse "and-elim"
      jp.parse "conjunction-elim"
      jp.parse "∧-elim"
    ] 
    for sentence in sentences
      expect(sentence.rule.connective).to.equal('and')

  it "names rules uniformly (elim)", ->
    sentences = [
      jp.parse "and-elim"
      jp.parse "and-elimination"
    ] 
    for sentence in sentences
      expect(sentence.rule.variant.intronation).to.equal('elim')

  it "works without a side being specified", ->
    result = jp.parse "and elim "
    expect(result.rule.connective).to.equal('and')
    expect(result.rule.variant.side?).to.be.false
    expect(result.rule.variant.intronation).to.equal('elim')
    # console.log util.inspect result
    
  it "allows you to put symbols next to variants (e.g. ∧elim)", ->
    result = jp.parse "∧elim"
    expect(result.rule.connective).to.equal('and')
    expect(result.rule.variant.intronation).to.equal('elim')

  it "allows you to put symbols after variants (e.g. elim∧)", ->
    result = jp.parse "elim∧"
    expect(result.rule.connective).to.equal('and')
    expect(result.rule.variant.intronation).to.equal('elim')

  it "throws without a variant specified", ->
    expect(-> jp.parse "conjunction ").to.throw

  it "throws given something incoherent", ->
    expect(-> jp.parse "and or elim ").to.throw

  it "throws given something incoherent (version two)", ->
    expect(-> jp.parse "and elim all ").to.throw

  it "doesn't throws without a variant specified if the rule doesn't require one", ->
    expect(-> jp.parse "reit 44").not.to.throw
    expect(-> jp.parse "premise ").not.to.throw
    expect(-> jp.parse "assumption ").not.to.throw

  it "recognizes 'premise' as a justification", ->
    j = jp.parse "this is a premise "
    expect(j.rule.connective).to.equal('premise')
    
  it "recognizes 'assumption' as a justification", ->
    j = jp.parse "this is an assumption "
    expect(j.rule.connective).to.equal('premise')

  it "allows you to use 'and' to separate numbers", ->
    result = jp.parse "and elim right because 1 and 3"
    expect(result.rule.connective).to.equal('and')
    expect(result.numbers).to.deep.equal(['1','3'])
    
  it "allows you to use 'to' to separate number ranges", ->
    result = jp.parse "or intro because 1 to 3"
    expect(result.rule.connective).to.equal('or')
    expect(result.numbers).to.deep.equal(['1-3'])
    
  it "allows numbers to be separated with commas", ->
    result = jp.parse "or intro because 1, 9, ,7, 10-12,8,7,"
    expect(result.rule.connective).to.equal('or')
    expect(result.numbers).to.deep.equal(['1','9','7','10-12','8','7'])

  it "represents number ranges uniformly", ->
    result = jp.parse "or intro 1-2 1 to 2 1 - 2 1 -- 2"
    expect(result.numbers.length).to.equal(4)
    for num in result.numbers
      expect(num).to.equal('1-2')

  # # This is really tricky to do with the lexer; I decided to 
  # # do it with `add_line_numbers.cleanNumber` instead.  This has the 
  # # advantage that we do the same thing to the citation numbers 
  # # as we do to the numbers at the start of a line.
  # it "gets rid of one trailing period", ->
  #   result = jp.parse "or intro because 1. , 9., ,7., 10.-12.,8.,7.,"
  #   expect(result.rule.connective).to.equal('or')
  #   expect(result.numbers).to.deep.equal(['1','9','7','10-12','8','7'])

  it "number ranges are correctly formatted whether you use `-`, `--`, ` to `, or ` - `", ->
    sentences = [
      jp.parse "or intro because 1 to 3"
      jp.parse "or intro because 1-3"
      jp.parse "or intro because 1 - 3"
      jp.parse "or intro because 1 -- 3"
      jp.parse "or intro because 1--3"
      jp.parse "or intro because 1 to 3"
    ]
    for sentence in sentences
      # console.log util.inspect(sentence)
      expect(sentence.numbers).to.deep.equal(['1-3'])

  it "allows you to use 'to' in explaining things", ->
    result = jp.parse "here we apply or intro to 1 to 3 to do whatever later."
    expect(result.rule.connective).to.equal('or')
    expect(result.numbers).to.deep.equal(['1-3'])

  it "allows you to use 'order', 'sometimes', and other words that begin with the names of rules", ->
    result = jp.parse "here we apply or intro to 1 to 3 in order to do something later."
    expect(result.rule.connective).to.equal('or')
    expect(result.numbers).to.deep.equal(['1-3'])
  
  it "allows you to use any of the rule names in the LPL textbook", ->
    rulePairs = [
      # [[expectedConnective, expectedIntronation], textToParse]  
      [['and','intro'], '∧intro']
      [['and','elim'], '∧elim']
      [['or','intro'], '∨intro']
      [['or','elim'], '∨elim']
      [['not','intro'], '¬intro']
      [['not','elim'], '¬elim']
      [['contradiction','intro'], '⊥intro']
      [['contradiction','elim'], '⊥elim']
      [['arrow','intro'], '→intro']
      [['arrow','elim'], '→elim']
      [['double_arrow','intro'], '↔intro']      
      [['double_arrow','elim'], '↔elim']      
      [['reit',null], 'reit']
      [['identity','intro'], '=intro']      
      [['identity','elim'], '=elim']
      [['universal','intro'], '∀intro']
      [['universal','elim'], '∀elim']
      [['existential','intro'], '∃intro']
      [['existential','elim'], '∃elim']
    ]
    rulePairs = ( [name, jp.parse(text)] for [name,text] in rulePairs)
    for [name, justification] in rulePairs
      expect(justification.rule.connective).to.equal(name[0])
      expect(justification.rule.variant.intronation).to.equal(name[1])

  it "allows you to add ticks at the start of the justification", ->
    result = jp.parse "tick exists D 1"
    expect(result.ticked).to.be.true
  it "allows you to add ticks at the end of the justification", ->
    result = jp.parse "exists D 1 ✓"
    expect(result.ticked).to.be.true
  it "does not tick lines that are not ticked", ->
    result = jp.parse "exists D 1"
    expect(result.ticked?).to.be.false
  
  it "correctly gets double negation as ~~", ->
    result = jp.parse "~~ D 1"
    expect(result.rule.connective).to.equal('double-negation')