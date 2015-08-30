/* description: simple FOL test 
 * The parser returns objects like {type:"and", left:[Object], right:[Object]}.
*/

/* lexical grammar */
%lex


%%

\s+                     { /* skip whitespace */ }
"true"                  { return 'true' ;       }
"false"                 { return 'false' ;      }
"and"|"&"               { return 'and' ;        }
"arrow"|"->"            { return 'arrow' ;      }
"or"                    { return 'or' ;         }
"not"                   { return 'not';         }
"all"                   { return 'universal_quantifier';   }
"some"|"exists"         { return 'existential_quantifier'; }
"("                     { return '(' ;          }
")"                     { return ')' ;          }
","                     { return ',' ;          }
[A-Z][a-z][A-Za-z0-9]*  { return 'predicate';   }    
[F-HR][0-9]*            { return 'predicate';   }
[PQST][0-9]*            { return 'sentence_letter';        }
[A-E][0-9]*             { return 'sentence_letter';        }
[a-d][0-9]*             { return 'name';        }
[etxyzw][0-9]*          { return 'variable';    }
<<EOF>>                 { return 'EOF' ;        }
.                       { return 'invalid_character' ;    }

/lex

/* operator associations and precedence */

%nonassoc 'arrow'
%left 'and' 'or'
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
        { $$ = {type:"existential_quantifier", location:@1, variable:{type:'variable', variable_name:$3, location:@3}, left:$5, right:null}; }
    | universal_quantifier '(' variable ')' e
        { $$ = {type:"universal_quantifier", location:@1, variable:{type:'variable', variable_name:$3, location:@3}, left:$5, right:null}; }
    | e and e
        { $$ = {type:'and', location:@2, left:$1, right:$3}; }
    | e or e
        { $$ = {type:'or', location:@2, left:$1, right:$3}; }
    | e arrow e
        { $$ = {type:'arrow', location:@2, left:$1, right:$3}; }
    | not e
        { $$ = {type:'not', location:@1, left:$2, right:null}; }
    | '(' e ')'
        { $$ = $2; }
    | true
        { $$ = {type:'value', value:true, left:null, right:null}; }
    | false
        { $$ = {type:'value', value:false, left:null, right:null}; }
    | sentence_letter
        { $$ = {type:'sentence_letter', location:@1, letter:$1, left:null, right:null}; }
    | predicate '(' termlist  ')'
        { $$ = { type:'predicate', name:$1, location:@1, termlist:$3 } ; }
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
        { $$ = {type:'variable', variable_name:$1, location:@1}; }
    ;