_ = require 'lodash'

util = require 'util'

chai = require 'chai'
expect = chai.expect

blockParser = require '../block_parser'
addLineNumbers = require '../add_line_numbers'
addJustification = require '../add_justification'
addSentences = require '../add_sentences'
addStatus = require '../add_status'

_parse = (proofText) ->
  block = blockParser.parse proofText
  addLineNumbers.to block
  addJustification.to block
  addSentences.to block
  addStatus.to block
  return block


describe "add_status", ->
  describe "`.getErrorMessage`", ->
    it "adds an error message to each line", ->
      proof = _parse '''
        A
        B
        ---
        A and B   // and intro: 1,2
      '''
      for n in [1..4] 
        aLine = proof.getLine(n)
        expect(_.isString(aLine.getErrorMessage())).to.be.true
    it "adds a status object to each line", ->
      proof = _parse '''
        A
        B
        ---
        A and B   // and intro: 1,2
      '''
      for n in [1,2,4] 
        aLine = proof.getLine(n)
        expect(aLine.status.verified).to.be.false
        expect(aLine.status.sentenceParsed).to.be.true
    it "allows a block to list all error messages"
  
  describe "LineStatus", ->
    it ".addMessage allows you to add a message to a line", ->
      proof = _parse '''
        A
        B
        ---
        A and B   // and intro: 1,2
      '''
      aLine = proof.getLine(1)
      nofMsg = aLine.status.messages.length
      aLine.status.addMessage('aarrgh')
      expect(aLine.status.messages.length).to.equal(nofMsg+1)
      expect(aLine.getErrorMessage().search('aarrgh')).not.to.equal(-1)
    it "doesn't conflate messages for different proofs", ->
      proofText = '''
        A
        B
        ---
        A and B   // and intro: 1,2
      '''
      proof1 = _parse proofText
      proof2 = _parse proofText
      aLine1 = proof1.getLine(1)
      aLine1.status.addMessage('aarrgh')
      aLine2 = proof2.getLine(1)
      expect(aLine1.status.messages.length).to.equal(1)
      expect(aLine2.status.messages.length).to.equal(0)
      
    it ".popMessage allows you to remove the last message added to a line", ->
      proof = _parse '''
        C
        B
        ---
        A and B   // or intro: 1,2
      '''
      aLine = proof.getLine(1)
      aLine.status.addMessage('aarrgh')
      expect(aLine.status.messages.length).to.equal(1)
      aLine.status.popMessage()
      expect(aLine.status.messages.length).to.equal(0)
      expect(aLine.getErrorMessage().search('aarrgh')).to.equal(-1)
      
    it ".addAlthoughMessage allows you to add an although message to a line"
    it ".getMessage allows you to get a composite message about a line", ->
      proof = _parse '''
        C
        B
        ---
        A and B   // or intro: 1,2
      '''
      aLine = proof.getLine(1)
      aLine.status.addMessage('aarrgh')
      aLine.status.addMessage('fffddddh')
      expect(aLine.status.getMessage().search('aarrgh')).not.to.equal(-1)
      expect(aLine.status.getMessage().search('fffddddh')).not.to.equal(-1)


  describe "constructing error messages", ->
    it "adds a message when a line has  a syntax error", ->
      proof = _parse '''
        1. A      // premise
        2. &*^$&_)&*^  // premise
      '''
      line = proof.getLine(2)
      expect(line.status.verified).to.be.false
      expect(line.status.getMessage().search('sentence')).not.to.equal(-1)
    it "adds a message when a line has no justification", ->
      proof = _parse '''
        1. A      // premise
        2. A and B  
      '''
      line = proof.getLine(2)
      expect(line.status.verified).to.be.false
      expect(line.status.getMessage().search('justification')).not.to.equal(-1)
    it "adds a message when a line has faulty justification", ->
      proof = _parse '''
        1. A      // premise
        2. A and B  // alii asdyiuy ^(&*$
      '''
      line = proof.getLine(2)
      expect(line.status.verified).to.be.false
      expect(line.status.getMessage().search('justification')).not.to.equal(-1)


