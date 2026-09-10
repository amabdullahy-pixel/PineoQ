---
name: natural-language-to-math
category: Research & Modeling
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/language/operators/
---

# Natural Language to Math

## Purpose
Translating verbal trading rules into formal logic → mathematics → Boolean
conditions → Pine. Canonical pipeline:

```
Natural Language → Formal Logic → Mathematics → Boolean Conditions → Pine
```

## When to Use
- Every user-stated rule; every vague "I want it to buy when…" requirement.

## Core Knowledge

### Translation Pipeline (work the example)
Verbal: "RSI1 > RSI3 and the difference must be at least 18 and no expansion"
1. **Formal logic:** identify predicates and terms:
   P₁ = rsi₁ > rsi₃ · P₂ = (rsi₁ − rsi₃) ≥ 18 · P₃ = expansion = false
2. **Mathematics:** define each term with window/normalization:
   rsi₁ = RSI(close, len₁)@tf₁, rsi₃ = RSI(close, len₃)@tf₃ — AMBIGUITY CHECK:
   "RSI1/RSI3" = RSI with two different LENGTHS on one series? or RSI of two
   different SYMBOLS/TIMEFRAMES? Ask or state the assumption explicitly.
3. **Boolean conditions:**
```pine
float r1 = ta.rsi(close, len1)
float r3 = ta.rsi(close, len3)
bool P1 = r1 > r3
bool P2 = (r1 - r3) >= 18.0
bool P3 = not expansionActive
bool rule = P1 and P2 and P3
```
4. **Pine semantics check:** v6 lazy and/or (safe, skill 01); explicit
   parentheses around every and/or mix; bool(x) never implicit; terms defined
   at GLOBAL scope if from ta.* (no conditional ta calls, skill 01).

### Ambiguity Table (ask before coding)
| Verbal phrase | Ambiguity | Default assumption to declare |
|---|---|---|
| "above/below" | close vs high/low? bar close? | close, confirmed bar |
| "crosses" | intrabar touch vs close-through | close-through (isconfirmed) |
| "RSI1, RSI3" | lengths? timeframes? symbols? | lengths — unless told otherwise |
| "strong move" | how measured? | body > k·avgBody or ATR multiples (skill 41) |
| "and/or" in speech | inclusive/exclusive | inclusive OR; confirm exclusivity |
| "quickly/fast" | bars? %? | N bars (state N) |

### Boolean Algebra Guards
- De Morgan for negation: `not (A and B) == not A or not B`.
- Precedence: and binds tighter than or — PARENthesize: `(A and B) or C ≠ A and (B or C)`.
- XOR trap: verbal "or" usually means inclusive OR — XOR only if stated.
- Unknowns propagate: any na term makes the whole conjunction na-ish → guard
  with `not na(...)` (skill 14) or barstate gates (skill 07).

### Validation of the Translation
- Echo the formalization BACK to the requester in plain language + the exact
  Pine lines; get confirmation BEFORE building (requirements loop, skill 72).

## Common Mistakes
- Coding the ambiguous reading without declaring the assumption.
- and/or precedence bugs in long condition strings.
- "Crosses" implemented intrabar (repaints, skill 12).
- Missing na-guards on multi-term conditions.

## Corrections & Updates
- [2026-09] Created; pipeline + ambiguity table formalized.
