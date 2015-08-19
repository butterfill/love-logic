/* description: simple boolean test */

/* lexical grammar */
%lex
%%

\s+                   /* skip whitespace */
"true"  return 'true'
"false"                   return 'false'
"and"                   return 'and'
"not"                   return 'not'
"(" return '('
")" return ')'
<<EOF>>               return 'EOF'
.                     return 'INVALID'

/lex

/* operator associations and precedence */

%left 'and' 
%left 'not'

%start expressions

%% /* language grammar */

expressions
    : e EOF
        {return $1;}
    ;

e
    : e 'and' e
        {$$ = $1 && $3;}
    | 'not' e
        {$$ = !$2;}
    | '(' e ')'
        {$$ = $2;}
    | 'true'
        {$$ = true;}
    | 'false'
        {$$ = false;}
    ;
