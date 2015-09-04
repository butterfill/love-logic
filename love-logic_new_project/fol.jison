/*  Defines a JISON lexer and parser for the yaFOL language.
    The parser returns objects like {type:"and", left:[Object], right:[Object], location:{...}, symbol:'&'}.
    where `location` is the parser's object describing the location of the symbol parsed.
    and `symbol` is the symbol from the input.
 
    Tested against JISON version 0.4.15.
    
    Note that the JISON lexer does not return the longest match; instead
    it matches the first rule it can.
*/

/* lexical grammar */
%lex
%options flex 


%%

\s+                     { /* skip whitespace */             }
"true"                  { return 'true' ;                   }
"false"|"⊥"|"contradiction"  { return 'false' ;                  }
"="                     { return 'identity' ;               }
"and"|"&"|"∧"|"•"       { return 'and' ;                    }
"arrow"|"->"|"⇒"|"→"|"⊃"            { return 'arrow' ;                  }
"↔"|"≡"|"⇔"           { return 'double_arrow';            }
[oO][rR]|"∨"|"+"|"ǀǀ"       { return 'or' ;                     }
[nN][oO][tT]|"¬"|"˜"|"!"       { return 'not';                     }
[nN][oO][rR]|"↓"               { return 'nor';                     }
[nN][aA][nN][dD]|"↑"              { return 'nand';                     }
[aA][lL][lL]|"∀"|[eE][vV][eE][rR][yY]       { return 'universal_quantifier';    }
[sS][oO][mM][eE]|[eE][xX][iI][sS][tT][sS]|"∃"     { return 'existential_quantifier';  }
"("                     { return '(' ;                      }
")"                     { return ')' ;                      }
","                     { return ',' ;                      }

/*  Predicates.
    A predicate starts with a capital letter and is followed by a bracket.
    Examples: F(x), R (a,b), LeftOf(a,b), F2(x)
    in the following, '/((\s)*\()' is lex for lookahead:
     /      -- the lex symbol for look ahead
     (\s)*  -- allow any amount of whitespace
     \(     -- match a bracket (the bracket is escaped)
*/
[A-Z][A-Za-z0-9]*/((\s)*\()  { return 'predicate';               }    
[PQRST][0-9]*            { return 'sentence_letter';         }
[A-E][0-9]*             { return 'sentence_letter';         }
[a-d][0-9]*             { return 'name';                    }
[etxyzw][0-9]*          { return 'variable';                }
[φψχ][0-9]*              { return 'expression_variable';     }
[αβγτ][0-9]*               { return 'term_metavariable';       }
<<EOF>>                 { return 'EOF' ;                    }
.                       { return 'invalid_character' ;      }

/lex



/* operator associations and precedence */

%nonassoc 'arrow' 'double_arrow'
%left 'and' 'or' 'nand' 'nor'
%left 'not'
%left existential_quantifier universal_quantifier

/* This tells JISON where to start: */
%start expressions


%% /* language grammar */

expressions
    : e EOF
        { return $1; }
    ;

e
    : existential_quantifier quantifier_variable e
        { $$ = {type:"existential_quantifier", symbol:$1, location:@1, boundVariable:$2, left:$3, right:null}; }
    | '(' existential_quantifier quantifier_variable ')' e
        { $$ = {type:"existential_quantifier", symbol:$2, location:@2, boundVariable:$3, left:$5, right:null}; }
    | universal_quantifier quantifier_variable e
        { $$ = {type:"universal_quantifier", symbol:$1, location:@1, boundVariable:$2, left:$3, right:null}; }
    | '(' universal_quantifier quantifier_variable ')' e
        { $$ = {type:"universal_quantifier", symbol:$2, location:@2, boundVariable:$3, left:$5, right:null}; }
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
    | '(' e ')'
        { $$ = $2; }
    ;

quantifier_variable
    : variable
        { $$ = {type:'variable', name:$1, location:@1}; }
    | term_metavariable
        { $$ = {type:'term_metavariable', name:$1, location:@1}; }
    | '(' quantifier_variable ')'
        { $$ = $2; }
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