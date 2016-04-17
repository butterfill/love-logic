_ = require 'lodash'

symbols = require('../symbols')


dialects =
  lpl :
    available : true
    description : 'The language and natural deduction proof system presented in Barker-Plummer, Barwise and Etchemndy’s ‘Language, Proof and Logic’'
    textbook : "Language, Proof and Logic by Barker-Plummer, Barwise & Etchemendy"
    versions : 
      "0.1" : # version 0.1
        symbols : 'default'
        parser : 'awFOL'
        rules : 'fitch'
  teller :
    available : true
    description : 'The language and natural deduction proof system presented in Teller’s ‘A Modern Formal Logic Primer’ (1998)'
    textbook : "A Modern Formal Logic Primer by Teller"
    versions : 
      "0.1" : 
        symbols : 'teller'
        parser : 'teller'
        rules : 'teller'
  copi :
    available : false
    versions : 
      "0.1" : 
        symbols : 'copi'
        parser : 'copi'
        # TODO : copi rules don’t exist yet!
        rules : 'copi'
  forallx :
    available : true
    description : 'The language and natural deduction proof system presented in Magnus’ ‘forallx’ (2014)'
    textbook : "A Modern Formal Logic Primer by Magnus"
    versions : 
      "0.1" : 
        symbols : 'forallx'
        parser : 'forallx'
        rules : 'forallx'
    

# default settings!
dialectName = 'lpl'
dialectVersion = "0.1"
exports.set = (name, version) ->
  dialectName = name
  allVersions = dialects[name].versions
  unless version?
    version = Math.max(_.keys(allVersions))
  dialectVersion = version
  d = allVersions[version]
  setSymbols(d.symbols)
  setCurrentParser(d.parser)  
  setCurrentRules(d.rules)
# exports.getCurrentDialect = () ->
#   return dialects[dialectName].versions[dialectVersion]
exports.getCurrentDialectNameAndVersion = () ->
  return {name: dialectName, version: dialectVersion}
exports.getTextbookForDialect = (name) ->
  name ?= dialectName
  return dialects[name].textbook
exports.getAllDialectNamesAndDescriptions = () ->
  dialectNames = _.keys(dialects)
  res = []
  for key in dialectNames
    d = dialects[key]
    continue unless d.available is true
    res.push { name:key, description:d.description, textbook:d.textbook }
  return res


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