---
name: calculus-and-optimization
category: Mathematics
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/pine-script-docs/language/loops/
---

# Calculus & Optimization

## Purpose
Discrete derivatives/integrals, rate-of-change concepts, and optimization
strategies in Pine's bar-sequential world.

## When to Use
- Momentum as derivative, curvature detection, parameter search, gradient-flavored logic.

## Core Knowledge

### Derivatives (discrete)
- First difference: `ta.change(x, 1) = x - x[1]`.
- N-bar rate of change: `ta.change(x, n)` or `ta.roc(x, n)`.
- Second derivative (acceleration): `ta.change(ta.change(x))` — noisy; smooth
  first (e.g., EMA) before differentiating.
- Slope over window: `ta.linreg(src, len, 0) - ta.linreg(src, len, 1)` per bar;
  or regression endpoints: `(linreg_now - linreg_n_bars_ago) / n`.

### Integrals (discrete)
- Cumulative: `ta.cum(src)` (from dataset start).
- Windowed integral: `math.sum(src, len)` (rolling sum).
- Trapezoid refinement for price-like series:
  `(y[i] + y[i+1]) / 2 * dt` summed in a loop.
- Area under curve patterns: volume-weighted accumulations, VWAP as running
  ∫(price·volume)dV / ∫volume.

### Limits & Asymptotics
- Concept-level: thresholds via `math.max/min`, saturation via clamps:
  `math.max(0, math.min(1, score))` — squashing functions for scores.
- Exponential saturation: `1 - math.exp(-k*x)` growth-to-limit shapes.

### Optimization in Pine (constraints shape strategy)
- NO general solvers/gradients — optimization is:
  1. **Analytic**: closed forms (e.g., least squares via `ta.linreg` or matrix math).
  2. **Grid/random search OFFLINE** (TradingView strategy tester's parameter
     optimizer is the UI tool; Pine itself doesn't self-optimize).
  3. **In-script iterative**: loops with convergence conditions (500ms/bar cap,
     skill 69) — e.g., bisection to find crossing level, Newton-style root
     finding with iteration caps.
- Gradient CONCEPTS for scoring: direction + magnitude of improvement
  (`dScore = score - score[1]`), used for adaptive steps (skill 48).

### Root Finding Pattern (bounded bisection)
```pine
f(float x) =>                      // target function
    x * x - 2.0
float lo = 0.0, hi = 2.0
for i = 1 to 60                    // iteration cap: budget-safe
    float mid = (lo + hi) / 2
    if f(lo) * f(mid) <= 0
        hi := mid
    else
        lo := mid
float sqrt2 = (lo + hi) / 2
```

## Common Mistakes
- Differentiating noisy series directly (double noise) — smooth first.
- Unbounded iterative solvers → 500ms loop timeout (skill 01/69).
- Expecting in-script parameter optimization — Pine evaluates one parameter set
  per run; optimization is external/UI-driven.
- Confusing math.sum (rolling) with ta.cum (cumulative).

## Corrections & Updates
- [2026-09] Created; verified against v6 reference (ta.slope does NOT exist —
  compute via linreg differences).
