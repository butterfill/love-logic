# Documentation Index

Welcome to the project documentation. These guides contain runnable CoffeeScript doctests that you can validate locally.

How to use
- Validate doctests: `npm run docs:test`
- Run examples: `npm run examples`

Guides
- Overview: High-level architecture of parsers, evaluator, and proof engine
  - ./overview.md
- Evaluation: Evaluate FOL sentences against a world with examples
  - ./evaluation.md
- Prenex Normal Form: Convert expressions to PNF (simplify and sort) with examples
  - ./normal_form.md
- Proofs (Fitch): Parse and verify proofs, including subproofs, dialect example, and quantified rules
  - ./proofs.md
- Parsers and Dialects: Grammar files, regeneration with jison, and quick parse doctest
  - ./parsers.md
- Substitutions and Matching: Patterns, matches, and substitutions with examples
  - ./substitutions.md
- Testing docs: Doctest format, #=> output assertions, and conventions
  - ./testing.md

Notes
- Doctest code blocks are marked as `coffee doctest`.
- Expected output lines within doctests use `#=>` to assert substrings in stdout.
- Some examples are dialect-sensitive; the guide sets the dialect explicitly when required.
