/* Defines a JISON lexer and parser for the justification part of proof lines in the yaFOL language.
*/

/* lexical grammar */
%lex


%%

/* treat number - number as a number, and number to number also */
/* not working: [0-9]\S*\s*-*( to )?\s*[0-9]\S* { return 'number';                 } */
[0-9]\S*                 { return 'number';                 }
"elim"|"elimination"    { return 'elimination' ;            }
"intro"|"introduction"  { return 'introduction' ;           }
"="|"identity"          { return 'identity' ;               }
"and"|"conjunction"|"∧"|"•"  { return 'and' ;                    }
"arrow"|"->"|"⇒"|"→"|"⊃" { return 'arrow' ;                  }
"double arrow"|"↔"|"≡"|"⇔"           { return 'double_arrow';            }
"or"|"∨"|"+"|"ǀǀ"       { return 'or' ;                     }
"not"|"¬"|"˜"|"!"|"negation"       { return 'not';                     }
"all"|"∀"|"every"|"universal"       { return 'universal';    }
"some"|"exists"|"∃"|"existential"     { return 'existential';  }
"left"                  { return 'left' ;                      }
"right"                 { return 'right' ;                      }
"("                     { return '(' ;                      }
")"                     { return ')' ;                      }
","                     { return ',' ;                      }
"to"|"from"|"using"|"applying"|"applied"|"since"|"because"  { /* skip these words */             }
\s+                     { /* skip whitespace */             }


/lex

/* operator associations and precedence */

%start justification

%% /* language grammar */

justification
    : j EOF
        { return $1; }
    ;


j
    : rule 
        { $$ = {rule:$1, location:@1}; }
    | rule number
        { $$ = {rule:$1, location:@1, numbers:$2 }; }
    | number rule 
        { $$ = {rule:$2, location:@2, numbers:$1}; }
    ;

rule 
    : connective variant
      { $$= {connective:$1, variant:$2}; }
    ;

variant
    : elimination
        { $$=[$1]; }
    | introduction
        { $$=[$1]; }
    |
      introduction left
        { $$=[$1,$2]; }
    |
      introduction right
        { $$=[$1,$2]; }
    |
      elimination left
        { $$=[$1,$2]; }
    |
      elimination right
        { $$=[$1,$2]; }
    ;

connective 
    : and
        { $$=$1 }
    |
      or
        { $$=$1 }
    ;
        