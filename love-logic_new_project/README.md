Parsers for a first-order language and for Fitch-style proofs.
Can evaluate sentences against possible situations.
Can convert sentences to prenex normal form.
Can test whether an expression matches a logical form, applying substitutions as necessary (e.g. φ[τ->α]).
Rules of proof can be expressed in a natural way, e.g.
```
universal :
    elim : rule.from('all τ φ').to('φ[τ->α]')
    intro : rule.from( rule.subproof('[α]', 'φ') ).to('all τ φ[α->τ]')
```
There are tests covering most functions.

(c) Stephen A. Butterfill 2015
All rights reserved.
Contact me if you want to use this code.