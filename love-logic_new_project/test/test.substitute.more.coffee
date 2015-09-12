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
  describe "`.doAfterApplyingSubstitutions", ->
    it "lists possible substitutions", ->
      e = fol.parse '(a=a)[a->b]'
      process = (e) ->
        console.log "found #{util.expressionToString e}"
        return undefined
      result = substitute.doAfterApplyingSubstitutions e, process
      expect(result).to.be.undefined
      