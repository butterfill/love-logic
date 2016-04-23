/*  Defines a JISON parser for the justification part of 
    proof lines in the awFOL language.
    
    Tested against JISON version 0.4.15.
*/

%start justification

/* enable EBNF grammar syntax */
%ebnf

%% /* language grammar */

justification
    : j EOF
        { return $1; }
    ;


j
    : rule_name 
        { $$ = {type: 'justification', rule:$1, location:@1}; }
    | rule_name numberlist
        { $$ = {type: 'justification', rule:$1, location:@1, numbers:$2 }; }
    | numberlist rule_name
        { $$ = {type: 'justification', rule:$2, location:@2, numbers:$1}; }
    ;

rule_name 
    : connective intronation (side)?
      { $$= { type: 'rule', connective:$connective, 
              variant:{type:'variant', intronation:$intronation, side:$3 }
            }; }
    | intronation connective (side)?
      { $$= { type: 'rule', connective:$connective, 
              variant:{type:'variant', intronation:$intronation, side:$3 }
            }; }
    | side connective intronation
      { $$= { type: 'rule', connective:$connective, 
              variant:{type:'variant', intronation:$intronation, side:$side }
            }; }
    | connective side intronation
      { $$= { type: 'rule', connective:$connective, 
              variant:{type:'variant', intronation:$intronation, side:$side }
            }; }
    | side intronation connective
      { $$= { type: 'rule', connective:$connective, 
              variant:{type:'variant', intronation:$intronation, side:$side }
            }; }
    | intronation side connective
      { $$= { type: 'rule', connective:$connective, 
              variant:{type:'variant', intronation:$intronation, side:$side }
            }; }

    /* reit and premise are special cases : they can't take a variant */
    | (reit|premise|bare_rule)
      { $$= {type: 'rule', connective:$1, variant:{type:'variant', intronation:null, side: null }}; }

    ;


intronation    
    :  elim
        { $$='elim'; }
    | intro
        { $$='intro'; }
    | decomposition
        { $$='decomposition'; }
    | decomposition2
        { $$='decomposition2'; }
    ;
    
side
    : left
        { $$='left'; }
    | right
        { $$='right'; }
    ;

numberlist
    : number
        { $$ = [$1]; }
    | number numberlist
        { $$ = [$1].concat($2); }
    ;
