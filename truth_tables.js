/**
 * create truth tables for formulae like
 * ['not', ['not', '$1']] > '$1'
 * ['not', ['and', '$1', '$2' ]] > ['or', ['not','$1'], ['not','$2']]
 *
 *
 * see substitute.js for other notes
 *
 */

require(['substitute','lib/underscore'], function(substitute){
    
    /**
     * @returns {Array} An array of sentence letters contained in the phrase
     */
    function extract_sentence_letters(phrase) {
        
    }
    
    /**
     * @returns {Array} An array of arrays of truth values
     */ 
    function generate_rows(sentence_letters) {
        nof_letters = sentence_letters.length;
        nof_rows = 2^nof_letters;
        _.each( _.range(nof_rows),
               function(element, index, list){
                //***DO (use binary)
               }
              )
    }
    
    /**
     * @returns true or false
     * @param values should be an Array of truth values for the sentence letters in the phrase
     */
    function evaluate(phrase, sentence_letters, values) {
        
    }

});

