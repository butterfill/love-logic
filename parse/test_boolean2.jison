/* description: simple boolean test */

/* lexical grammar */
%lex

id          [A-Z][0-9]*

%%

\s+         /* skip whitespace */
"true"      return 'true'
"false"     return 'false'
"and"       return 'and'
"arrow"     return 'arrow'
"or"        return 'or'
"not"       return 'not'
"("         return '('
")"         return ')'
{id}        return 'ID'
<<EOF>>     return 'EOF'
.           return 'INVALID'

/lex

/* operator associations and precedence */

%left 'arrow'
%left 'and' 'or'
%left 'not'

%start expressions

%% /* language grammar */

expressions
    : e EOF
        { return $1; }
    ;

conj
    : 'and' | 'or' | 'arrow' ;

e
    : e 'and' e
        { $$ = [$2, $1, $3]; }
    | e 'or' e
        { $$ = [$2, $1, $3]; }
    | e 'arrow' e
        { $$ = [$2, $1, $3]; }
    | 'not' e
        { $$ = ['not',$2]; }
    | '(' e ')'
        { $$ = $2; }
    | 'true'
        { $$ = ['VAL', true]; }
    | 'false'
        { $$ = ['VAL', false]; }
    | 'ID'
        { $$ = ['PROP', $1]; }
    ;
