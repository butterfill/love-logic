/*  Defines a JISON lexer for the justification part of 
    proof lines in the awFOL language.
    
    Tested against JISON version 0.4.15.
*/

/* lexical grammar */
/*   
    %options flex means JISON's lexer matches the longest match, 
    not the first rule it finds.
*/
%options flex case-insensitive



%%


/*  Allow 'and' to be used to separate digits by looking ahead.
    Why not just lex 'and' as a `separator`?  Because we also want
    allow 'and' to be used in verbose justifications, and as the name of
    the rule `and elim`.
      [0-9][^,\s]*  -- the number ([^,\s]* matches anything but space or commas)
      (\s+and\s+)   -- 'and' must be surrounded by whitespace
       /            -- the lex symbol for look ahead
       [0-9]        -- the start of a new digit (not captured because of the look ahead)
*/
([0-9][^,\s]*)(\s+and\s+)/[0-9]  
    { yytext = yy.lexer.matches[1];  return 'number'; }    

/*  'to' also needs special treatment.
    When it appears between numbers, treat the numbers as a range; otherwise
    ignore it as part of verbose justification.
    Note that number ranges are returned from the parser formatted 
    as `digits-digits`.  (This matches how number ranges are formatted 
    elsewhere, e.g. in the `line_numbers` module.)
*/
([0-9][^,\s]*)\s+to\s+([0-9][^,\s]*) 
    { yytext = yy.lexer.matches[1]+"-"+yy.lexer.matches[2];  
      return 'number'; 
    }    

/*  '-' needs special treatment for the same reason as 'to' does.
    [0-9][^,\s]*? --  the number, non-greedy (`?`) because otherwise it could eat 
                      into the - separator.
    (?:\-+)       --  matches `-`, `--`, ... 
                      `?:` means don't group; the `-` is escaped (`\-`) because 
                      JISON seems to do something weird with the pattern otherwise.
    Otherwise everything is as for 'to' except that whitespace around the `-` is
    optional.
*/
([0-9][^,\s]*?)\s*(?:\-+)\s*([0-9][^,\s]*) 
    { yytext = yy.lexer.matches[1]+"-"+yy.lexer.matches[2];  
      return 'number'; 
    }    

/*  This is our basic number matching expression.
        ([0-9][^,\s]*)    -- start with a digit, continue with anything but `,` or whitespace
        (?:(\s*\,)*)      -- eat up any following commas (but we won't use them).
*/
([0-9][^,\s]*)(?:(\s*\,)*)
    { yytext = yy.lexer.matches[1];
      return 'number'; }


"elimination"|"eliminate"|"elim"|"e"    
    { return 'elim'; }
"introduction"|"introduce"|"intro"|"i"  
    { return 'intro'; }
"decomposition-2"|"decomposition2"|"d-2"|"d2" { return 'decomposition2'; }
"decomposition"|"d" { return 'decomposition'; }
    

"✓"|"tick" { return 'tick'; }

"⊥"|"_|_"|"contradiction"|"contra"|"false"
    { yytext = 'contradiction';
      return 'connective'; }


"or"|"∨"|"+"|"ǀǀ"|"|"     
    { yytext = 'or';
      return 'connective'; }
"="|"identity"          
    { yytext = 'identity';
      return 'connective'; }

"and"|"conjunction"|"∧"|"•"|"&"  
    { yytext = 'and';
      return 'connective'; }

"double_arrow"|"↔"|"≡"|"⇔"|"<->"           
    { yytext = 'double_arrow';
      return 'connective'; }

"arrow"|"->"|"⇒"|"→"|"⊃" 
    { yytext = 'arrow';
      return 'connective'; }

"not"|"¬"|"˜"|"~"|"!"|"negation"
    { yytext = 'not';
      return 'connective'; }

"reit"|"reiteration"|"r"
    { yytext = 'reit';
      return 'reit'; }

"premise"|"assumption"|"set member"|"sm"|"p"
    { yytext = 'premise';
      return 'premise'; }

/* NB: within each rule, put longer names before shorter ones (eg "commutivity"|"comm").
   Otherwise the parser will not recognise the rules.
*/

"weakening"|"w"                     { yytext = 'weakening';return 'connective'; }
"argument by cases"|"cases"|"ac"    { yytext = 'cases';return 'connective'; }
"denying the consequent"|"dc"       { yytext = 'DC';return 'connective'; }
"reductio"|"rd"|"reductio ad absurdum" { yytext = 'reductio';return 'connective'; }
"dm"|"deMorgan"|"dem"|"de morgan"         { yytext = 'DM';return 'connective'; }
"contraposition"|"cp"             { yytext = 'contraposition';return 'connective'; }
"conditional"|"c"                 { yytext = 'C';return 'connective'; }
"cd"                              { yytext = 'contradiction';return 'connective'; }
"not all"|"not-all"|"~∀"          { yytext = 'not-all';return 'connective'; }
"all not"|"all-not"|"∀~"          { yytext = 'all-not';return 'connective'; }
"exists not"|"exists-not"|"∃~"    { yytext = 'exists-not';return 'connective'; }
"not exists"|"not-exists"|"~∃"    { yytext = 'not-exists';return 'connective'; }

"dilemma"|"dil"                    { yytext = 'dilemma';return 'connective'; }
"mt"|"modus tollens"|"modus-tollens"               
                      { yytext = 'modus-tollens';return 'connective'; }
"hs"|"hypothetical syllogism"|"hypothetical-syllogism"      
                      { yytext = 'hypothetical-syllogism';return 'connective'; }
"ds"|"disjunctive syllogism"|"disjunctive-syllogism"      
                      { yytext = 'disjunctive-syllogism';return 'connective'; }
"commutivity"|"comm"|"com"  { yytext = 'commutivity';return 'connective'; }
"dn"|"double-negation"|"double negation"|"negated negation"|"negated-negation"|"~~"|"¬¬"|"not not"
                      { yytext = 'double-negation';return 'connective'; }
"mc"|"material-conditional"|"material conditional"
                      { yytext = "material-conditional";return 'connective'; }
"bex"|"↔ex"|"biconditional-exchange"|"biconditional exchange"
                      { yytext = 'biconditional-exchange';return 'connective'; }
"qn"|"quantifier-negation"|"quantifier negation"         
                      { yytext = 'quantifier-negation';return 'connective'; }

"implication"|"impl"    { yytext = 'implication';return 'connective'; }
"transposition"|"trans" { yytext = 'transposition';return 'connective'; }
"distribution"|"dist"   { yytext = 'distribution';return 'connective'; }
"association"|"assoc"   { yytext = 'association';return 'connective'; }
"idempotence"|"idem"    { yytext = 'idempotence';return 'connective'; }
"exportation"|"exp"     { yytext = 'exportation';return 'connective'; }
"equivalence"|"equiv"   { yytext = 'equivalence';return 'connective'; }


"negated biconditional"|"negated-biconditional"|"not <->"|"~ <->"|"~<->"|"not<->"|"~↔"|"~≡"|"~ ↔"|"~ ≡"|"¬↔"|"¬≡"|"¬ ↔"|"¬ ≡"   
          { yytext = 'not_double_arrow';return 'connective'; }
("negated"|"not"|"~"|"¬"|"!")(\s)?("and"|"conjunction"|"∧"|"•"|"&")  { yytext = 'not_and';return 'connective'; }

("negated"|"not"|"~"|"¬"|"!")(\s)?("disjunction"|"or"|"∨"|"|")  { yytext = 'not_or';return 'connective'; }

("negated"|"not"|"~"|"¬"|"!")(\s)?("conditional"|"arrow"|"->"|"⇒"|"→"|"⊃")  { yytext = 'not_arrow';return 'connective'; }




"all"|"∀"|"every"|"universal"
    { yytext = 'universal';
      return 'connective'; }

"some"|"exists"|"∃"|"existential"     
    { yytext = 'existential';
      return 'connective'; }

"left"                  
    { return 'left'; }
"right" 
  { return 'right'; }

"close branch"|"close-branch"   { yytext = 'close-branch';return 'connective'; }
"open branch"|"open-branch"   { yytext = 'open-branch';return 'connective'; }





[\s,]+                     
    { /*  Skip whitespace and commas. 
      */ 
    }
<<EOF>>
    { return 'EOF'; }
\w+
    { 
      /*  I would love to `return 'waffle';` and treat
          waffle as a category because I want to allow 
          some of the connectives to appear in waffle, e.g. 'not'.
          But attempts to do this proved too tricky for me so far.
      */ 
    }
.
    { /* Ignore everything else */ }


