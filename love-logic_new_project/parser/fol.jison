/*  Defines a JISON lexer and parser for the awFOL language.
    The parser returns objects like {type:"and", left:[Object], right:[Object], location:{...}, symbol:'&'}.
    where `location` is the parser's object describing the location of the symbol parsed.
    and `symbol` is the symbol from the input.
 
    Tested against JISON version 0.4.15.
    
    Note that the JISON lexer does not return the longest match; instead
    it matches the first rule it can.
*/

/* lexical grammar */
%lex


%%

\s+                     { /* skip whitespace */             }

/*  Connectives.  */
"true"                       { return 'true'; }
"false"|"⊥"|"contradiction"  { return 'false'; }
"="                          { return 'identity'; }
"and"|"&"|"∧"|"•"            { return 'and'; }
"arrow"|"->"|"⇒"|"→"|"⊃"    { return 'arrow'; }
"↔"|"≡"|"⇔"                { return 'double_arrow'; }
[oO][rR]|"∨"|"+"|"ǀǀ"        { return 'or'; }
[nN][oO][tT]|"¬"|"˜"|"!"     { return 'not'; }
[nN][oO][rR]|"↓"             { return 'nor'; }
[nN][aA][nN][dD]|"↑"         { return 'nand'; }
[aA][lL][lL]|"∀"|[eE][vV][eE][rR][yY]         { return 'universal_quantifier'; }
[sS][oO][mM][eE]|[eE][xX][iI][sS][tT][sS]|"∃" { return 'existential_quantifier'; }

/*  Punctuation.
    Round brackets, '(' and ')', are used for grouping expressions and for predication.
    Square brackets, '[' and ']', are used for defining substitutions (e.g. φ[τ->α])
    and for initial boxes which express 
*/
"("     { return '('; }
")"     { return ')'; }
"["     { return '['; }
"]"     { return ']'; }
","     { return ','; }

/*  Predicates.
    A predicate starts with a capital letter followed by any number
    of digits or letters, which is then followed by a left bracket.
    Whitespace may separate the letter and the bracket.
    Examples: F(x), R (a,b), LeftOf(a,b), F2(x)
    
    Note that the left bracket is not consumed by the lexer.
    In the following, '/((\s)*\()' is lex for lookahead:
     /      -- the lex symbol for look ahead
     (\s)*  -- allow any amount of whitespace
     \(     -- match a bracket (the bracket is escaped)
*/
[A-Z][A-Za-z0-9]*/((\s)*\()  { return 'predicate';               }    

/*  Sentence letters.
    A sentence letter (or 'sentence variable') is a capital letter 
    followed by any number of digits (and not followed by
    a left bracket --- if it were, it would get matched as a predicate).

    Note: this clause must come AFTER the Predicates so that
    the `A` in `A(x)` is parsed as a predicate rather than as a sentence 
    letter.
*/  
[A-Z][0-9]*            { return 'sentence_letter';         }

[a-d][0-9]*             { return 'name';                    }
[etxyzw][0-9]*          { return 'variable';                }

/*  Variables for terms and expressions. */
[φψχ][0-9]*              { return 'expression_variable';     }
[αβγτ][0-9]*               { return 'term_metavariable';       }

/* Misc. */
<<EOF>>                 { return 'EOF' ;                    }
.                       { return 'invalid_character' ;      }

/lex



/* operator associations and precedence */

%nonassoc 'arrow' 'double_arrow'
%left 'and' 'or' 'nand' 'nor'
%left 'not'
%left existential_quantifier universal_quantifier
%left substitution_list
%left '[' ']'

/* This tells JISON where to start: */
%start expressions


%% /* language grammar */

expressions
    : e EOF
        { return $1; }
    | box e EOF
        { $2.box = $1; return $2; }
/*
    | e substitution_list EOF
        { $1.substitutions = $2; return $1; }
    | box e substitution_list EOF
        { $2.box = $1; $2.substitutions = $3; return $2; }
*/
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
    | sentence_letter_or_expression_variable
        { $$ = $1; }
    | predicate '(' termlist  ')'
        { $$ = { type:'predicate', name:$1, location:@1, termlist:$3 } ; }
    | term identity term
        { $$ = {type:'identity', symbol:$2, termlist:[$1, $3] }; }
    | '(' e ')'
        { $$ = $2; }

    /*  Substitutions -- see below.
        Note that `substitution_list` is `.reverse()`d here.
    */
    | e substitution_list
      { $1.substitutions = $2.reverse(); $$ = $1; }

    ;

/*  (Bring this out of the above means we can re-use it later 
    when defining substitutions.)
*/
sentence_letter_or_expression_variable
    : expression_variable
        { $$ = {type:'expression_variable', location:@1, letter:$1, left:null, right:null}; }
    | sentence_letter
        { $$ = {type:'sentence_letter', location:@1, letter:$1, left:null, right:null}; }
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


/*  
    Substitutions that may appear after an expression
    (e.g. '(A and B)[A->(C and D)]).
    
    This is tricky because we allow two notations for multiple substitutions:
        `(A and B)[A->P,B->Q]`
    and 
        `(A and B)[A->P][B->Q]`
    
    Note that recursive clauses must all be tail first
    (e.g. `substitution_list substitution`, and not the other way around).
    (This is because making one of them tail-first avoids errors 
    in the grammar, and making them all tail-first ensures that
    lists of substitutions are ordered in a consistent way.)
*/
substitution_list
    /*  Allow [sub1,sub2,...] 
        Note that this allows a single substitution.
    */
    : '[' bare_substitution_list ']'
        { $$ = $2; }
    /*  Allow [sub1][sub2]... */
    | substitution_list substitution
        { $$ = [$2].concat($1) }
    ;

substitution
    : '[' bare_substitution ']'
        { $$ = $2 }
    ;
    
bare_substitution 
    : term arrow term 
        { $$ = {type:'substitution', from:$1, to:$3}; }
    | sentence_letter_or_expression_variable arrow e  
        { $$ = {type:'substitution', from:$1, to:$3}; }
    ;

bare_substitution_list
    : bare_substitution
        { $$ = [$1] }
    | bare_substitution_list ',' bare_substitution 
        { $$ = [$3].concat($1) }
    ;


/*  
    The box before an expression (e.g. '[a] F(a)'.)
*/
box 
    : '[' term ']'
      { $$ = {type:'box', term:$2}; }
    ;