# Skill: mathematical-foundation

## Metadata

```yaml
id: mathematical-foundation
name: Mathematical Foundation
version: 1.0.0
path: skills/normalized/quant/mathematical-foundation/skill.md
layer: QUANT
domains: [mathematics, pine-mapping]
triggers:
  english:
    - math namespace
    - float precision
    - epsilon comparison
    - operator precedence
    - rolling vs cumulative sum
    - log return
    - degrees radians
  persian:
    - مبانی ریاضی
    - دقت اعشار
    - مقایسه اپسیلون
    - اولویت عملگرها
    - لگاریتم بازده
dependencies:
  mandatory: []
  optional: [numerical-methods, linear-algebra, financial-mathematics, pine-type-system]
status: normalized
priority: 1
```

## Purpose

Core math (algebra, ratios, exponentials/logs) and its exact Pine v6 mapping:
the `math` namespace inventory, precision/numeric limits, safe float
comparison, operator precedence, and trading-context algebra. The baseline for
translating any formula into Pine without silent numeric corruption.

## Triggers

Select for: translating formulas into Pine; verifying math behavior or
precision; float comparison/rounding questions; operator precedence disputes;
choosing `math.sum` vs `ta.cum`; log-return conversions.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Formula or math question | description | formalization contract | yes |
| Symbol tick size (for mintick rounding) | context | target symbol | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Correct Pine math mapping | knowledge applied | Implementation |
| Precision/stability risk flags | warnings | Pre-Verification, numerical-methods |
| Precedence-safe expression form | design note | Implementation Planning |

## Rules

1. `math` namespace (v6, source-verified inventory): constants `math.pi`,
   `math.e`, `math.phi` (1.618…), `math.rphi` (0.618…), `math.inf`,
   `math.nan`; arithmetic/abs `math.abs`, `math.sign`, `math.avg(...)`,
   `math.sum(src, len)` — ROLLING sum, not cumulative (cumulative is `ta.cum`);
   exp/log `math.exp`, `math.log`, `math.log10`, `math.pow`, `math.sqrt`; trig
   in radians (sin/cos/tan/asin/acos/atan; `math.todegrees`,
   `math.toradians`); hyperbolic NOT built-in — implement via identities
   (e.g., `sinh(x) = (math.exp(x) - math.exp(-x)) / 2`); rounding
   `math.round(x[, precision])`, `math.floor`, `math.ceil`,
   `math.round_to_mintick(x)`; min/max/random `math.max/min(...)`,
   `math.random(min, max, seed)` — seed = reproducible sequence, no seed =
   different each run.
2. Precision & numeric limits: `float` = IEEE 754 64-bit double, internal
   precision limit 1e-16; `int` = 64-bit signed (±9.22e18) — beware overflow
   with cumulative volume × huge multipliers; na propagates through all
   arithmetic; `na` ≠ `math.nan` (na = missing data).
3. **Division by zero** — UNVERIFIED claim, original wording preserved: the
   source states "division by zero → `math.inf`/`math.nan` (NOT a runtime
   error)". Import-time check (official Operators page, 2026-09) found the
   docs silent on runtime division-by-zero results, while a *constant*
   division by zero is a compile-time error and community evidence indicates
   runtime division by zero yields `na` (na propagates through arithmetic per
   the official Operators page). PROPOSED INTERPRETATION (not substituted):
   guard every denominator and treat zero-division output as na-or-undefined
   — never rely on any specific zero-division result value. The mandatory
   guard rule itself is source-native and unaffected (see rule 6 and
   numerical-methods).
4. Safe float comparison: epsilon windows
   (`math.abs(a - b) < 1e-9`) or mintick rounding
   (`math.round_to_mintick(a) == math.round_to_mintick(b)`); never `==` on
   computed floats.
5. Operator precedence (high → low): `[]` → unary `+ - not` → `* / %` →
   `+ -` → `< <= > >=` → `== !=` → `and` → `or` → `?:`; equal precedence =
   left-to-right; when in doubt parenthesize — especially mixing and/or with
   comparisons. (Matches the official Operators page precedence table,
   verified at import.)
6. Algebra & ratios in trading context: percent change `(b - a) / a * 100`
   (guard a ≠ 0); normalize ratios by their own MA; proportions for scaling
   (ATR-scaled distances, risk-per-R units); log-scale awareness —
   `math.log(p2 / p1)` = continuously compounded return.

## Workflow

1. Translate the formula step-by-step with explicit Pine mapping (rule 1).
2. Flag precision/stability risks (rules 2–4) into numerical-methods checks.
3. Parenthesize ambiguous expressions (rule 5) in planned code.
4. Record zero-division/na guards as mandatory design elements (rules 2–3, 6).

## Constraints

- No native hyperbolic functions (identity-based implementation required).
- `math.sum` is rolling — lifetime accumulation must use `ta.cum`.
- Trig I/O is radians-only.

## Assumptions

- `math` namespace inventory per v6 reference as claimed by the source;
  division-by-zero runtime behavior remains unverified (rule 3) — re-verify
  against docs/behavior before relying on any specific result value.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| `0.1 + 0.2 == 0.3` fails | float artifact | rule 4: epsilon/mintick compare |
| math.sum expected cumulative | wrong totals | rule 1: use ta.cum |
| Degrees into trig | wrong angles | rule 1: radians only |
| Zero division in signals | inf/nan/na propagation | rule 6 guards + rule 3 note |

## Dependencies

Optional: numerical-methods (stability toolkit), linear-algebra (matrix math),
financial-mathematics (log returns depth), pine-type-system (na/bool rules).
Load only on their own triggers.

## Examples

- "Why isn't my equality check passing?" → rule 4 epsilon comparison.
- "Accumulate volume from dataset start" → rule 1: `ta.cum`, not `math.sum`.
- Persian: «چرا محاسبه درصدی‌ام اشتباه است؟» → rule 6 + precedence.

## Verification Criteria

- No float `==` comparisons; epsilon/mintick forms used.
- All denominators guarded; cumulative vs rolling sum intent matches function.
- Complex expressions parenthesized per rule 5.
- Zero-division result values never relied upon (rule 3 note respected).

## Ambiguities

- Division-by-zero runtime result (rule 3): source claim vs community evidence
  conflict; recorded, not resolved — the mandatory guard rule is unaffected.

## Missing Information

- Authoritative runtime division-by-zero semantics (docs currently silent).

## Import Notes

- Batch `batch-002` import from `skills/incoming/16-mathematical-foundation.md`.
- Import-time verification: operator precedence table CONFIRMED against the
  official Operators page (2026-09 fetch); official page documents na
  propagation through arithmetic.
- One UNVERIFIED source claim detected (division-by-zero → inf/nan): preserved
  verbatim as a flagged claim with a proposed interpretation recorded
  separately — per import rules, no silent correction; the skill's own
  guard-every-denominator discipline remains the operative rule. This is the
  batch's only content-level finding.
- Structural reorganization into the Skill template otherwise; no semantic
  changes.

## Source Reference

- Original filename: `16-mathematical-foundation.md`
- Original source path: `skills/incoming/16-mathematical-foundation.md`
- Import batch: `batch-002`
- Normalization status: normalized
- Validation status: passed (with one documented unverified claim)
- Import date: 2026-09 (batch-002)
