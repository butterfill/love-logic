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

%x expectLeftBracket

%%

\s+                     { /* skip whitespace */             }

/*  Punctuation.
    Round brackets, '(' and ')', are used for grouping expressions and for predication.
    Square brackets, '[' and ']', are used for defining substitutions (e.g. φ[τ->α])
    and for initial boxes which express 
*/
<expectLeftBracket>"("     { this.popState(); return '('; }
"("     { return '('; }
")"     { return ')'; }
"["     { return '['; }
"]"     { return ']'; }
","     { return ','; }

/*  Predicates.
    A predicate starts with a capital letter followed by any number
    of digits or letters, which is then followed by a left bracket.
    Whitespace may NOT separate the letter and the bracket.
    Examples: F(x), LeftOf(a,b), F2(x)
    
    Note that the left bracket is not consumed by the lexer.
    In the following, '/((\s)*\()' is lex for lookahead:
     /      -- the lex symbol for look ahead
     \(     -- match a bracket (the bracket is escaped)
    
    Note that this only works because connectives like and are 
    defined first and the lexer matches in the order things are defined.
    Otherwise the `And` in `A And (B Or C)` could be a predicate.
*/
[A-Z][A-Za-z0-9]*/(\()  { this.begin('expectLeftBracket');
                          return 'predicate';               }    

"-->"    { return 'substitution_symbol'; }

/*  Connectives.  
    (These must come after predicates as predicates may start with connectives, e.g. `Orange(a)`.)
    Note that the ⊥ symbol is tricky: _|_ contains or and ‘contra’ and ‘contradiction’ are both allowed.
*/
[tT][rR][uU][eE]             { return 'true'; }
[fF][aA][lL][sS][eE]|"⊥"|"_|_"|[cC][oO][nN][tT][rR][aA][dD][iI][cC][tT][iI][oO][nN]|[cC][oO][nN][tT][rR][aA]  
                             { return 'false'; }
"="                          { return 'identity'; }
[aA][nN][dD]|"&"|"∧"|"•"            { return 'and'; }
[aA][rR][rR][oO][wW]|"->"|"⇒"|"→"|"⊃"    { return 'arrow'; }
"↔"|"≡"|"⇔"|"double_arrow"|"<->" { return 'double_arrow'; }
[oO][rR]|"∨"|"+"|"ǀǀ"|"|"        { return 'or'; }
[nN][oO][tT]|"¬"|"~"|"˜"|"!"     { return 'not'; }
[nN][oO][rR]|"↓"             { return 'nor'; }
[nN][aA][nN][dD]|"↑"         { return 'nand'; }
[aA][lL][lL]|"∀"|[eE][vV][eE][rR][yY]         { return 'universal_quantifier'; }
[sS][oO][mM][eE]|[eE][xX][iI][sS][tT][sS]|"∃" { return 'existential_quantifier'; }



/*  Sentence letters.
    A sentence letter (or 'sentence variable') is a capital letter 
    followed by any number of digits (and not followed by
    a left bracket --- if it were, it would get matched as a predicate).

    Note: this clause must come AFTER the Predicates so that
    the `A` in `A(x)` is parsed as a predicate rather than as a sentence 
    letter.
    
    Note: p, q, r and s are Copi sentence 
*/  
[A-Zpqrs][0-9]*         { return 'sentence_letter'; }

[a-d][0-9]*             { return 'name'; }
[etxyzw][0-9]*          { return 'variable'; }

/*  Variables for terms and expressions. */
[φψχ][0-9]*           { return 'expression_variable'; }
[αβγτ][0-9]*           { return 'term_metavariable'; }

/* null is permitted only in substitutions like `φ[α->null]` and `φ[ψ->null]` */
[nN][uU][lL][lL]        { return 'null'; }

/* Misc. */
<<EOF>>                 { return 'EOF'; }
.                       { return 'invalid_character'; }

/lex



/* operator associations and precedence */

/*  arrow 
    i.  `A and B arrow C` is `(A and B) arrow C`
    ii. `nonassoc` so that A arrow B arrow C is not an expression
*/
%nonassoc 'arrow' 'double_arrow'

%left 'and' 'or' 'nand' 'nor'

/* `not A and B` is `(not A) and B` */
%left 'not'     

/* `exists x F(x) and A` is `(exists x F(x)) and A` */
%left existential_quantifier universal_quantifier
/* These are for the (horrible) Copi style (x) universal quantifiers. */
%left  '(' variable ')'
%left  '(' term_metavariable ')'

/* `A and not A[A->B]` is `A and not (A[A->B])` */
%left '[' ']'

%nonassoc 'identity'

/* This tells JISON where to start: */
%start expressions


%% /* language grammar */

expressions
    : e EOF
        { return $1; }
    | box EOF
        { return $1; }
    | box e EOF
        { $2.box = $1; return $2; }
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
    | '(' variable_or_metavariable ')' e
        { $$ = {type:"universal_quantifier", symbol:'', location:@2, boundVariable:$2, left:$4, right:null}; }
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
    | e '[' substitution_list ']'
      {
         if( $1.substitutions && $1.substitutions.length ) {
           $1.substitutions = $1.substitutions.concat($3);
         } else {
           $1.substitutions = $3;
         }
         $$ = $1; 
      }

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

variable_or_metavariable
    : variable
        { $$ = {type:'variable', name:$1, location:@1}; }
    | term_metavariable
        { $$ = {type:'term_metavariable', name:$1, location:@1}; }
    ;

name_or_metavariable
    : name
        { $$ = {type:'name', name:$1, location:@1}; }
    | term_metavariable
        { $$ = {type:'term_metavariable', name:$1, location:@1}; }
    ;

quantifier_variable
    : variable_or_metavariable
        { $$ = $1; }
    | '(' variable_or_metavariable ')'
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
    | variable_or_metavariable
        { $$ = $1; }
    ;


/*  
    Substitutions that may appear after an expression
    (e.g. '(A and B)[A->(C and D)]).
    
    We allow two notations for multiple substitutions:
        `(A and B)[A->P,B->Q]`
    and 
        `(A and B)[A->P][B->Q]`
    
    (The second is allowed because the rule above says that
    `e[sub]` is an expression; it follows that `(e[sub])[sub2]` 
    is an expression too.)
*/
  
substitution_list
    : substitution
        { $$ = [$1] }
    |  substitution ',' substitution_list
        { $$ = [$1].concat($3) }
    ;

substitution 
    : term substitution_symbol term 
        { $$ = {type:'substitution', from:$1, to:$3, symbol:$2}; }
    | term substitution_symbol null 
        { $$ = {type:'substitution', from:$1, to:null, symbol:$2}; }
    | e substitution_symbol e  
        { $$ = {type:'substitution', from:$1, to:$3, symbol:$2}; }
    | e substitution_symbol null
        { $$ = {type:'substitution', from:$1, to:null, symbol:$2}; }
    ;


/*  
    The box before an expression (e.g. '[a] F(a)'.)
*/
box 
    : '[' name_or_metavariable ']'
      { $$ = {type:'box', term:$2}; }
    ;