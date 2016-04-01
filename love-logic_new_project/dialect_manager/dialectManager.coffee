symbols = require('../symbols')


currentSymbols = symbols.default
exports.setSymbols = (name) ->
  currentSymbols = symbols[name]
exports.getSymbols = (name) ->
  return currentSymbols

parsers = 
  awFOL : awFOL = require '../parser/awFOL'
exports.registerParser = (name, parser) ->
  parsers[name] = parser
currentParserName = 'awFOL'
exports.getParser = (name) -> 
  return parsers[name]
exports.getCurrentParser = () -> 
  return parsers[currentParserName]
exports.getCurrentParserName = () -> 
  return currentParserName
exports.setCurrentParser = (name) ->
  currentParserName = name

  
ruleSets = {}
exports.registerRuleSet = (name, rules) ->
  ruleSets[name] = rules
currentRulesName = 'fitch'
exports.getCurrentRules = () -> 
  return ruleSets[currentRulesName]
exports.getCurrentRulesName = () -> 
  return currentRulesName
exports.setCurrentRules = (name) ->
  currentRulesName = name
