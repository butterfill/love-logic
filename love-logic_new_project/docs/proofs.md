# Proofs (Fitch-style)

Parse and verify Fitch-style natural deduction proofs.

The doctest below parses a minimal proof and verifies it. It should print `true`.

```coffee doctest
fol = require './fol'
fol.setDialect 'lpl'
proof = require './proofs/proof'
text = '''
  | A            premise
  |---
  | A            reit 1
'''
pr1 = proof.parse text
norm = pr1.toString({numberLines:true})
pr = proof.parse norm
console.log pr.verify()  #=> true
```

Notes:
- Proof lines accept comments with `//` for justifications.
- Subproofs are introduced with `|` and `---` as in the tests.
- The rules applied depend on the current dialect; default is `lpl`.

Subproof example (implication introduction):

```coffee doctest
fol = require './fol'
fol.setDialect 'lpl'
proof = require './proofs/proof'
text = '''
  B
   | A
   | B         reit 1
  A arrow B    arrow intro 2-3
'''
pr1 = proof.parse text
norm = pr1.toString({numberLines:true})
pr = proof.parse norm
console.log pr.verify()  #=> true
```

Different dialects (logicbook):

```coffee doctest
fol = require './fol'
fol.setDialect 'logicbook'
proof = require './proofs/proof'
text = '''
  B
   | A
   | B         reit 1
  A arrow B    arrow intro 2-3
'''
pr1 = proof.parse text
norm = pr1.toString({numberLines:true})
pr = proof.parse norm
console.log pr.verify()  #=> true
```

Quantified examples (lpl dialect by default):

Universal introduction (correct):

```coffee doctest
fol = require './fol'
fol.setDialect 'lpl'
proof = require './proofs/proof'
text = '''
  |          
  |---       
  || [a]     premise 
  ||---      
  || a=a     = intro 
  | ∀x x=x   ∀ intro 3-5
'''
pr = proof.parse text
console.log pr.verify()  #=> true
```

Existential introduction:

```coffee doctest
fol = require './fol'
fol.setDialect 'lpl'
proof = require './proofs/proof'
text = '''
  | F(a)      premise
  |---
  | ∃x F(x)   exists intro 1
'''
pr = proof.parse text
console.log pr.verify()  #=> true
```
