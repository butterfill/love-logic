# Overview

This project provides parsers for first-order logic (FOL) across multiple dialects and a Fitch-style proof engine. It also includes tools for evaluating FOL sentences against a world, converting to Prenex Normal Form (PNF), and applying substitutions/matching.

Core modules:
- `fol.coffee`: Public API that ties together parsing, substitution, normal form conversions, evaluation, and dialect management.
- `parser/*`: Jison grammars and generated parsers for supported dialects.
- `proofs/*`: Proof parsing and verification (Fitch-style), with rules per textbook dialect.
- `evaluate.coffee`: Evaluate parsed expressions against a provided world.
- `normal_form.coffee`: Convert expressions to PNF, simplify, and sort.
- `substitute.coffee`, `match.coffee`, `util.coffee`: Utilities for substitutions, matching, and expression traversal.

See `docs/evaluation.md` and `docs/normal_form.md` for runnable examples.
