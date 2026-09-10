---
name: optimization-and-calibration
category: Backtesting & Optimization
version: 1.0.0
last_updated: 2026-09
confidence: medium
sources:
  - https://www.tradingview.com/support/solutions/43000628599-strategy-properties/
  - https://www.tradingview.com/pine-script-docs/concepts/strategies/
---

# Optimization & Calibration

## Purpose
Parameter optimization, grid/random search, sensitivity analysis, calibration —
within TradingView's actual toolset.

## When to Use
- Tuning inputs honestly; deciding whether a parameter even matters.

## Core Knowledge

### Platform Reality (VERIFIED — needs-review flag)
- TradingView has NO built-in strategy parameter optimizer (three independent
  doc checks found none; such optimizers exist on MetaTrader, NOT TradingView;
  community feature requests ask for one). External automation tools violate
  TradingView ToS (account-ban risk).
- Therefore: optimization = MANUAL parameter sweeps (edit input → rerun →
  record) or in-script design that avoids sweeps.

### Manual Sweep Discipline
- Sweep ONE parameter at a time; hold others fixed; log a table:
  {param, value, netProfit, PF, maxDD, N trades}.
- Grid concept: choose 3–5 values per parameter, spanning ≥2× range (e.g.,
  ATR mult 1.5 / 2 / 2.5 / 3 / 4).
- Random search concept: random combos often beat full grids under a fixed
  trial budget (curse of dimensionality: k params × 5 values = 5^k runs).

### Sensitivity Analysis (the real deliverable)
- GOOD: performance changes SMOOTHLY and stays positive across a NEIGHBORHOOD
  of parameter values ("flat plateau").
- BAD: sharp peak — performance collapses one step away → fitted noise
  (skill 54). A parameter that must be "exactly 17" is not a parameter, it's a
  curve-fit.
- Decision rule: keep parameter only if the plateau median beats the baseline.

### Calibration vs Optimization
- Calibration = setting FEW parameters to asset-class-sensible values (e.g.,
  ATR mult 2–3, cost model to broker reality) — low degrees of freedom.
- Optimization = SEARCH for best values — high degrees of freedom, always
  paired with OOS validation (skill 53).
- In-script reality: Pine runs ONE parameter set per execution; no auto-search
  inside a script. Design fewer, meaningful inputs (skill 68).

## Common Mistakes
- Sweeping 5+ parameters simultaneously (combinatorial explosion, all noise).
- Optimizing ON the evaluation window (leakage).
- Reporting the best run instead of the plateau.
- Using external auto-optimizers on the account (ToS risk).

## Corrections & Updates
- [2026-09] Created. NO-BUILT-IN-OPTIMIZER finding verified 3× (needs-review:
  re-verify if TradingView ships one — check release notes via skill 06).
