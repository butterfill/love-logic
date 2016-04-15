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
var tellerFOL = (function(){
var o=function(k,v,o,l){for(o=o||{},l=k.length;l--;o[k[l]]=v);return o},$V0=[1,4],$V1=[1,5],$V2=[1,6],$V3=[1,7],$V4=[1,9],$V5=[1,12],$V6=[1,13],$V7=[1,18],$V8=[1,19],$V9=[1,14],$Va=[1,15],$Vb=[1,17],$Vc=[1,21],$Vd=[1,22],$Ve=[1,23],$Vf=[1,24],$Vg=[1,25],$Vh=[1,26],$Vi=[1,27],$Vj=[1,30],$Vk=[5,10,12,13,14,15,16,17,26,27,38],$Vl=[1,37],$Vm=[5,10,12,13,14,15,16,17,26,27,38,39],$Vn=[5,10,12,13,14,15,16,17,25,26,27,32,33,34,35,36,38,39],$Vo=[5,10,12,13,14,15,16,17,27,38],$Vp=[5,10,27,38],$Vq=[27,38];
var parser = {trace: function trace() { },
yy: {},
symbols_: {"error":2,"expressions":3,"e":4,"EOF":5,"box":6,"(":7,"existential_quantifier":8,"quantifier_variable":9,")":10,"universal_quantifier":11,"and":12,"or":13,"nand":14,"nor":15,"arrow":16,"double_arrow":17,"not":18,"true":19,"false":20,"sentence_letter_or_expression_variable":21,"predicate":22,"termlist":23,"term":24,"identity":25,"[":26,"]":27,"substitution_list":28,"expression_variable":29,"sentence_letter":30,"variable_or_metavariable":31,"variable":32,"term_metavariable":33,"name":34,"name_hat":35,"term_metavariable_hat":36,"substitution":37,",":38,"substitution_symbol":39,"null":40,"$accept":0,"$end":1},
terminals_: {2:"error",5:"EOF",7:"(",8:"existential_quantifier",10:")",11:"universal_quantifier",12:"and",13:"or",14:"nand",15:"nor",16:"arrow",17:"double_arrow",18:"not",19:"true",20:"false",22:"predicate",25:"identity",26:"[",27:"]",29:"expression_variable",30:"sentence_letter",32:"variable",33:"term_metavariable",34:"name",35:"name_hat",36:"term_metavariable_hat",38:",",39:"substitution_symbol",40:"null"},
productions_: [0,[3,2],[3,2],[3,3],[4,5],[4,5],[4,3],[4,3],[4,3],[4,3],[4,3],[4,3],[4,2],[4,1],[4,1],[4,1],[4,2],[4,3],[4,3],[4,3],[4,4],[21,1],[21,1],[31,1],[31,1],[9,1],[23,1],[23,2],[24,1],[24,1],[24,1],[24,1],[28,1],[28,3],[37,3],[37,3],[37,3],[37,3],[6,3]],
performAction: function anonymous(yytext, yyleng, yylineno, yy, yystate /* action[1] */, $$ /* vstack */, _$ /* lstack */) {
/* this == yyval */

var $0 = $$.length - 1;
switch (yystate) {
case 1: case 2:
 return $$[$0-1]; 
break;
case 3:
 $$[$0-1].box = $$[$0-2]; return $$[$0-1]; 
break;
case 4:
 this.$ = {type:"existential_quantifier", symbol:$$[$0-3], location:_$[$0-3], boundVariable:$$[$0-2], left:$$[$0], right:null}; 
break;
case 5:
 this.$ = {type:"universal_quantifier", symbol:$$[$0-3], location:_$[$0-3], boundVariable:$$[$0-2], left:$$[$0], right:null}; 
break;
case 6:
 this.$ = {type:'and', symbol:$$[$0-1], location:_$[$0-1], left:$$[$0-2], right:$$[$0]}; 
break;
case 7:
 this.$ = {type:'or', symbol:$$[$0-1], location:_$[$0-1], left:$$[$0-2], right:$$[$0]}; 
break;
case 8:
 this.$ = {type:'nand', symbol:$$[$0-1], location:_$[$0-1], left:$$[$0-2], right:$$[$0]}; 
break;
case 9:
 this.$ = {type:'nor', symbol:$$[$0-1], location:_$[$0-1], left:$$[$0-2], right:$$[$0]}; 
break;
case 10:
 this.$ = {type:'arrow', symbol:$$[$0-1], location:_$[$0-1], left:$$[$0-2], right:$$[$0]}; 
break;
case 11:
 this.$ = {type:'double_arrow', symbol:$$[$0-1], location:_$[$0-1], left:$$[$0-2], right:$$[$0]}; 
break;
case 12:
 this.$ = {type:'not', symbol:$$[$0-1], location:_$[$0-1], left:$$[$0], right:null}; 
break;
case 13:
 this.$ = {type:'value', symbol:$$[$0], location:_$[$0], value:true, left:null, right:null}; 
break;
case 14:
 this.$ = {type:'value', symbol:$$[$0], location:_$[$0], value:false, left:null, right:null}; 
break;
case 15: case 25: case 30:
 this.$ = $$[$0]; 
break;
case 16:
 this.$ = { type:'predicate', name:$$[$0-1], location:_$[$0-1], termlist:$$[$0] } ; 
break;
case 17:
 this.$ = {type:'identity', symbol:$$[$0-1], termlist:[$$[$0-2], $$[$0]] }; 
break;
case 18: case 19:
 this.$ = $$[$0-1]; 
break;
case 20:

         if( $$[$0-3].substitutions && $$[$0-3].substitutions.length ) {
           $$[$0-3].substitutions = $$[$0-3].substitutions.concat($$[$0-1]);
         } else {
           $$[$0-3].substitutions = $$[$0-1];
         }
         this.$ = $$[$0-3]; 
      
break;
case 21:
 this.$ = {type:'expression_variable', location:_$[$0], letter:$$[$0], left:null, right:null}; 
break;
case 22:
 this.$ = {type:'sentence_letter', location:_$[$0], letter:$$[$0], left:null, right:null}; 
break;
case 23:
 this.$ = {type:'variable', name:$$[$0], location:_$[$0]}; 
break;
case 24:
 this.$ = {type:'term_metavariable', name:$$[$0], location:_$[$0]}; 
break;
case 26: case 32:
 this.$ = [$$[$0]] 
break;
case 27:
 this.$ = [$$[$0-1]].concat($$[$0]) 
break;
case 28:
 this.$ = {type:'name', name:$$[$0], location:_$[$0]}; 
break;
case 29:
 this.$ = {type:'name_hat', name:$$[$0], location:_$[$0]}; 
break;
case 31:
 this.$ = {type:'term_metavariable_hat', name:$$[$0], location:_$[$0]}; 
break;
case 33:
 this.$ = [$$[$0-2]].concat($$[$0]) 
break;
case 34: case 36:
 this.$ = {type:'substitution', from:$$[$0-2], to:$$[$0], symbol:$$[$0-1]}; 
break;
case 35: case 37:
 this.$ = {type:'substitution', from:$$[$0-2], to:null, symbol:$$[$0-1]}; 
break;
case 38:
 this.$ = {type:'box', term:$$[$0-1]}; 
break;
}
},
table: [{3:1,4:2,6:3,7:$V0,18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:10,26:[1,11],29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},{1:[3]},{5:[1,20],12:$Vc,13:$Vd,14:$Ve,15:$Vf,16:$Vg,17:$Vh,26:$Vi},{4:29,5:[1,28],7:$V0,18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:10,26:$Vj,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},{4:33,7:$V0,8:[1,31],11:[1,32],18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:10,26:$Vj,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},{4:34,7:$V0,18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:10,26:$Vj,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},o($Vk,[2,13]),o($Vk,[2,14]),o($Vk,[2,15]),{23:35,24:36,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},{25:$Vl},{4:38,7:$V0,18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:39,26:$Vj,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},o($Vm,[2,21]),o($Vm,[2,22]),o($Vn,[2,28]),o($Vn,[2,29]),o($Vn,[2,30]),o($Vn,[2,31]),o($Vn,[2,23]),o($Vn,[2,24]),{1:[2,1]},{4:40,7:$V0,18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:10,26:$Vj,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},{4:41,7:$V0,18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:10,26:$Vj,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},{4:42,7:$V0,18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:10,26:$Vj,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},{4:43,7:$V0,18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:10,26:$Vj,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},{4:44,7:$V0,18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:10,26:$Vj,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},{4:45,7:$V0,18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:10,26:$Vj,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},{21:49,24:48,28:46,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb,37:47},{1:[2,2]},{5:[1,50],12:$Vc,13:$Vd,14:$Ve,15:$Vf,16:$Vg,17:$Vh,26:$Vi},{4:38,7:$V0,18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:10,26:$Vj,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},{9:51,31:52,32:$V7,33:$V8},{9:53,31:52,32:$V7,33:$V8},{10:[1,54],12:$Vc,13:$Vd,14:$Ve,15:$Vf,16:$Vg,17:$Vh,26:$Vi},o($Vo,[2,12],{26:$Vi}),o($Vk,[2,16]),o($Vk,[2,26],{31:16,24:36,23:55,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb}),{24:56,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},{12:$Vc,13:$Vd,14:$Ve,15:$Vf,16:$Vg,17:$Vh,26:$Vi,27:[1,57]},{25:$Vl,27:[1,58]},o($Vo,[2,6],{26:$Vi}),o($Vo,[2,7],{26:$Vi}),o($Vo,[2,8],{26:$Vi}),o($Vo,[2,9],{26:$Vi}),o($Vp,[2,10],{12:$Vc,13:$Vd,14:$Ve,15:$Vf,26:$Vi}),o($Vp,[2,11],{12:$Vc,13:$Vd,14:$Ve,15:$Vf,26:$Vi}),{27:[1,59]},{27:[2,32],38:[1,60]},{39:[1,61]},{39:[1,62]},{1:[2,3]},{10:[1,63]},{10:[2,25]},{10:[1,64]},o($Vk,[2,18]),o($Vk,[2,27]),o($Vk,[2,17]),o($Vk,[2,19]),o([5,7,18,19,20,22,26,29,30,32,33,34,35,36],[2,38]),o($Vk,[2,20]),{21:49,24:48,28:65,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb,37:47},{24:66,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb,40:[1,67]},{4:68,7:$V0,18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:10,26:$Vj,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb,40:[1,69]},{4:70,7:$V0,18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:10,26:$Vj,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},{4:71,7:$V0,18:$V1,19:$V2,20:$V3,21:8,22:$V4,24:10,26:$Vj,29:$V5,30:$V6,31:16,32:$V7,33:$V8,34:$V9,35:$Va,36:$Vb},{27:[2,33]},o($Vq,[2,34]),o($Vq,[2,35]),o($Vq,[2,36],{12:$Vc,13:$Vd,14:$Ve,15:$Vf,16:$Vg,17:$Vh,26:$Vi}),o($Vq,[2,37]),o($Vo,[2,4],{26:$Vi}),o($Vo,[2,5],{26:$Vi})],
defaultActions: {20:[2,1],28:[2,2],50:[2,3],52:[2,25],65:[2,33]},
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
options: {},
performAction: function anonymous(yy,yy_,$avoiding_name_collisions,YY_START) {
var YYSTATE=YY_START;
switch($avoiding_name_collisions) {
case 0: /* skip whitespace */             
break;
case 1: return 7; 
break;
case 2: return 10; 
break;
case 3: return 26; 
break;
case 4: return 27; 
break;
case 5: return 38; 
break;
case 6: return 22;               
break;
case 7: return 39; 
break;
case 8: return 19; 
break;
case 9: return 20; 
break;
case 10: return 25; 
break;
case 11: return 12; 
break;
case 12: return 16; 
break;
case 13: return 17; 
break;
case 14: return 13; 
break;
case 15: return 18; 
break;
case 16: return 15; 
break;
case 17: return 14; 
break;
case 18: return 11; 
break;
case 19: return 8; 
break;
case 20: return 30; 
break;
case 21: return 40; 
break;
case 22: return 35; 
break;
case 23: return 34; 
break;
case 24: return 32; 
break;
case 25: return 29; 
break;
case 26: return 36; 
break;
case 27: return 33; 
break;
case 28: return 5; 
break;
case 29: return 'invalid_character'; 
break;
}
},
rules: [/^(?:\s+)/,/^(?:\()/,/^(?:\))/,/^(?:\[)/,/^(?:\])/,/^(?:,)/,/^(?:[A-Z][0-9]*(?=([a-zαβγτ]+)))/,/^(?:-->)/,/^(?:true\b)/,/^(?:false|⊥|_\|_|contradiction|contra\b)/,/^(?:=)/,/^(?:and|&|∧|•)/,/^(?:arrow|->|⇒|→|⊃)/,/^(?:↔|≡|⇔|double_arrow|<->)/,/^(?:or|∨|\+|ǀǀ|\|)/,/^(?:not|¬|~|˜|!)/,/^(?:nor|↓)/,/^(?:nand|↑)/,/^(?:all|∀|every\b)/,/^(?:some|exists|∃)/,/^(?:[A-Z][0-9]*)/,/^(?:[nN][uU][lL][lL])/,/^(?:[a-r][0-9]*\^)/,/^(?:[a-r][0-9]*)/,/^(?:[xyzw][0-9]*)/,/^(?:[φψχ][0-9]*)/,/^(?:[αβγτ][0-9]*\^)/,/^(?:[αβγτ][0-9]*)/,/^(?:$)/,/^(?:.)/],
conditions: {"expectLeftBracket":{"rules":[],"inclusive":false},"INITIAL":{"rules":[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29],"inclusive":true}}
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
exports.parser = tellerFOL;
exports.Parser = tellerFOL.Parser;
exports.parse = function () { return tellerFOL.parse.apply(tellerFOL, arguments); };
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