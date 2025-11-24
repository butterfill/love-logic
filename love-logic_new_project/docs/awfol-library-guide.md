# awfol.js Developer Guide

**awfol** is a JavaScript library for parsing, evaluating, and verifying First-Order Logic (FOL) sentences and natural deduction proofs. It supports multiple textbook dialects (such as *Language, Proof and Logic*, *forall x*, and *The Logic Book*).

## 1. Setup & Initialization

### Importing
Include the bundle in your project. If using TypeScript, ensure `awfol.d.ts` is visible to your compiler.

```typescript
import { fol, proof } from '@love-logic/core/vendor';

// Or CommonJS
// const { fol, proof } = require('./path/to/awfol.bundle.js');
```

### Setting the Dialect
Before parsing, you **must** select a dialect. This determines the parser syntax (e.g., `&` vs `∧`), the output symbols, and the specific proof rules applied during verification.

**Available Dialects:** `lpl` (default), `forallx`, `teller`, `logicbook`.

```typescript
// Set dialect to 'Language, Proof and Logic'
fol.setDialect('lpl');

// Or 'forall x'
// fol.setDialect('forallx');
```

---

## 2. Working with FOL Sentences

The `fol` namespace handles parsing, evaluation, and AST manipulation.

### Parsing
Convert a string into an Expression object (AST).

```typescript
try {
  // Dialect-specific syntax is required here
  const expr = fol.parse('exists x (Cube(x) and Large(x))');
  
  // Convert back to string (uses dialect symbols, e.g., ∃x (Cube(x) ∧ Large(x)))
  console.log(expr.toString());
} catch (e) {
  console.error("Syntax error:", e.message);
}
```

### The Expression Object
The parsed object contains the AST structure (`type`, `left`, `right`, `quantifier`, etc.) and several utility methods attached at runtime:

| Method | Description |
| :--- | :--- |
| `.toString({ replaceSymbols: boolean })` | Returns the string representation. If `replaceSymbols` is false, keeps original ASCII input. |
| `.clone()` | Returns a deep copy of the expression. |
| `.getFreeVariableNames()` | Returns an array of variables not bound by a quantifier. |
| `.getSentenceLetters()` | Returns used sentence letters (e.g., `['P', 'Q']`). |
| `.negate()` | Returns a new expression wrapping the current one in a negation. |
| `.convertToPNFsimplifyAndSort()` | Returns a normalized Prenex Normal Form version. |

### Evaluation (Possible Worlds)
You can check if a sentence is true in a specific "Situation" (Model).

**Situation Structure:**
1.  **domain**: Array of objects (usually numbers).
2.  **names**: Map of constant names to domain objects.
3.  **predicates**: Map of predicate names to an *Extension* (an array of tuples representing truth).

```typescript
const situation = {
  domain: [1, 2, 3],
  names: {
    a: 1, 
    b: 2
  },
  predicates: {
    // "Cube" is true for object 1
    Cube: [[1]], 
    // "Larger" is true for (1, 2)
    Larger: [[1, 2]] 
  }
};

const sentence = fol.parse('Cube(a) and Larger(a, b)');
const isTrue = sentence.evaluate(situation); // true
```

---

## 3. Pattern Matching & Substitution

The library allows you to treat logic sentences as patterns using meta-variables.

*   **Expression Variables:** `φ`, `ψ`, `χ` (match any sub-formula).
*   **Term Variables:** `α`, `β`, `τ` (match names or variables like `a`, `x`).

```typescript
// Define a pattern: Double Negation
const pattern = fol.parse('not not φ');

// Define a candidate
const candidate = fol.parse('not not (A and B)');

// Check for match
const matchMap = candidate.findMatches(pattern);

if (matchMap) {
  // matchMap.φ is the expression (A and B)
  console.log("Matched content:", matchMap['φ'].toString());
} else {
  console.log("Did not match pattern");
}
```

---

## 4. Proof Verification (Fitch Style)

The `proof` namespace parses and verifies Fitch-style natural deduction proofs.

### Proof Syntax
Proofs are formatted text strings.
*   **Line numbers**: `1.`, `2.` (optional, but recommended).
*   **Justifications**: Comments starting with `//` or extra whitespace.
*   **Subproofs**: Indicated by indentation or `|` bars.
*   **Dividers**: `---` separates premises from the rest of the block.

**Example Proof Text:**
```text
| A and B           // premise
|---
| A                 // and elim 1
| B                 // and elim 1
| B and A           // and intro 3,2
```

### Parsing and Verifying

```typescript
const proofText = `
1. P -> Q      // premise
2. P           // premise
3. Q           // arrow elim 1, 2
`;

// 1. Parse the proof
// NOTE: Returns a Proof object OR an error string if parsing fails.
const result = proof.parse(proofText);

if (typeof result === 'string') {
  console.error("Parse Error:", result);
} else {
  const myProof = result;

  // 2. Verify the logic
  const isValid = myProof.verify();

  if (isValid) {
    console.log("Proof is valid!");
  } else {
    console.log("Proof is invalid.");
    // Get specific error messages (e.g., "Line 3: justification incorrect")
    console.log(myProof.listErrorMessages());
  }
}
```

### Inspecting the Proof Structure
The `Proof` object is a recursive structure (Blocks contain Lines or Blocks).

*   `myProof.getPremises()`: Returns array of `fol.Expression`.
*   `myProof.getConclusion()`: Returns `fol.Expression` or `false`.
*   `myProof.getLine(n)`: Gets the line object at 1-based index `n`.

### Dialect Sensitivity
The verifier strictly enforces the rules of the active dialect.
*   **LPL**: Uses "Intro/Elim".
*   **LogicBook**: Uses "D" (Decomposition).
*   **Teller**: Uses "I/E" and specific names like `weakening`.

Ensure `fol.setDialect(...)` is called before parsing proofs.

---

## 5. Troubleshooting

**1. "Unknown parser..."**
You didn't call `fol.setDialect()`. The library needs to know which grammar to use.

**2. `proof.parse` returning a string**
Unlike `fol.parse` (which throws Errors), `proof.parse` returns the error message string directly on failure. Always check the type of the return value.

**3. "Variable x is not bound" during evaluation**
In `fol.evaluate`, free variables (like `Cube(x)`) cannot be evaluated directly. The formula must be a sentence (no free variables) or you must bind them manually in the logic (not exposed in high-level API).

**4. Symbol mismatches**
If `toString()` outputs `&` but you expected `∧`, check your dialect.
*   LPL: `∧`, `→`
*   forallx: `&`, `→`
*   Teller: `&`, `⊃`