# Some new notes (not part of the project, just not sure where to put them)
# 2015-08-19
# Coffeescript makes expressing logic really easy.
# It's really temping to think there's a simple solution to my logic problem.

# See end for a sketch of how proofs might be laid out nicely, too.
# 
# 

_ = require('lodash')

some = (fn) ->
  return _.some domain, (obj) ->
    return true if fn(obj)

all = (fn) ->
  return _.all domain, (obj) ->
    return true if fn(obj)

theif = (ant, conseq) ->
  return (not ant) or conseq
  

domain = ['Ayesha','Boris','Caitlyn']

tall = (obj) ->
  return obj in ['Ayesha']

hungry = (obj) ->
  return obj in ['Ayesha', 'Boris','Caitlyn']

nothing_is_this = (obj) ->
  return false
everything_is_this = (obj) ->
  return true

leftOf = (x,y) ->
  return [x,y].toString() in (pair.toString() for pair in [['Ayesha','Boris'],['Ayesha','Caitlyn'],['Boris','Caitlyn']])

console.log 'all( (x) -> tall(x) )', all( (x) -> tall(x) )
console.log 'all( (x) -> hungry(x) )', all( (x) -> hungry(x) )
console.log 'all( (x) -> (tall(x) and hungry(x)) )', all( (x) -> (tall(x) and hungry(x)) )
console.log 'all( (x) -> (tall(x) or hungry(x)) )', all( (x) -> (tall(x) or hungry(x)) )
console.log 'some( (x) -> (tall(x) and hungry(x)) )', some( (x) -> (tall(x) and hungry(x)) )
console.log 'some( (x) -> tall(x) )', some( (x) -> tall(x) )
console.log 'some( (y) -> all( (x) -> leftOf(x,y) ) )', some( (y) -> all( (x) -> leftOf(x,y) ) )
console.log 'some( (y) -> all( (x) -> leftOf(x,y) or x is y ) )', some( (y) -> all( (x) -> leftOf(x,y) or x is y ) )
console.log 'leftOf("Ayesha","Boris")', leftOf("Ayesha","Boris")
console.log 'some( (y) -> some( (x) -> leftOf(x,y) ) )', some( (y) -> some( (x) -> leftOf(x,y) ) )

console.log 'some( (x) -> nothing_is_this(x) )', some( (x) -> nothing_is_this(x) )
console.log 'not all( (x) -> nothing_is_this(x) )', not all( (x) -> nothing_is_this(x) )
console.log 'all( (x) -> everything_is_this(x) )',  all( (x) -> everything_is_this(x) )

console.log 'all( (x) -> all( (y) -> all( (z) -> ( theif( leftOf(x,y) and leftOf(y,z), leftOf(x,z)) ) )))', all( (x) -> all( (y) -> all( (z) -> ( theif( leftOf(x,y) and leftOf(y,z), leftOf(x,z)) ) )))


# How to write proofs 
# -----
# So that they are easy to read and parse.
#
# first attempt:
#
# 1. A and B
# 2. suppose not A, then ...
#   because 1 by and-elim:
#   3. A
#   because 2, 3 by contradiction-intro:
#   4. contradiction
# because 2-4 by not-intro:
# 5. not not A
# because 5 by not-elim:
# 6. A
  
#
# A better form
# -------
# Here's a better form:
#     `number`. `sentence` ( `rule` [`number`|`number-range`|`number-array`] )
# where `rule` and the `number`-thing can occur in any order.
# Note that arbitrary text is allowed in the brackets (and ignored).
#
# Lines introduing a subproof are special:
#     `number`. suppose `sentence`[, arbitrary text which is ignored] 
#
#
# 1. A and B (premise)
# 2. suppose not A, then ...
#   3. A (from 1 using and-elim)
#   4. contradiction (applying contradiction-intro to 2, 3)
# 5. not not A (not-intro applied to 2-4)
# 6. A (not-elim 5)
  
# everything(x) is such that: it(x) is tall or it(x) is bald
# everything( (x) ->           tall(x)       or bald(x) )