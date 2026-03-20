export type DialectName = 'lpl' | 'teller' | 'copi' | 'forallx' | 'logicbook' | (string & {});

export interface DialectNameAndVersion {
  name: DialectName;
  version: string;
}

export interface DialectInfo {
  name: DialectName;
  description?: string;
  textbook?: string;
}

export interface Symbols {
  [name: string]: string | boolean | undefined;
}

export interface ExpressionStringifyOptions {
  /**
   * Replace internal operator names with the current dialect's symbols.
   * Defaults to `true`.
   */
  replaceSymbols?: boolean;
  /**
   * Override the symbol table used during stringification.
   */
  symbols?: Symbols;
}

export interface World {
  domain: unknown[];
  names: Record<string, unknown>;
  predicates: Record<string, unknown[][]>;
  [key: string]: unknown;
}

export interface PredicateRef {
  name: string;
  arity: number;
}

export interface MatchMap {
  [name: string]: DecoratedExpression | unknown;
}

/**
 * Runtime expressions are plain objects decorated with helper methods after parsing.
 * The structural AST is intentionally typed loosely here because the supported API
 * is the method-bearing decorated object rather than every possible internal node shape.
 */
export interface DecoratedExpression {
  [key: string]: unknown;
  walk(fn: (expression: unknown) => unknown): DecoratedExpression;
  delExtraneousProperties(): void;
  isIdenticalTo(otherExpression: unknown): boolean;
  clone(): DecoratedExpression;
  toString(options?: ExpressionStringifyOptions): string;
  listMetaVariableNames(): string;
  listMetaVariableNamesAsList(): string[];
  findMatches(pattern: unknown, matches?: MatchMap, options?: unknown): MatchMap | false;
  applyMatches(matches: MatchMap): DecoratedExpression;
  applySubstitutions(): DecoratedExpression;
  containsSubstitutions(): boolean;
  getAllSubstitutionInstances(): DecoratedExpression[];
  getNames(): string[];
  getPredicates(): PredicateRef[];
  getSentenceLetters(): string[];
  getFreeVariableNames(): string[];
  negate(): DecoratedExpression;
  convertToPNFsimplifyAndSort(): DecoratedExpression;
  isPNFExpressionEquivalent(other: unknown): boolean;
  evaluate(world: World): boolean;
}

export interface ProofStatus {
  verified?: boolean;
  getMessage?(): string;
  [key: string]: unknown;
}

export interface ProofLine {
  [key: string]: unknown;
  number?: string | number;
  sentence?: string;
  status?: ProofStatus;
  verify(): boolean;
  getRuleName?(): string;
}

export interface Proof {
  [key: string]: unknown;
  verify(): boolean;
  listErrorMessages(): string;
  getLine(lineNumber: number): ProofLine;
  toString(options?: { treeProof?: boolean; numberLines?: boolean }): string;
  clone(options?: unknown): Proof;
  detachChildren(): { children: unknown[]; childlessProof: Proof };
}

export interface FolApi {
  /**
   * Parse a sentence using the currently active dialect parser unless a parser is supplied.
   * Throws on parse failure.
   */
  parse(text: string, parser?: unknown): DecoratedExpression;
  /**
   * Parse with the built-in system parser (`awFOL`), regardless of the current dialect.
   * Throws on parse failure.
   */
  parseUsingSystemParser(text: string): DecoratedExpression;
  /**
   * Change the global dialect used by parsing, stringification, and proof checking.
   */
  setDialect(name: DialectName | DialectNameAndVersion, version?: string): void;
  getCurrentDialectNameAndVersion(): DialectNameAndVersion;
  getAllDialectNamesAndDescriptions(): DialectInfo[];
  getTextbookForDialect(name?: DialectName): string | undefined;
  getLanguageNames(): string[];
  getPredLanguageName(): string;
  /**
   * Get the active symbol table, or a named symbol table if provided.
   */
  getSymbols(name?: string): Symbols;
  symbols: Record<string, Symbols>;
  /**
   * Internal compatibility hook retained for older consumers.
   * It is reachable at runtime but not part of the stable public API.
   */
  _dialectManager?: unknown;
}

export interface ProofApi {
  /**
   * Parse proof text. Returns a decorated proof object on success, or an error message string
   * when the proof cannot be parsed.
   */
  parse(text: string, options?: unknown): Proof | string;
}

export declare const fol: FolApi;
export declare const proof: ProofApi;
export declare const symbols: Record<string, Symbols>;

export declare function parse(text: string, parser?: unknown): DecoratedExpression;
export declare function parseUsingSystemParser(text: string): DecoratedExpression;
export declare function setDialect(name: DialectName | DialectNameAndVersion, version?: string): void;
export declare function getCurrentDialectNameAndVersion(): DialectNameAndVersion;
export declare function getAllDialectNamesAndDescriptions(): DialectInfo[];
export declare function getTextbookForDialect(name?: DialectName): string | undefined;
export declare function getLanguageNames(): string[];
export declare function getPredLanguageName(): string;
export declare function parseProof(text: string, options?: unknown): Proof | string;
