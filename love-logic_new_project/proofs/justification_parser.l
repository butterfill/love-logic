/*  Defines a JISON lexer for the justification part of 
    proof lines in the yaFOL language.
    
    Tested against JISON version 0.4.15.
*/

/* lexical grammar */
/*   
    %options flex means JISON's lexer matches the longest match, 
    not the first rule it finds.
*/
%options flex case-insensitive



%%


/*  Allow 'and' to be used to separate digits by looking ahead.
    Why not just lex 'and' as a `separator`?  Because we also want
    allow 'and' to be used in verbose justifications, and as the name of
    the rule `and elim`.
      [0-9][^,\s]*  -- the number ([^,\s]* matches anything but space or commas)
      (\s+and\s+)   -- 'and' must be surrounded by whitespace
       /            -- the lex symbol for look ahead
       [0-9]        -- the start of a new digit (not captured because of the look ahead)
*/
([0-9][^,\s]*)(\s+and\s+)/[0-9]  
    { yytext = yy.lexer.matches[1];  return 'number'; }    

/*  'to' also needs special treatment.
    When it appears between numbers, treat the numbers as a range; otherwise
    ignore it as part of verbose justification.
    Note that number ranges are returned from the parser formatted 
    as `digits-digits`.  (This matches how number ranges are formatted 
    elsewhere, e.g. in the `line_numbers` module.)
*/
([0-9][^,\s]*)\s+to\s+([0-9][^,\s]*) 
    { yytext = yy.lexer.matches[1]+"-"+yy.lexer.matches[2];  
      return 'number'; 
    }    

/*  '-' needs for the same reason as 'to' does.
    [0-9][^,\s]*? --  the number, non-greedy (`?`) because otherwise it could eat 
                      into the - separator.
    (?:\-+)       --  matches `-`, `--`, ... 
                      `?:` means don't group; the `-` is escaped (`\-`) because 
                      JISON seems to do something weird with the pattern otherwise.
    Otherwise everything is as for 'to' except that whitespace around the `-` is
    optional.
*/
([0-9][^,\s]*?)\s*(?:\-+)\s*([0-9][^,\s]*) 
    { yytext = yy.lexer.matches[1]+"-"+yy.lexer.matches[2];  
      return 'number'; 
    }    

/*  This is our basic number matching expression.
        ([0-9][^,\s]*)    -- start with a digit, continue with anything but `,` or whitespace
        (?:(\s*\,)*)      -- eat up any following commas (but we won't use them).
*/
([0-9][^,\s]*)(?:(\s*\,)*)
    { yytext = yy.lexer.matches[1];
      return 'number'; }


"elimination"|"eliminate"|"elim"    
    { return 'elim'; }
"introduction"|"introduce"|"intro"  
    { return 'intro'; }


"or"|"∨"|"+"|"ǀǀ"       
    { yytext = 'or';
      return 'connective'; }
"="|"identity"          
    { yytext = 'identity';
      return 'connective'; }

"and"|"conjunction"|"∧"|"•"  
    { yytext = 'and';
      return 'connective'; }

"double arrow"|"↔"|"≡"|"⇔"           
    { yytext = 'double_arrow';
      return 'connective'; }

"arrow"|"->"|"⇒"|"→"|"⊃" 
    { yytext = 'arrow';
      return 'connective'; }

"not"|"¬"|"˜"|"!"|"negation"
    { yytext = 'not';
      return 'connective'; }

"⊥"|"contradiction"
    { yytext = 'contradiction';
      return 'connective'; }

"reit"|"reiteration"
    { yytext = 'reit';
      return 'reit'; }

"premise"|"assumption"
    { yytext = 'premise';
      return 'premise'; }


"all"|"∀"|"every"|"universal"
    { yytext = 'universal';
      return 'connective'; }

"some"|"exists"|"∃"|"existential"     
    { yytext = 'existential';
      return 'connective'; }

"left"                  
    { return 'left'; }
"right" 
  { return 'right'; }

[\s,\-]+                     
    { /*  Skip whitespace, commas and dashes. 
      */ 
    }
<<EOF>>
    { return 'EOF'; }
\w+
    { 
      /*  I would love to `return 'waffle';` and treat
          waffle as a category because I want to allow 
          some of the connectives to appear in waffle, e.g. 'not'.
          But attempts to do this proved too tricky for me so far.
      */ 
    }
.
    { /* Ignore everything else */ }


