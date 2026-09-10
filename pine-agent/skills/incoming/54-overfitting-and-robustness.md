---
name: overfitting-and-robustness
category: Backtesting & Optimization
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/support/solutions/43000666265-how-deep-backtesting-works/
---

# Overfitting & Robustness

## Purpose
Curve fitting, parameter stability, robustness across regimes/symbols/
timeframes, Monte Carlo robustness, multiple-testing control.

## When to Use
- Final gate before deploying/trusting any optimized strategy.

## Core Knowledge

### Curve Fitting (definition + cure)
- Overfit = model memorized noise: in-sample brilliance, OOS collapse.
- Cures: fewer parameters (skill 68), longer samples, OOS discipline (skill 53),
  plateau-only acceptance (skill 52), explicit falsification (skill 66).

### Robustness Battery (run ALL before trust)
1. **Parameter stability** — neighbors of the chosen values must remain
   profitable (±20% on lookbacks/mults). Sharp cliffs = noise.
2. **Regime robustness** — split results by regime (skill 47): strategy may
   lose in one regime ONLY IF regime-gated there; unexplained regime losses =
   fragility.
3. **Symbol robustness** — same logic on 5+ related symbols; edge should be
   positive on most (not necessarily all).
4. **Timeframe robustness** — 1–2 neighboring timeframes; fragile TF-lock =
   artifact.
5. **Monte Carlo robustness** — bootstrap trade sequence (skill 28): report
   5th-percentile final equity and P(DD > X%); strategy must survive the
   5th-percentile path with the chosen position sizing (skill 31).
6. **Sub-period consistency** — 4+ equal sub-periods: how many profitable?
   One period carrying everything = fragility.

### Multiple Testing Control
- K backtest variants tested → false-positive risk ≈ 1−(1−α)^K.
- Budget trials; log EVERY variant tested (honest trial ledger, skill 73);
  apply Bonferroni-style tightening: require OOS p < α/K conceptually, or
  simply demand larger effect sizes as K grows.
- Two independent OOS periods > one double-optimized parameter set.

### Deployment Thresholds (suggested defaults — falsify per system)
- ≥100 trades, PF ≥ 1.3, expectancy > 2× costs, OOS retains ≥ 50% of IS
  expectancy, 5th-pct MC drawdown within risk policy.

## Common Mistakes
- Treating a single great backtest as evidence (it's one draw from noise).
- Robustness tested only on the winning symbol/TF.
- "It passed IS" as the final word (IS is the EASY test).
- No trial ledger → unknowable K → unfalsifiable claims.

## Corrections & Updates
- [2026-09] Created; thresholds marked as defaults to calibrate per market.
