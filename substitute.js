/**
 * apply substitutions to formulae like
 * ['not', ['not', '$1']] > '$1'
 * ['not', ['and', '$1', '$2' ]] > ['or', ['not','$1'], ['not','$2']]
 *
 *
 * terminology for parameter values:
 *  - a phrase is a piece of parsed FOL (e.g. ['not', ['not', 'P']])
 *  - a variable is a string prefixed with $, e.g. '$1'
 *  - a match is a piece of parsed FOL with zero or more elements replaced by
 *      variables (e.g. ['not', ['not', '$1']])
 *  - a substitution is a map with .from and .to keys whose values are both matches
 *
 */

/**
 * testing only (TODO: remove) --- expose parser as fol (global var)
 */
require(['parse/test_boolean2'],function(){
    window.fol = test_boolean2;
    //use like fol.parse("not true")
});

require(['lib/underscore'], function(){
    
    //underscore just adds to globals
    
    function is_var(elm) {
        return typeof elm === 'string' && elm[0] === '$';
    }
    
    /**
     * @returns true iff the two phrases are the same
     * [Because phrases are arrays, this is just a deep array comparitor]
     */
    function are_identical_phrases(p1, p2) {
        if( ! _.isArray(p1) || ! _.isArray(p2) ) {
            return p1===p2;
        }
        if( p1.length !== p2.length ) {
            return false;
        }
        return _.all(p1, function(p1_elm, idx){
            var p2_elm = p2[idx];
            return are_identical_phrases(p1_elm, p2_elm);
        });
    }
    
    /**
     * @param phrase is like ['not', 'P']
     * @param match is like  ['not', ['not', '$1']] where '$.+' is a variable
     * @return false if no match, otherwise a map with each variable's match
     * Only considers the top node of phrase (not recursive)
     */
    function is_match(phrase, match, matches_) {
        matches_ = matches_ || {};   //stores $1 etc
        if( ! _.isArray(phrase) || ! _.isArray(match) ) {
            return phrase === match;
        }
        if( phrase.length !== match.length ) {
            return false;
        }
        var success = _.all(match, function(match_elm, idx) {
            var phrase_elm = phrase[idx];
            if( is_var(match_elm) ) {
                var key = match_elm;
                if( key in matches_ ) {
                    //every instance of a variable must match the same thing
                    if( !are_identical_phrases( matches_[key], phrase_elm ) ) {
                        return false;
                    }
                }
                matches_[key] = phrase_elm;
                console.log('matched '+key+' = '+matches_[key]);
                return true;
            }
            if( match_elm === phrase_elm ) {
                return true;
            }
            if( _.isArray(match_elm) && _.isArray(match_elm) ) {
                return is_match(phrase_elm, match_elm, matches_);
            }
            return false;
        });
        return ( success ? matches_ : false );
    }
    
    /**
     * @param match is like  ['not', ['not', '$1']] where '$.+' is a variable
     * @param matches is like {$1:['not','P']}
     * @return a phrase with variables replaced by their matches
     */
    function replace(match, matches) {
        if(  _.isArray(match) ) {
            //apply replace to each element of the array and return result
            return _.map(
                match,
                function(elm) {
                    return replace(elm, matches);
                } 
            );
        }
        // match is a leaf (not an arrayl.)
        var leaf = match;
        if( is_var(leaf) ) {
            return matches[leaf];
        }
        return leaf;
    }
    
    /**
     * recursively substitute all instances of from_match with to_match
     * @param sub is a map containing .from and .to, which are both matches
     */
    function substitute(phrase, sub) {
        var matches = is_match(phrase, sub.from);
        if( matches ) {
            phrase = replace(sub.to, matches);
        }
        if( ! _.isArray(phrase) ) {
            return phrase;
        }
        return _.map(phrase, function(elm){
            return substitute(elm, sub);
        });
    }
    
    var True = ['VAL', true];
    var False = ['VAL', false];
    
    /**
     * These get us to disjunctive normal form, with some simplifications
     * involving things like (True or $1) > $1
     * All of these substitutions leave the connectives as binary
     */
    var substitutions = {
        dbl_neg : {
            from : ['not',['not','$1']],
            to : '$1'
        },
        demorgan1 : {
            from : ['not', ['and', '$1', '$2' ]],
            to : ['or', ['not','$1'], ['not','$2']]
        },
        demorgan2 : {
            from : ['not', ['or', '$1', '$2' ]],
            to : ['and', ['not','$1'], ['not','$2']]
        },
        arrow : {
            from : ['arrow', '$1', '$2'],
            to : ['or', ['not', '$1'], '$2']
        },
        not_false : {
            from : ['not', False],
            to : True
        },
        not_true : {
            from : ['not', True],
            to : False
        },
        lem_left : {
            from : ['or', ['not', '$1'], '$1'],
            to : True
        },
        lem_right : {
            from : ['or', '$1', ['not', '$1']],
            to : True
        },
        contra_left : {
            from : ['and', ['not', '$1'], '$1'],
            to : False
        },
        contra_right : {
            from : ['and', '$1', ['not', '$1']],
            to : False
        },
        // false or true ... etc
        or_true_left : {
            from : ['or', True, '$1'],
            to : True
        },
        or_true_right : {
            from : ['or', '$1', True],
            to : True
        },
        or_false_left : {
            from : ['or', '$1', False],
            to : '$1'
        },
        or_false_right : {
            from : ['or', False, '$1'],
            to : '$1'
        },
        and_false_left : {
            from : ['and', False, '$1'],
            to : False
        },
        and_false_right : {
            from : ['and', '$1', False],
            to: False
        },
        and_true_left : {
            from : ['and', True, '$1'],
            to : '$1'
        },
        and_true_right : {
            from : ['and', '$1', True],
            to : '$1'
        },
        //disjunctive normal form
        dnf_left : {
            from : ['and', ['or', '$1', '$2'], '$3'],
            to : ['or', ['and', '$1', '$3'], ['and', '$2', '$3']]
        },
        dnf_right : {
            from : ['and', '$3', ['or', '$1', '$2']],
            to : ['or', ['and', '$1', '$3'], ['and', '$2', '$3']]
        }
    };
    
    /**
     * repeatedly apply fn to obj until the value fails to change according
     * to comparitor.
     * Caution: may cause hang if not used with care (nb. check comparitor)
     */
    function exhaust(fn, obj, comparitor) {
        comparitor = comparitor || are_identical_phrases; // function(a,b) { return a === b; };
        var pre = null;
        var post = obj;
        while( !comparitor(pre, post) ) {
            pre = post;
            post = fn(pre);
        }
        return post;
    }
    
    /**
     * @param subs is an array of subsitutions 
     * apply all subs to phrase in sequence, returning the result
     */
    function substitute_reduce(phrase, subs) {
        return _.reduce(
            subs,
            function(phrase, sub){  //could replace with simply subsititute
                return substitute(phrase,sub);
            },
            phrase
        );
    }
    
    /**
     * like substitute_reduce but keeps cycling through subs until none
     * yeild a change
     */
    function substitute_exhaust(phrase, subs) {
        var pre = null;
        var post = phrase;
        while( !are_identical_phrases(pre, post) ) {
            pre = post;
            post = substitute_reduce(pre, subs);
        }
        return post;
    }
    

    // -- renaming PROP variables

    /**
     * @returns true iff phrase is a PROP variable like P
     */
    function is_PROP(phrase) {
        return _.isArray(phrase) && phrase[0]==='PROP';
    }
    
    /**
     * @returns an array with the named PROP variables in a canoical order
     * (used to replace PROP variables for canonical representation)
     */
    function list_PROPs(phrase) {
        if( is_PROP(phrase) ) {
            return [phrase[1]];
        }
        if( _.isArray(phrase) ) {
            return _.reduce(
                phrase,
                function(list, elm){
                    return _.union(list, list_PROPs(elm) );
                },
                []
            );
        }
        return [];
    }
    
    function substitute_PROP(phrase, sub) {
        return substitute(phrase, {
            from : ['PROP', sub.from],
            to : ['PROP', sub.to]
        });
    }
    
    /**
     * provides a canonical renaming of propositional variables
     */
    function rename_PROPs(phrase) {
        var PROPs = list_PROPs(phrase);
        var intermediate = _.reduce(
            PROPs,
            function( phrase, PROP, idx ){
                return substitute_PROP(phrase, {
                    from : PROP,
                    to : '_'+idx    //not a legal PROP variable name
                });
            },
            phrase
        )
        return _.reduce(
            PROPs,
            function( phrase, _ignore, idx ){
                return substitute_PROP(phrase, {
                   from : '_' + idx,
                   to : 'P' + (idx+1)
                });
            },
            intermediate
        );
    }
    
    
    
    // -- stuff that involves n-ary connectives

    /**
     * convert binary connectives into n-ary connectives, flattening disjunctive
     * normal form into a tree with minimal depth
     */
    function flatten(phrase) {
        if( ! _.isArray(phrase) ) {
            return phrase;
        }
        if( phrase[0] === 'and' || phrase[0] === 'or' ) {
            //check whether any children are same connective
            var idx = 1;
            while( idx < phrase.length ) {
                var child = phrase[idx];
                if( child[0] === phrase[0] ) {
                    //connectives match: add child's con/disjuncts to parent phrase and remove child
                    phrase = phrase.concat(child.slice(1));
                    phrase.splice(idx,1);
                } else {
                    //only increase idx in this case because otherwise the splice counts as moving on
                    idx += 1;
                }
            }
        }
        return _.map(phrase, function(elem){
            return flatten(elem);
        });
    }
    
    /**
     * return phrase involving only binary connectives
     */
    function unflatten(phrase) {
        if( ! _.isArray(phrase) ) {
            return phrase;
        }
        if( phrase.length > 3 ) {
            //needs work
            var connective = phrase[0];
            var first_child = phrase[1];
            var other_children = phrase.slice(2);
            phrase = [ connective, [connective].concat(other_children), first_child ];
        }
        return _.map(phrase, function(elem){
            return unflatten(elem);
        });
    }
    
    function replace_children( phrase, new_children ) {
        return [phrase[0]].concat(new_children);
    }
    
    // much of what follows is concerned with getting to the point where
    // we have DNF where the conjuncts contain no duplicates and do not
    // contain a sentence letter and its negation
    
    /**
     * remove any duplicate conjuncts in 'and' and 'or'
     */
    function remove_duplicates(phrase) {
        if( ! _.isArray(phrase) ) {
            return phrase;
        }
        if( phrase[0] === 'and' || phrase[0] === 'or' ) {
            //check whether any children are same
            actual_children = phrase.slice(1);
            unique_children = [];
            while( actual_children.length > 0 ) {
                child = actual_children.pop();
                var is_new = _.all(unique_children, function(old_child){
                    return !are_identical_phrases(old_child, child);
                });
                if(is_new) {
                    unique_children.push(child);
                }
            }
            phrase = replace_children(phrase, unique_children);
        }
        return _.map(phrase, function(elem){
            return remove_duplicates(elem);
        });
    }
    
    function remove_double_negations( phrase ) {
        return substitute_exhaust(phrase, [substitutions.dbl_neg] );
    }
    
    /**
     * @returns true if list_of_phrases contains a formula and its negation
     */
    function contains_fmla_and_its_neg(list_of_phrases) {
        var not_negated = [];
        var negated = [];
        _.each(list_of_phrases, function(phrase) {
            if( ! _.isArray(phrase) ) {
                not_negated.push(phrase);
                return;
            }
            phrase = remove_double_negations(phrase);
            if( phrase[0] === 'not' ) {
                negated.push(phrase[1]);    //nb we add the non-negated phrase!
            } else {
                not_negated.push(phrase);
            }
        });
        //are any of the negated phrases identical to a not_negated phrase?
        return _.any(negated, function(negated_phrase){
            return _.any(not_negated, function(phrase) {
                return are_identical_phrases(negated_phrase, phrase);
            });
        });
    }

    /**
     * spots formulae and their negations in conjunctions and disjunctions
     */
    function simplify( phrase ) {
        if( ! _.isArray(phrase) ) {
            return phrase;
        }
        if( phrase[0] === 'and' || phrase[0] === 'or' ) {
            var juncts = phrase.slice(1);
            if( contains_fmla_and_its_neg(juncts) ) {
                return ( phrase[0] === 'and' ? False : True )
            }
        }
        return _.map(phrase, function(elem){
            return simplify(elem);
        })
    }
    
    /**
     * disjunctive normal form with no repeted *juncts and no *junct containg
     * a formula and its negation
     */
    function canonical(phrase) {
        var do_substitutions = function(phrase) {
            return substitute_exhaust(phrase, substitutions);
        }
        return do_substitutions(
            unflatten(
                simplify(
                    flatten(
                        do_substitutions(phrase)
                    )
                )
            )
        );
    }
    
    
    //TODO write function that will compare phrases irrespective of order of *juncts
    // (requires being able to interscet two lists with a custom comparator --- then
    //  just compare their lengths to their intersection)
    
    
    
    // -- testing only -- config for browser console
    
    window.l = {
        are_identical_phrases : are_identical_phrases,
        is_match : is_match,
        replace : replace,
        substitute : substitute,
        substitutions : substitutions,
        substitute_reduce : substitute_reduce,
        substitute_exhaust : substitute_exhaust,
        flatten : flatten,
        unflatten : unflatten,
        remove_duplicates : remove_duplicates,
        exhaust : exhaust,
        canonical : canonical,
        list_PROPs : list_PROPs,
        rename_PROPs : rename_PROPs,
        contains_fmla_and_its_neg : contains_fmla_and_its_neg,
        simplify : simplify,
        dm : {
            from: ['not', ['and', '$1', '$2' ]],
            to : ['or', ['not','$1'], ['not','$2']]
        },
        dm_phrase : ['and',['not','Q'],['not', ['and', 'P', ['not', 'Q'] ]]]
    };
    //test
    window.res = {
        are_identical_phrases : are_identical_phrases([1,[2,3]],[1,[2,3]]),
        substitute : substitute(l.dm_phrase,l.dm),
        substitute2 : substitute(['not',['not','P']],l.substitutions.dbl_neg),
        substitute_exhaust : substitute_exhaust(l.dm_phrase, substitutions),
        canonical_test: are_identical_phrases( l.canonical(fol.parse('P or (Q arrow false)')), l.canonical(fol.parse('not (not P and Q)')) )
        

    };

});

