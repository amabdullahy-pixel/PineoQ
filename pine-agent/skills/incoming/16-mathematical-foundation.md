---
name: mathematical-foundation
category: Mathematics
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/pine-script-docs/language/operators/
---

# Mathematical Foundation

## Purpose
Core math (algebra, ratios, exponentials/logs) and its exact Pine v6 mapping.

## When to Use
- Translating formulas into Pine; verifying math behavior/precision.

## Core Knowledge

### math Namespace (v6 — verified inventory)
- Constants: `math.pi`, `math.e`, `math.phi` (1.618…), `math.rphi` (0.618…),
  `math.inf`, `math.nan`.
- Arithmetic/abs: `math.abs`, `math.sign`, `math.avg(...)`, `math.sum(src, len)`
  (ROLLING sum, not cumulative — cumulative is `ta.cum`).
- Exp/log: `math.exp` (e^x), `math.log` (ln), `math.log10`, `math.pow(b, e)`, `math.sqrt`.
- Trig (radians in/out): `sin cos tan asin acos atan`;
  conversions: `math.todegrees`, `math.toradians`.
- Hyperbolic: NOT built-in — implement via identities
  (`sinh(x) = (math.exp(x) - math.exp(-x)) / 2`).
- Rounding: `math.round(x[, precision])`, `math.floor`, `math.ceil`,
  `math.round_to_mintick(x)` (symbol tick size).
- Min/max/random: `math.max/min(...)`, `math.random(min, max, seed)` —
  seed = reproducible sequence; no seed = different each run.

### Precision & Numeric Limits
- `float` = IEEE 754 64-bit double; internal precision limit **1e-16**
  (>16 fractional digits not representable).
- `int` = 64-bit signed (±9.22e18). Overflow beyond wraps/undefined — beware
  cumulative volume × huge multipliers.
- Division by zero → `math.inf`/`math.nan` (NOT a runtime error).
- na propagates through all arithmetic; `na` ≠ `math.nan` (na = missing data).

### Safe Float Comparison
```pine
bool eq = math.abs(a - b) < 1e-9          // epsilon compare
bool samePrice = math.round_to_mintick(a) == math.round_to_mintick(b)
```

### Operator Precedence (high → low)
`[]` → unary `+ - not` → `* / %` → `+ -` → `< <= > >=` → `== !=` → `and` → `or`
→ `?:` (ternary). Equal precedence = left-to-right. When in doubt,
PARENthesize — especially mixing and/or with comparisons.

### Algebra & Ratios in Trading Context
- Percent change: `(b - a) / a * 100`; normalize ratios by their own MA (skill 15).
- Proportions for scaling (ATR-scaled distances, risk-per-R units).
- Log-scale awareness: price ratios ↔ log differences
  (`math.log(p2 / p1)` = continuously compounded return, skill 29).

## Common Mistakes
- `0.1 + 0.2 == 0.3` → false (float artifact).
- Using math.sum expecting lifetime cumulative (it's a rolling window sum).
- Degrees into trig functions (radians required).
- Forgetting division-by-zero → inf/nan silently flows into signals.

## Corrections & Updates
- [2026-09] Created; verified against v6 reference (math namespace complete).
