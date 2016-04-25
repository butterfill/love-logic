/* parser generated by jison 0.4.17 */
/*
  Returns a Parser object of the following structure:

  Parser: {
    yy: {}
  }

  Parser.prototype: {
    yy: {},
    trace: function(),
    symbols_: {associative list: name ==> number},
    terminals_: {associative list: number ==> name},
    productions_: [...],
    performAction: function anonymous(yytext, yyleng, yylineno, yy, yystate, $$, _$),
    table: [...],
    defaultActions: {...},
    parseError: function(str, hash),
    parse: function(input),

    lexer: {
        EOF: 1,
        parseError: function(str, hash),
        setInput: function(input),
        input: function(),
        unput: function(str),
        more: function(),
        less: function(n),
        pastInput: function(),
        upcomingInput: function(),
        showPosition: function(),
        test_match: function(regex_match_array, rule_index),
        next: function(),
        lex: function(),
        begin: function(condition),
        popState: function(),
        _currentRules: function(),
        topState: function(),
        pushState: function(condition),

        options: {
            ranges: boolean           (optional: true ==> token location info will include a .range[] member)
            flex: boolean             (optional: true ==> flex-like lexing behaviour where the rules are tested exhaustively to find the longest match)
            backtrack_lexer: boolean  (optional: true ==> lexer regexes are tested in order and for each matching regex the action code is invoked; the lexer terminates the scan when a token is returned by the action code)
        },

        performAction: function(yy, yy_, $avoiding_name_collisions, YY_START),
        rules: [...],
        conditions: {associative list: name ==> set},
    }
  }


  token location info (@$, _$, etc.): {
    first_line: n,
    last_line: n,
    first_column: n,
    last_column: n,
    range: [start_number, end_number]       (where the numbers are indexes into the input string, regular zero-based)
  }


  the parseError function receives a 'hash' object with these members for lexer and parser errors: {
    text:        (matched text)
    token:       (the produced terminal token, if any)
    line:        (yylineno)
  }
  while parser (grammar) errors will also provide these members, i.e. parser errors deliver a superset of attributes: {
    loc:         (yylloc)
    expected:    (string describing the set of expected tokens)
    recoverable: (boolean: TRUE when the parser has a error recovery rule available for this particular error)
  }
*/
var justification_parser = (function(){
var o=function(k,v,o,l){for(o=o||{},l=k.length;l--;o[k[l]]=v);return o},$V0=[1,7],$V1=[1,12],$V2=[1,13],$V3=[1,14],$V4=[1,15],$V5=[1,16],$V6=[1,17],$V7=[1,11],$V8=[1,18],$V9=[1,19],$Va=[5,7],$Vb=[5,7,22],$Vc=[5,7,10,16,17,18,19,20,21,23,24],$Vd=[5,7,10,20,21,22],$Ve=[5,7,10,16,17,18,19,22];
var parser = {trace: function trace() { },
yy: {},
symbols_: {"error":2,"justification":3,"j":4,"EOF":5,"j2":6,"tick":7,"rule_name":8,"numberlist":9,"connective":10,"intronation":11,"rule_name_option0":12,"rule_name_option1":13,"side":14,"rule_name_group0":15,"elim":16,"intro":17,"decomposition":18,"decomposition2":19,"left":20,"right":21,"number":22,"reit":23,"premise":24,"$accept":0,"$end":1},
terminals_: {2:"error",5:"EOF",7:"tick",10:"connective",16:"elim",17:"intro",18:"decomposition",19:"decomposition2",20:"left",21:"right",22:"number",23:"reit",24:"premise"},
productions_: [0,[3,2],[4,1],[4,2],[4,2],[6,1],[6,2],[6,2],[8,3],[8,3],[8,3],[8,3],[8,3],[8,3],[8,1],[8,1],[11,1],[11,1],[11,1],[11,1],[14,1],[14,1],[9,1],[9,2],[12,0],[12,1],[13,0],[13,1],[15,1],[15,1]],
performAction: function anonymous(yytext, yyleng, yylineno, yy, yystate /* action[1] */, $$ /* vstack */, _$ /* lstack */) {
/* this == yyval */

var $0 = $$.length - 1;
switch (yystate) {
case 1:
 return $$[$0-1]; 
break;
case 2:
 this.$ = $$[$0]; 
break;
case 3:
 $$[$0].ticked = true; this.$ = $$[$0] 
break;
case 4:
 $$[$0-1].ticked = true; this.$ = $$[$0-1] 
break;
case 5:
 this.$ = {type: 'justification', rule:$$[$0], location:_$[$0]}; 
break;
case 6:
 this.$ = {type: 'justification', rule:$$[$0-1], location:_$[$0-1], numbers:$$[$0] }; 
break;
case 7:
 this.$ = {type: 'justification', rule:$$[$0], location:_$[$0], numbers:$$[$0-1]}; 
break;
case 8:
 this.$= { type: 'rule', connective:$$[$0-2], 
              variant:{type:'variant', intronation:$$[$0-1], side:$$[$0] }
            }; 
break;
case 9:
 this.$= { type: 'rule', connective:$$[$0-1], 
              variant:{type:'variant', intronation:$$[$0-2], side:$$[$0] }
            }; 
break;
case 10:
 this.$= { type: 'rule', connective:$$[$0-1], 
              variant:{type:'variant', intronation:$$[$0], side:$$[$0-2] }
            }; 
break;
case 11:
 this.$= { type: 'rule', connective:$$[$0-2], 
              variant:{type:'variant', intronation:$$[$0], side:$$[$0-1] }
            }; 
break;
case 12:
 this.$= { type: 'rule', connective:$$[$0], 
              variant:{type:'variant', intronation:$$[$0-1], side:$$[$0-2] }
            }; 
break;
case 13:
 this.$= { type: 'rule', connective:$$[$0], 
              variant:{type:'variant', intronation:$$[$0-2], side:$$[$0-1] }
            }; 
break;
case 14: case 15:
 this.$= {type: 'rule', connective:$$[$0], variant:{type:'variant', intronation:null, side: null }}; 
break;
case 16:
 this.$='elim'; 
break;
case 17:
 this.$='intro'; 
break;
case 18:
 this.$='decomposition'; 
break;
case 19:
 this.$='decomposition2'; 
break;
case 20:
 this.$='left'; 
break;
case 21:
 this.$='right'; 
break;
case 22:
 this.$ = [$$[$0]]; 
break;
case 23:
 this.$ = [$$[$0-1]].concat($$[$0]); 
break;
}
},
table: [{3:1,4:2,6:3,7:[1,4],8:5,9:6,10:$V0,11:8,14:9,15:10,16:$V1,17:$V2,18:$V3,19:$V4,20:$V5,21:$V6,22:$V7,23:$V8,24:$V9},{1:[3]},{5:[1,20]},{5:[2,2],7:[1,21]},{6:22,8:5,9:6,10:$V0,11:8,14:9,15:10,16:$V1,17:$V2,18:$V3,19:$V4,20:$V5,21:$V6,22:$V7,23:$V8,24:$V9},o($Va,[2,5],{9:23,22:$V7}),{8:24,10:$V0,11:8,14:9,15:10,16:$V1,17:$V2,18:$V3,19:$V4,20:$V5,21:$V6,23:$V8,24:$V9},o($Vb,[2,14],{11:25,14:26,16:$V1,17:$V2,18:$V3,19:$V4,20:$V5,21:$V6}),{10:[1,27],14:28,20:$V5,21:$V6},{10:[1,29],11:30,16:$V1,17:$V2,18:$V3,19:$V4},o($Vb,[2,15]),o($Vc,[2,22],{9:31,22:$V7}),o($Vd,[2,16]),o($Vd,[2,17]),o($Vd,[2,18]),o($Vd,[2,19]),o($Ve,[2,20]),o($Ve,[2,21]),o($Vb,[2,28]),o($Vb,[2,29]),{1:[2,1]},{5:[2,4]},{5:[2,3]},o($Va,[2,6]),o($Va,[2,7]),o($Vb,[2,24],{12:32,14:33,20:$V5,21:$V6}),{11:34,16:$V1,17:$V2,18:$V3,19:$V4},o($Vb,[2,26],{13:35,14:36,20:$V5,21:$V6}),{10:[1,37]},{11:38,16:$V1,17:$V2,18:$V3,19:$V4},{10:[1,39]},o($Vc,[2,23]),o($Vb,[2,8]),o($Vb,[2,25]),o($Vb,[2,11]),o($Vb,[2,9]),o($Vb,[2,27]),o($Vb,[2,13]),o($Vb,[2,10]),o($Vb,[2,12])],
defaultActions: {20:[2,1],21:[2,4],22:[2,3]},
parseError: function parseError(str, hash) {
    if (hash.recoverable) {
        this.trace(str);
    } else {
        function _parseError (msg, hash) {
            this.message = msg;
            this.hash = hash;
        }
        _parseError.prototype = Error;

        throw new _parseError(str, hash);
    }
},
parse: function parse(input) {
    var self = this, stack = [0], tstack = [], vstack = [null], lstack = [], table = this.table, yytext = '', yylineno = 0, yyleng = 0, recovering = 0, TERROR = 2, EOF = 1;
    var args = lstack.slice.call(arguments, 1);
    var lexer = Object.create(this.lexer);
    var sharedState = { yy: {} };
    for (var k in this.yy) {
        if (Object.prototype.hasOwnProperty.call(this.yy, k)) {
            sharedState.yy[k] = this.yy[k];
        }
    }
    lexer.setInput(input, sharedState.yy);
    sharedState.yy.lexer = lexer;
    sharedState.yy.parser = this;
    if (typeof lexer.yylloc == 'undefined') {
        lexer.yylloc = {};
    }
    var yyloc = lexer.yylloc;
    lstack.push(yyloc);
    var ranges = lexer.options && lexer.options.ranges;
    if (typeof sharedState.yy.parseError === 'function') {
        this.parseError = sharedState.yy.parseError;
    } else {
        this.parseError = Object.getPrototypeOf(this).parseError;
    }
    function popStack(n) {
        stack.length = stack.length - 2 * n;
        vstack.length = vstack.length - n;
        lstack.length = lstack.length - n;
    }
    _token_stack:
        var lex = function () {
            var token;
            token = lexer.lex() || EOF;
            if (typeof token !== 'number') {
                token = self.symbols_[token] || token;
            }
            return token;
        };
    var symbol, preErrorSymbol, state, action, a, r, yyval = {}, p, len, newState, expected;
    while (true) {
        state = stack[stack.length - 1];
        if (this.defaultActions[state]) {
            action = this.defaultActions[state];
        } else {
            if (symbol === null || typeof symbol == 'undefined') {
                symbol = lex();
            }
            action = table[state] && table[state][symbol];
        }
                    if (typeof action === 'undefined' || !action.length || !action[0]) {
                var errStr = '';
                expected = [];
                for (p in table[state]) {
                    if (this.terminals_[p] && p > TERROR) {
                        expected.push('\'' + this.terminals_[p] + '\'');
                    }
                }
                if (lexer.showPosition) {
                    errStr = 'Parse error on line ' + (yylineno + 1) + ':\n' + lexer.showPosition() + '\nExpecting ' + expected.join(', ') + ', got \'' + (this.terminals_[symbol] || symbol) + '\'';
                } else {
                    errStr = 'Parse error on line ' + (yylineno + 1) + ': Unexpected ' + (symbol == EOF ? 'end of input' : '\'' + (this.terminals_[symbol] || symbol) + '\'');
                }
                this.parseError(errStr, {
                    text: lexer.match,
                    token: this.terminals_[symbol] || symbol,
                    line: lexer.yylineno,
                    loc: yyloc,
                    expected: expected
                });
            }
        if (action[0] instanceof Array && action.length > 1) {
            throw new Error('Parse Error: multiple actions possible at state: ' + state + ', token: ' + symbol);
        }
        switch (action[0]) {
        case 1:
            stack.push(symbol);
            vstack.push(lexer.yytext);
            lstack.push(lexer.yylloc);
            stack.push(action[1]);
            symbol = null;
            if (!preErrorSymbol) {
                yyleng = lexer.yyleng;
                yytext = lexer.yytext;
                yylineno = lexer.yylineno;
                yyloc = lexer.yylloc;
                if (recovering > 0) {
                    recovering--;
                }
            } else {
                symbol = preErrorSymbol;
                preErrorSymbol = null;
            }
            break;
        case 2:
            len = this.productions_[action[1]][1];
            yyval.$ = vstack[vstack.length - len];
            yyval._$ = {
                first_line: lstack[lstack.length - (len || 1)].first_line,
                last_line: lstack[lstack.length - 1].last_line,
                first_column: lstack[lstack.length - (len || 1)].first_column,
                last_column: lstack[lstack.length - 1].last_column
            };
            if (ranges) {
                yyval._$.range = [
                    lstack[lstack.length - (len || 1)].range[0],
                    lstack[lstack.length - 1].range[1]
                ];
            }
            r = this.performAction.apply(yyval, [
                yytext,
                yyleng,
                yylineno,
                sharedState.yy,
                action[1],
                vstack,
                lstack
            ].concat(args));
            if (typeof r !== 'undefined') {
                return r;
            }
            if (len) {
                stack = stack.slice(0, -1 * len * 2);
                vstack = vstack.slice(0, -1 * len);
                lstack = lstack.slice(0, -1 * len);
            }
            stack.push(this.productions_[action[1]][0]);
            vstack.push(yyval.$);
            lstack.push(yyval._$);
            newState = table[stack[stack.length - 2]][stack[stack.length - 1]];
            stack.push(newState);
            break;
        case 3:
            return true;
        }
    }
    return true;
}};
/* generated by jison-lex 0.3.4 */
var lexer = (function(){
var lexer = ({

EOF:1,

parseError:function parseError(str, hash) {
        if (this.yy.parser) {
            this.yy.parser.parseError(str, hash);
        } else {
            throw new Error(str);
        }
    },

// resets the lexer, sets new input
setInput:function (input, yy) {
        this.yy = yy || this.yy || {};
        this._input = input;
        this._more = this._backtrack = this.done = false;
        this.yylineno = this.yyleng = 0;
        this.yytext = this.matched = this.match = '';
        this.conditionStack = ['INITIAL'];
        this.yylloc = {
            first_line: 1,
            first_column: 0,
            last_line: 1,
            last_column: 0
        };
        if (this.options.ranges) {
            this.yylloc.range = [0,0];
        }
        this.offset = 0;
        return this;
    },

// consumes and returns one char from the input
input:function () {
        var ch = this._input[0];
        this.yytext += ch;
        this.yyleng++;
        this.offset++;
        this.match += ch;
        this.matched += ch;
        var lines = ch.match(/(?:\r\n?|\n).*/g);
        if (lines) {
            this.yylineno++;
            this.yylloc.last_line++;
        } else {
            this.yylloc.last_column++;
        }
        if (this.options.ranges) {
            this.yylloc.range[1]++;
        }

        this._input = this._input.slice(1);
        return ch;
    },

// unshifts one char (or a string) into the input
unput:function (ch) {
        var len = ch.length;
        var lines = ch.split(/(?:\r\n?|\n)/g);

        this._input = ch + this._input;
        this.yytext = this.yytext.substr(0, this.yytext.length - len);
        //this.yyleng -= len;
        this.offset -= len;
        var oldLines = this.match.split(/(?:\r\n?|\n)/g);
        this.match = this.match.substr(0, this.match.length - 1);
        this.matched = this.matched.substr(0, this.matched.length - 1);

        if (lines.length - 1) {
            this.yylineno -= lines.length - 1;
        }
        var r = this.yylloc.range;

        this.yylloc = {
            first_line: this.yylloc.first_line,
            last_line: this.yylineno + 1,
            first_column: this.yylloc.first_column,
            last_column: lines ?
                (lines.length === oldLines.length ? this.yylloc.first_column : 0)
                 + oldLines[oldLines.length - lines.length].length - lines[0].length :
              this.yylloc.first_column - len
        };

        if (this.options.ranges) {
            this.yylloc.range = [r[0], r[0] + this.yyleng - len];
        }
        this.yyleng = this.yytext.length;
        return this;
    },

// When called from action, caches matched text and appends it on next action
more:function () {
        this._more = true;
        return this;
    },

// When called from action, signals the lexer that this rule fails to match the input, so the next matching rule (regex) should be tested instead.
reject:function () {
        if (this.options.backtrack_lexer) {
            this._backtrack = true;
        } else {
            return this.parseError('Lexical error on line ' + (this.yylineno + 1) + '. You can only invoke reject() in the lexer when the lexer is of the backtracking persuasion (options.backtrack_lexer = true).\n' + this.showPosition(), {
                text: "",
                token: null,
                line: this.yylineno
            });

        }
        return this;
    },

// retain first n characters of the match
less:function (n) {
        this.unput(this.match.slice(n));
    },

// displays already matched input, i.e. for error messages
pastInput:function () {
        var past = this.matched.substr(0, this.matched.length - this.match.length);
        return (past.length > 20 ? '...':'') + past.substr(-20).replace(/\n/g, "");
    },

// displays upcoming input, i.e. for error messages
upcomingInput:function () {
        var next = this.match;
        if (next.length < 20) {
            next += this._input.substr(0, 20-next.length);
        }
        return (next.substr(0,20) + (next.length > 20 ? '...' : '')).replace(/\n/g, "");
    },

// displays the character position where the lexing error occurred, i.e. for error messages
showPosition:function () {
        var pre = this.pastInput();
        var c = new Array(pre.length + 1).join("-");
        return pre + this.upcomingInput() + "\n" + c + "^";
    },

// test the lexed token: return FALSE when not a match, otherwise return token
test_match:function (match, indexed_rule) {
        var token,
            lines,
            backup;

        if (this.options.backtrack_lexer) {
            // save context
            backup = {
                yylineno: this.yylineno,
                yylloc: {
                    first_line: this.yylloc.first_line,
                    last_line: this.last_line,
                    first_column: this.yylloc.first_column,
                    last_column: this.yylloc.last_column
                },
                yytext: this.yytext,
                match: this.match,
                matches: this.matches,
                matched: this.matched,
                yyleng: this.yyleng,
                offset: this.offset,
                _more: this._more,
                _input: this._input,
                yy: this.yy,
                conditionStack: this.conditionStack.slice(0),
                done: this.done
            };
            if (this.options.ranges) {
                backup.yylloc.range = this.yylloc.range.slice(0);
            }
        }

        lines = match[0].match(/(?:\r\n?|\n).*/g);
        if (lines) {
            this.yylineno += lines.length;
        }
        this.yylloc = {
            first_line: this.yylloc.last_line,
            last_line: this.yylineno + 1,
            first_column: this.yylloc.last_column,
            last_column: lines ?
                         lines[lines.length - 1].length - lines[lines.length - 1].match(/\r?\n?/)[0].length :
                         this.yylloc.last_column + match[0].length
        };
        this.yytext += match[0];
        this.match += match[0];
        this.matches = match;
        this.yyleng = this.yytext.length;
        if (this.options.ranges) {
            this.yylloc.range = [this.offset, this.offset += this.yyleng];
        }
        this._more = false;
        this._backtrack = false;
        this._input = this._input.slice(match[0].length);
        this.matched += match[0];
        token = this.performAction.call(this, this.yy, this, indexed_rule, this.conditionStack[this.conditionStack.length - 1]);
        if (this.done && this._input) {
            this.done = false;
        }
        if (token) {
            return token;
        } else if (this._backtrack) {
            // recover context
            for (var k in backup) {
                this[k] = backup[k];
            }
            return false; // rule action called reject() implying the next rule should be tested instead.
        }
        return false;
    },

// return next match in input
next:function () {
        if (this.done) {
            return this.EOF;
        }
        if (!this._input) {
            this.done = true;
        }

        var token,
            match,
            tempMatch,
            index;
        if (!this._more) {
            this.yytext = '';
            this.match = '';
        }
        var rules = this._currentRules();
        for (var i = 0; i < rules.length; i++) {
            tempMatch = this._input.match(this.rules[rules[i]]);
            if (tempMatch && (!match || tempMatch[0].length > match[0].length)) {
                match = tempMatch;
                index = i;
                if (this.options.backtrack_lexer) {
                    token = this.test_match(tempMatch, rules[i]);
                    if (token !== false) {
                        return token;
                    } else if (this._backtrack) {
                        match = false;
                        continue; // rule action called reject() implying a rule MISmatch.
                    } else {
                        // else: this is a lexer rule which consumes input without producing a token (e.g. whitespace)
                        return false;
                    }
                } else if (!this.options.flex) {
                    break;
                }
            }
        }
        if (match) {
            token = this.test_match(match, rules[index]);
            if (token !== false) {
                return token;
            }
            // else: this is a lexer rule which consumes input without producing a token (e.g. whitespace)
            return false;
        }
        if (this._input === "") {
            return this.EOF;
        } else {
            return this.parseError('Lexical error on line ' + (this.yylineno + 1) + '. Unrecognized text.\n' + this.showPosition(), {
                text: "",
                token: null,
                line: this.yylineno
            });
        }
    },

// return next match that has a token
lex:function lex() {
        var r = this.next();
        if (r) {
            return r;
        } else {
            return this.lex();
        }
    },

// activates a new lexer condition state (pushes the new lexer condition state onto the condition stack)
begin:function begin(condition) {
        this.conditionStack.push(condition);
    },

// pop the previously active lexer condition state off the condition stack
popState:function popState() {
        var n = this.conditionStack.length - 1;
        if (n > 0) {
            return this.conditionStack.pop();
        } else {
            return this.conditionStack[0];
        }
    },

// produce the lexer rule set which is active for the currently active lexer condition state
_currentRules:function _currentRules() {
        if (this.conditionStack.length && this.conditionStack[this.conditionStack.length - 1]) {
            return this.conditions[this.conditionStack[this.conditionStack.length - 1]].rules;
        } else {
            return this.conditions["INITIAL"].rules;
        }
    },

// return the currently active lexer condition state; when an index argument is provided it produces the N-th previous condition state, if available
topState:function topState(n) {
        n = this.conditionStack.length - 1 - Math.abs(n || 0);
        if (n >= 0) {
            return this.conditionStack[n];
        } else {
            return "INITIAL";
        }
    },

// alias for begin(condition)
pushState:function pushState(condition) {
        this.begin(condition);
    },

// return the number of states currently on the stack
stateStackSize:function stateStackSize() {
        return this.conditionStack.length;
    },
options: {"flex":true,"case-insensitive":true},
performAction: function anonymous(yy,yy_,$avoiding_name_collisions,YY_START) {
var YYSTATE=YY_START;
switch($avoiding_name_collisions) {
case 0: yy_.yytext = yy.lexer.matches[1];  return 22; 
break;
case 1: yy_.yytext = yy.lexer.matches[1]+"-"+yy.lexer.matches[2];  
      return 22; 
    
break;
case 2: yy_.yytext = yy.lexer.matches[1]+"-"+yy.lexer.matches[2];  
      return 22; 
    
break;
case 3: yy_.yytext = yy.lexer.matches[1];
      return 22; 
break;
case 4: return 16; 
break;
case 5: return 17; 
break;
case 6: return 19; 
break;
case 7: return 18; 
break;
case 8: return 7; 
break;
case 9: yy_.yytext = 'contradiction';
      return 10; 
break;
case 10: yy_.yytext = 'or';
      return 10; 
break;
case 11: yy_.yytext = 'identity';
      return 10; 
break;
case 12: yy_.yytext = 'and';
      return 10; 
break;
case 13: yy_.yytext = 'double_arrow';
      return 10; 
break;
case 14: yy_.yytext = 'arrow';
      return 10; 
break;
case 15: yy_.yytext = 'not';
      return 10; 
break;
case 16: yy_.yytext = 'reit';
      return 23; 
break;
case 17: yy_.yytext = 'premise';
      return 24; 
break;
case 18: yy_.yytext = 'weakening';return 10; 
break;
case 19: yy_.yytext = 'cases';return 10; 
break;
case 20: yy_.yytext = 'DC';return 10; 
break;
case 21: yy_.yytext = 'reductio';return 10; 
break;
case 22: yy_.yytext = 'DM';return 10; 
break;
case 23: yy_.yytext = 'contraposition';return 10; 
break;
case 24: yy_.yytext = 'C';return 10; 
break;
case 25: yy_.yytext = 'contradiction';return 10; 
break;
case 26: yy_.yytext = 'not-all' ;return 10; 
break;
case 27: yy_.yytext = 'all-not';return 10; 
break;
case 28: yy_.yytext = 'exists-not';return 10; 
break;
case 29: yy_.yytext = 'not-exists' ;return 10; 
break;
case 30: yy_.yytext = 'dilemma';return 10; 
break;
case 31: yy_.yytext = 'modus-tollens';return 10; 
break;
case 32: yy_.yytext = 'hypothetical-syllogism';return 10; 
break;
case 33: yy_.yytext = 'disjunctive-syllogism';return 10; 
break;
case 34: yy_.yytext = 'commutivity';return 10; 
break;
case 35: yy_.yytext = 'double-negation';return 10; 
break;
case 36: yy_.yytext = "material-conditional";return 10; 
break;
case 37: yy_.yytext = 'biconditional-exchange';return 10; 
break;
case 38: yy_.yytext = 'quantifier-negation';return 10; 
break;
case 39: yy_.yytext = 'implication';return 10; 
break;
case 40: yy_.yytext = 'transposition';return 10; 
break;
case 41: yy_.yytext = 'distribution';return 10; 
break;
case 42: yy_.yytext = 'association';return 10; 
break;
case 43: yy_.yytext = 'idempotence';return 10; 
break;
case 44: yy_.yytext = 'exportation';return 10; 
break;
case 45: yy_.yytext = 'equivalence';return 10; 
break;
case 46: yy_.yytext = 'not_double_arrow';return 10; 
break;
case 47: yy_.yytext = 'not_and';return 10; 
break;
case 48: yy_.yytext = 'not_or';return 10; 
break;
case 49: yy_.yytext = 'not_arrow' ;return 10; 
break;
case 50: yy_.yytext = 'universal';
      return 10; 
break;
case 51: yy_.yytext = 'existential';
      return 10; 
break;
case 52: return 20; 
break;
case 53: return 21; 
break;
case 54: yy_.yytext = 'close-branch';return 10; 
break;
case 55: yy_.yytext = 'open-branch';return 10; 
break;
case 56: /*  Skip whitespace and commas. 
      */ 
    
break;
case 57: return 5; 
break;
case 58: 
      /*  I would love to `return 'waffle';` and treat
          waffle as a category because I want to allow 
          some of the connectives to appear in waffle, e.g. 'not'.
          But attempts to do this proved too tricky for me so far.
      */ 
    
break;
case 59: /* Ignore everything else */ 
break;
case 60:console.log(yy_.yytext);
break;
}
},
rules: [/^(?:([0-9][^,\s]*)(\s+and\s+)(?=[0-9]))/i,/^(?:([0-9][^,\s]*)\s+to\s+([0-9][^,\s]*))/i,/^(?:([0-9][^,\s]*?)\s*(?:-+)\s*([0-9][^,\s]*))/i,/^(?:([0-9][^,\s]*)(?:(\s*,)*))/i,/^(?:elimination|eliminate|elim|e)/i,/^(?:introduction|introduce|intro|i)/i,/^(?:decomposition-2|decomposition2|d-2|d2)/i,/^(?:decomposition|d)/i,/^(?:✓|tick)/i,/^(?:⊥|_\|_|contradiction|contra|false)/i,/^(?:or|∨|\+|ǀǀ|\|)/i,/^(?:=|identity)/i,/^(?:and|conjunction|∧|•|&)/i,/^(?:double_arrow|↔|≡|⇔|<->)/i,/^(?:arrow|->|⇒|→|⊃)/i,/^(?:not|¬|˜|~|!|negation)/i,/^(?:reit|reiteration|r)/i,/^(?:premise|assumption|set member|sm|p)/i,/^(?:weakening|w)/i,/^(?:argument by cases|cases|ac)/i,/^(?:denying the consequent|dc)/i,/^(?:reductio|rd|reductio ad absurdum)/i,/^(?:dm|deMorgan|dem|de morgan)/i,/^(?:contraposition|cp)/i,/^(?:conditional|c)/i,/^(?:cd)/i,/^(?:(negated|not_|not-|not|~|¬|!)(\s)?(all|∀|every|universal))/i,/^(?:all not|all-not|∀~)/i,/^(?:exists not|exists-not|∃~)/i,/^(?:(negated|not_|not-|not|~|¬|!)(\s)?(some|exists|∃|existential))/i,/^(?:dilemma|dil)/i,/^(?:mt|modus tollens|modus-tollens)/i,/^(?:hs|hypothetical syllogism|hypothetical-syllogism)/i,/^(?:ds|disjunctive syllogism|disjunctive-syllogism)/i,/^(?:commutivity|comm|com)/i,/^(?:dn|double-negation|double negation|negated negation|negated-negation|~~|~ ~|¬¬|¬ ¬|not not)/i,/^(?:mc|material-conditional|material conditional)/i,/^(?:bex|↔ex|biconditional-exchange|biconditional exchange)/i,/^(?:qn|quantifier-negation|quantifier negation)/i,/^(?:implication|impl)/i,/^(?:transposition|trans)/i,/^(?:distribution|dist)/i,/^(?:association|assoc)/i,/^(?:idempotence|idem)/i,/^(?:exportation|exp)/i,/^(?:equivalence|equiv)/i,/^(?:not_double_arrow|negated biconditional|negated-biconditional|not <->|~ <->|~<->|not<->|~↔|~≡|~ ↔|~ ≡|¬↔|¬≡|¬ ↔|¬ ≡)/i,/^(?:(negated|not_|not|~|¬|!)(\s)?(and|conjunction|∧|•|&))/i,/^(?:(negated|not_|not|~|¬|!)(\s)?(disjunction|or|∨|\|))/i,/^(?:(negated|not_|not|~|¬|!)(\s)?(conditional|arrow|->|⇒|→|⊃))/i,/^(?:all|∀|every|universal)/i,/^(?:some|exists|∃|existential)/i,/^(?:left)/i,/^(?:right)/i,/^(?:close branch|close-branch)/i,/^(?:open branch|open-branch)/i,/^(?:[\s,]+)/i,/^(?:$)/i,/^(?:\w+)/i,/^(?:.)/i,/^(?:.)/i],
conditions: {"INITIAL":{"rules":[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60],"inclusive":true}}
});
return lexer;
})();
parser.lexer = lexer;
function Parser () {
  this.yy = {};
}
Parser.prototype = parser;parser.Parser = Parser;
return new Parser;
})();


if (typeof require !== 'undefined' && typeof exports !== 'undefined') {
exports.parser = justification_parser;
exports.Parser = justification_parser.Parser;
exports.parse = function () { return justification_parser.parse.apply(justification_parser, arguments); };
exports.main = function commonjsMain(args) {
    if (!args[1]) {
        console.log('Usage: '+args[0]+' FILE');
        process.exit(1);
    }
    var source = require('fs').readFileSync(require('path').normalize(args[1]), "utf8");
    return exports.parser.parse(source);
};
if (typeof module !== 'undefined' && require.main === module) {
  exports.main(process.argv.slice(1));
}
}