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
    parser : 'copi'
    # TODO : copi rules don’t exist yet!
    rules : 'copi'
  forallx :
    symbols : 'forallx'
    parser : 'forallx'
    rules : 'forallx'
    

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
exports.getSymbols = (name) ->
  unless name?
    return symbols[currentSymbolsName]
  return symbols[name]
exports.getSymbolsName = () ->
  return currentSymbolsName

parsers = 
  awFOL : require '../parser/awFOL'
  copi : require '../parser/copiFOL'
  teller : require '../parser/tellerFOL'
  forallx : require '../parser/forallxFOL'
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