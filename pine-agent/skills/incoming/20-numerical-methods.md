---
name: numerical-methods
category: Mathematics
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/language/type-system/
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Numerical Methods

## Purpose
Approximation, interpolation, stability, floating-point pitfalls, and bounded
iterative methods inside Pine's execution budget.

## When to Use
- Custom smoothing/fitting, level solving, indicator stabilization,
  any algorithm with accumulations or convergence loops.

## Core Knowledge

### Floating-Point Stability
- float = 64-bit double, precision limit ~1e-16; catastrophic cancellation when
  subtracting near-equal large numbers (`a - b` where a≈b) — restructure
  formulas (e.g., `log(p2/p1)` instead of `log p2 − log p1` for returns).
- Accumulation error in long sums: periodically recompute, or sum smaller
  windows; prefer multiplicative forms for growth.
- Comparisons: epsilon windows (skill 16). Never `==` on computed floats.
- Division-by-zero → inf/nan; na-propagation through every expression.
  Guard EVERY denominator: `x > 0 ? a / x : na`.

### Interpolation & Approximation
- Linear interpolation between anchors (x known):
  `y = y0 + (y1 - y0) * (x - x0) / (x1 - x0)` (guard x1 ≠ x0).
- Value between bars: interpolate from `ta.valuewhen`/array anchors.
- Smoothing ladder (noise vs lag): SMA → EMA → DEMA/TEMA → HMA (skill 35);
  Kalman-style: state + gain loops.
- Rounding for order levels: `math.round_to_mintick`.

### Root Finding & Iterative Solvers (budget-safe)
- Bisection: robust, linear convergence; cap iterations (e.g., 40–60).
- Newton: quadratic convergence but needs derivative; guard against divergence
  (max step size, iteration cap, fallback to bisection).
- Fixed-point iteration `x := g(x)` until |Δ| < tol — ALWAYS with both
  tolerance and iteration caps (500ms/bar loop limit, skill 01).

### Discretization Patterns
- Bar-based derivatives/integrals (skill 18) are finite differences/sums —
  document the dt convention (one bar).
- Sub-bar dt via `request.security_lower_tf` arrays (skill 13).

### Numerical Robustness Checklist
- [ ] All denominators guarded (zero, na).
- [ ] Epsilon comparisons, no float equality.
- [ ] Iteration caps on every loop (time budget).
- [ ] No catastrophic cancellation in return/variance formulas.
- [ ] Degenerate cases handled: constant series (variance=0), single element
      arrays, empty windows.
- [ ] Values clamped where a score/index must stay bounded.

## Common Mistakes
- Variance of a constant series → 0 in denominator of z-score → inf/nan.
- Newton iterations diverging and hanging the bar execution.
- Rebuilding large sums over full history each bar (O(n) per bar → O(n²) total;
  use incremental state via `var`).

## Corrections & Updates
- [2026-09] Created; verified against type-system/limitations docs.
