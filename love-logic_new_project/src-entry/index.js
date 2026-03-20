import folModule from '../.build/cjs/fol.js';
import proofModule from '../.build/cjs/proofs/proof.js';
import symbolsModule from '../.build/cjs/symbols.js';

const fol = folModule;
const proof = proofModule;
const symbols = symbolsModule;

if (!fol.getSymbols) {
  fol.getSymbols = (name) => fol._dialectManager.getSymbols(name);
}

const parse = (...args) => fol.parse(...args);
const parseUsingSystemParser = (...args) => fol.parseUsingSystemParser(...args);
const setDialect = (...args) => fol.setDialect(...args);
const getCurrentDialectNameAndVersion = (...args) =>
  fol.getCurrentDialectNameAndVersion(...args);
const getAllDialectNamesAndDescriptions = (...args) =>
  fol.getAllDialectNamesAndDescriptions(...args);
const getTextbookForDialect = (...args) => fol.getTextbookForDialect(...args);
const getLanguageNames = (...args) => fol.getLanguageNames(...args);
const getPredLanguageName = (...args) => fol.getPredLanguageName(...args);
const parseProof = (...args) => proof.parse(...args);

export {
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
