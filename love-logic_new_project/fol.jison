/* description: simple FOL test 
 * The parser returns objects like {type:"and", left:[Object], right:[Object], location:{...}, symbol:'&'}.
 * where `location` is the parser's object describing the location of the symbol parsed.
 * and `symbol` is the symbol from the input.
*/

/* lexical grammar */
%lex


%%

\s+                     { /* skip whitespace */             }
"true"                  { return 'true' ;                   }
"false"|"⊥"             { return 'false' ;                  }
"="                     { return 'identity' ;               }
"and"|"&"|"∧"|"•"       { return 'and' ;                    }
"arrow"|"->"|"⇒"|"→"|"⊃"            { return 'arrow' ;                  }
"↔"|"≡"|"⇔"           { return 'double_arrow';            }
"or"|"∨"|"+"|"ǀǀ"       { return 'or' ;                     }
"not"|"¬"|"˜"|"!"       { return 'not';                     }
"nor"|"↓"               { return 'nor';                     }
"nand"|"↑"              { return 'nand';                     }
"all"|"∀"|"every"       { return 'universal_quantifier';    }
"some"|"exists"|"∃"     { return 'existential_quantifier';  }
"("                     { return '(' ;                      }
")"                     { return ')' ;                      }
","                     { return ',' ;                      }
[A-Z][a-z][A-Za-z0-9]*  { return 'predicate';               }    
[F-HR][0-9]*            { return 'predicate';               }
"φ"[0-9]*              { return 'expression_variable';     }
"χ"[0-9]*               { return 'expression_variable';     }
"ψ"[0-9]*              { return 'expression_variable';     }
[PQST][0-9]*            { return 'sentence_letter';         }
[A-E][0-9]*             { return 'sentence_letter';         }
[a-d][0-9]*             { return 'name';                    }
[etxyzw][0-9]*          { return 'variable';                }
"α"[0-9]*               { return 'term_metavariable';       }
"β"[0-9]*               { return 'term_metavariable';       }
"γ"[0-9]*               { return 'term_metavariable';       }
"τ"[0-9]*               { return 'term_metavariable';       }
<<EOF>>                 { return 'EOF' ;                    }
.                       { return 'invalid_character' ;      }

/lex

/* operator associations and precedence */

%nonassoc 'arrow' 'double_arrow'
%left 'and' 'or' 'nand' 'nor'
%left 'not'
%left existential_quantifier universal_quantifier

%start expressions

%% /* language grammar */

expressions
    : e EOF
        { return $1; }
    ;

e
    : existential_quantifier '(' variable ')' e
        { $$ = {type:"existential_quantifier", symbol:$1, location:@1, variable:{type:'variable', name:$3,            location:@3}, left:$5, right:null}; }
    | '(' existential_quantifier variable ')' e
        { $$ = {type:"existential_quantifier", symbol:$2, location:@2, variable:{type:'variable', name:$3,            location:@3}, left:$5, right:null}; }
    | existential_quantifier variable e
        { $$ = {type:"existential_quantifier", symbol:$1, location:@1, variable:{type:'variable', name:$2,            location:@2}, left:$3, right:null}; }
    | universal_quantifier '(' variable ')' e
        { $$ = {type:"universal_quantifier", symbol:$1, location:@1, variable:{type:'variable', name:$3,              location:@3}, left:$5, right:null}; }
    | '(' universal_quantifier variable ')' e
        { $$ = {type:"universal_quantifier", symbol:$2, location:@2, variable:{type:'variable', name:$3,              location:@3}, left:$5, right:null}; }
    | universal_quantifier variable e
        { $$ = {type:"universal_quantifier", symbol:$1, location:@1, variable:{type:'variable', name:$2,              location:@2}, left:$3, right:null}; }
    | e and e
        { $$ = {type:'and', symbol:$2, location:@2, left:$1, right:$3}; }
    | e or e
        { $$ = {type:'or', symbol:$2, location:@2, left:$1, right:$3}; }
    | e nand e
        { $$ = {type:'nand', symbol:$2, location:@2, left:$1, right:$3}; }
    | e nor e
        { $$ = {type:'nor', symbol:$2, location:@2, left:$1, right:$3}; }
    | e arrow e
        { $$ = {type:'arrow', symbol:$2, location:@2, left:$1, right:$3}; }
    | e double_arrow e
        { $$ = {type:'double_arrow', symbol:$2, location:@2, left:$1, right:$3}; }
    | not e
        { $$ = {type:'not', symbol:$1, location:@1, left:$2, right:null}; }
    | '(' e ')'
        { $$ = $2; }
    | true
        { $$ = {type:'value', symbol:$1, location:@1, value:true, left:null, right:null}; }
    | false
        { $$ = {type:'value', symbol:$1, location:@1, value:false, left:null, right:null}; }
    | sentence_letter
        { $$ = {type:'sentence_letter', location:@1, letter:$1, left:null, right:null}; }
    | expression_variable
        { $$ = {type:'expression_variable', location:@1, letter:$1, left:null, right:null}; }
    | predicate '(' termlist  ')'
        { $$ = { type:'predicate', name:$1, location:@1, termlist:$3 } ; }
    | term identity term
        { $$ = {type:'identity', symbol:$2, termlist:[$1, $3] }; }
    ;

termlist
    : term 
        { $$ = [$1] }
    | term ',' termlist
        { $$ = [$1].concat($3) }
    ;

term
    : name
        { $$ = {type:'name', name:$1, location:@1}; }
    | variable
        { $$ = {type:'variable', name:$1, location:@1}; }
    | term_metavariable
        { $$ = {type:'term_metavariable', name:$1, location:@1}; }
    ;