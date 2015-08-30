/* description: simple FOL test 
 * This version creates lists.
*/

/* lexical grammar */
%lex


%%

\s+                     { /* skip whitespace */ }
"true"                  { return 'true' ;       }
"false"                 { return 'false' ;      }
"and"|"&"               { return 'and' ;        }
"arrow"                 { return 'arrow' ;      }
"or"                    { return 'or' ;         }
"not"                   { return 'not';         }
"all"                   { return 'UNIVERSAL';   }
"some"|"exists"         { return 'EXISTENTIAL'; }
"("                     { return '(' ;          }
")"                     { return ')' ;          }
","                     { return ',' ;          }
[A-Z][a-z][A-Za-z0-9]*  { return 'predicate';   }    
[F-HR][0-9]*            { return 'predicate';   }
[PQST][0-9]*            { return 'PROP';        }
[A-E][0-9]*             { return 'PROP';        }
[a-d][0-9]*             { return 'NAME';        }
[etxyzw][0-9]*          { return 'VARIABLE';    }
<<EOF>>                 { return 'EOF' ;        }
.                       { return 'INVALID' ;    }

/lex

/* operator associations and precedence */

%nonassoc 'arrow'
%left 'and' 'or'
%left 'not'
%left EXISTENTIAL UNIVERSAL

%start expressions

%% /* language grammar */

expressions
    : e EOF
        { return $1; }
    ;

e
    : EXISTENTIAL '(' VARIABLE ')' e
        { $$ = ['EXISTENTIAL',$3, $5]; }
    | UNIVERSAL '(' VARIABLE ')' e
        { $$ = ['UNIVERSAL',$3, $5]; }
    | e and e
        { $$ = ['and', $1, $3]; }
    | e or e
        { $$ = ['or', $1, $3]; }
    | e arrow e
        { $$ = ['arrow', $1, $3]; }
    | not e
        { $$ = ['not',$2]; }
    | '(' e ')'
        { $$ = $2; }
    | true
        { $$ = ['VAL', true]; }
    | false
        { $$ = ['VAL', false]; }
    | PROP
        { $$ = ['PROP', $1]; }
    | predicate '(' termlist  ')'
        { $$ = ['predicate', $1, $3] ; }
    ;

termlist
    : term 
        { $$ = [$1] }
    | term ',' termlist
        { $$ = [$1].concat($3) }
    ;

term
    : NAME
        { $$ = ['NAME', $1]; }
    | VARIABLE
        { $$ = ['VARIABLE', $1]; }
    ;