# Skill: numerical-methods

## Metadata

```yaml
id: numerical-methods
name: Numerical Methods
version: 1.0.0
path: skills/normalized/quant/numerical-methods/skill.md
layer: QUANT
domains: [mathematics, numerical-stability]
triggers:
  english:
    - floating point stability
    - catastrophic cancellation
    - interpolation
    - smoothing ladder
    - newton iteration
    - fixed point iteration
    - accumulation error
    - numerical robustness
  persian:
    - روش‌های عددی
    - پایداری محاسبات
    - درون‌یابی
    - خطای انباشتی
dependencies:
  mandatory: []
  optional: [mathematical-foundation, calculus-and-optimization, mtf-engineering, trend-indicators]
status: normalized
priority: 2
```

## Purpose

Approximation, interpolation, stability, floating-point pitfalls, and bounded
iterative methods inside Pine's execution budget — the robustness layer that
keeps accumulations, level-solving, and custom smoothing from silently
corrupting signals.

## Triggers

Select for: custom smoothing/fitting; level solving or iterative algorithms;
indicator stabilization; long-run accumulations; z-score/variance failures on
degenerate series; any algorithm with convergence loops.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Algorithm/instability concern | description | formalization contract | yes |
| Series character (noisy, near-constant) | context | data characteristics | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Stability hardening design | implementation pattern | Implementation |
| Robustness checklist results | verification checks | Pre/Post-Verification |
| Iteration budget | constraint notes | Feasibility |

## Rules

1. Floating-point stability: float = 64-bit double with ~1e-16 precision;
   catastrophic cancellation when subtracting near-equal large numbers —
   restructure formulas (e.g., `log(p2/p1)` instead of `log p2 − log p1` for
   returns); accumulation error in long sums — periodically recompute or sum
   smaller windows, prefer multiplicative forms for growth; epsilon
   comparisons, never `==` on computed floats; division-by-zero → inf/nan and
   na-propagation through every expression — guard EVERY denominator
   (`x > 0 ? a / x : na`). (The specific runtime value of a zero division is
   unverified — see mathematical-foundation's flagged claim; the guard rule is
   unconditional.)
2. Interpolation & approximation: linear interpolation between anchors
   `y = y0 + (y1 - y0) * (x - x0) / (x1 - x0)` (guard x1 ≠ x0); value between
   bars via `ta.valuewhen`/array anchors; smoothing ladder (noise vs lag):
   SMA → EMA → DEMA/TEMA → HMA (see trend-indicators); Kalman-style state +
   gain loops; order-level rounding via `math.round_to_mintick`.
3. Root finding & iterative solvers (budget-safe): bisection — robust, linear
   convergence, cap iterations (40–60); Newton — quadratic convergence but
   needs a derivative, guard against divergence (max step size, iteration cap,
   fallback to bisection); fixed-point `x := g(x)` until |Δ| < tol — ALWAYS
   with both tolerance and iteration caps (500 ms/bar loop limit).
4. Discretization patterns: bar-based derivatives/integrals (see
   calculus-and-optimization) are finite differences/sums — document the dt
   convention (one bar); sub-bar dt via `request.security_lower_tf` arrays
   (see mtf-engineering).
5. Numerical robustness checklist: all denominators guarded (zero, na);
   epsilon comparisons, no float equality; iteration caps on every loop; no
   catastrophic cancellation in return/variance formulas; degenerate cases
   handled (constant series → variance 0, single-element arrays, empty
   windows); values clamped where a score/index must stay bounded.
6. Rebuild cost: rebuilding large sums over full history each bar is O(n) per
   bar → O(n²) total — use incremental state via `var`.

## Workflow

1. Audit the algorithm against the robustness checklist (rule 5) at
   Pre-Verification.
2. Apply stability transformations (rule 1) to any cancellation-prone formula.
3. Choose interpolation/smoothing per rule 2 with documented noise-vs-lag
   tradeoffs.
4. Cap and guard all solvers (rule 3); document the fallback path.
5. Enforce incremental state for history-wide accumulations (rule 6).

## Constraints

- Every iterative loop requires tolerance AND iteration caps.
- Degenerate-input handling (rule 5) is mandatory, not optional polish.

## Assumptions

- Float semantics per official type-system/limitations docs as claimed by the
  source.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| z-score inf/nan on flat series | variance = 0 denominator | rule 5 degenerate handling |
| Newton divergence hang | long loop | rule 3: caps + bisection fallback |
| O(n²) accumulation | slowdown over time | rule 6: incremental `var` state |
| `log p2 − log p1` precision loss | wrong returns | rule 1: `log(p2/p1)` |

## Dependencies

Optional: mathematical-foundation (precision/precedence base),
calculus-and-optimization (discrete operators), mtf-engineering (sub-bar dt),
trend-indicators (smoothing implementations). Load only on their own triggers.

## Examples

- "My ratio indicator explodes on quiet days" → rule 5/1: guard denominators,
  handle variance-0.
- "Fit a level between two anchors" → rule 2 interpolation with guards.
- Persian: «اندیکاتورم بعد از چند هزار کندل کند می‌شود» → rule 6: incremental
  state.

## Verification Criteria

- Robustness checklist fully passed and recorded.
- All loops have caps; all denominators guarded; no float `==`.
- No cancellation-prone forms in return/variance math.
- History-wide accumulations use incremental state.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-002` import from `skills/incoming/20-numerical-methods.md`.
- Structural reorganization only; no semantic changes. The division-by-zero
  guard rule is preserved unconditionally; its result-value claim cross-references
  mathematical-foundation's flagged claim rather than asserting either way.

## Source Reference

- Original filename: `20-numerical-methods.md`
- Original source path: `skills/incoming/20-numerical-methods.md`
- Import batch: `batch-002`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-002)
