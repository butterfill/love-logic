import {
  fol,
  proof,
  symbols,
  parse,
  parseUsingSystemParser,
  setDialect,
  getCurrentDialectNameAndVersion,
  getAllDialectNamesAndDescriptions,
  getTextbookForDialect,
  getLanguageNames,
  getPredLanguageName,
  parseProof
} from './index.js';

const globalScope =
  typeof window !== 'undefined' ? window : globalThis;

const loveLogic = {
  fol,
  proof,
  symbols,
  parse,
  parseUsingSystemParser,
  setDialect,
  getCurrentDialectNameAndVersion,
  getAllDialectNamesAndDescriptions,
  getTextbookForDialect,
  getLanguageNames,
  getPredLanguageName,
  parseProof
};

globalScope.fol = fol;
globalScope.proof = proof;
globalScope.symbols = symbols;
globalScope.loveLogic = loveLogic;
