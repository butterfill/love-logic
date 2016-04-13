symbols = require('../symbols')


dialects =
  default :
    symbols : 'default'
    parser : 'awFOL'
    rules : 'fitch'
  teller :
    symbols : 'teller'
    parser : 'teller'
    rules : 'teller'
  copi :
    symbols : 'copi'
    # TODO : parser doesn’t exist yet; using teller is an approximation!
    parser : 'teller'
    # TODO : rules don’t exist yet!
    rules : 'teller'

exports.set = (name) ->
  d = dialects[name]
  setSymbols(d.symbols)
  setCurrentParser(d.parser)  
  setCurrentRules(d.rules)

exports.listDialects = () ->
  return _.keys(dialects)
  
currentSymbolsName = 'default'
setSymbols = (name) ->
  currentSymbolsName = name
exports.setSymbols = setSymbols
exports.getSymbols = () ->
  return symbols[currentSymbolsName]
exports.getSymbolsName = () ->
  return currentSymbolsName

parsers = 
  awFOL : require '../parser/awFOL'
  teller : require '../parser/tellerFOL'
currentParserName = undefined
exports.registerParser = (name, parser) ->
  parsers[name] = parser
exports.getParser = (name) -> 
  unless name of parsers
    throw new Error "unknown parser #{name}"
  return parsers[name]
exports.getCurrentParser = () -> 
  return parsers[currentParserName]
exports.getCurrentParserName = () -> 
  return currentParserName
setCurrentParser = (name) ->
  unless name of parsers
    throw new Error "unknown parser ‘#{name}’"
  currentParserName = name
exports.setCurrentParser = setCurrentParser

setCurrentParser('awFOL')

  
ruleSets = {}
exports.registerRuleSet = (name, rules) ->
  ruleSets[name] = rules
currentRulesName = 'fitch'
exports.getCurrentRules = () -> 
  return ruleSets[currentRulesName]
exports.getCurrentRulesName = () -> 
  return currentRulesName
setCurrentRules = (name) ->
  currentRulesName = name
exports.setCurrentRules = setCurrentRules