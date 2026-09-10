---
name: adaptive-systems
category: Quantitative Trading
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://chartschool.stockcharts.com/table-of-contents/technical-indicators-and-overlays/technical-overlays/kaufmans-adaptive-moving-average-kama
  - https://waylandz.com/quant-book-en/Lesson-12-Regime-Detection/
---

# Adaptive Systems

## Purpose
Adaptive thresholds, dynamic parameters/lookbacks, volatility normalization,
percentile thresholds, regime-dependent parameters.

## When to Use
- Systems that must survive changing volatility/regimes without manual retuning.

## Core Knowledge

### Adaptive Thresholds (percentile-based)
```pine
float rsiTh = ta.percentile_nearest_rank(rsi, 250, 95)   // dynamic overbought
bool overbought = rsi >= rsiTh
```
- Static 70/30 RSI lines assume stable distribution — percentile thresholds
  auto-adapt per symbol/vol regime. Window ≥ ~1 year of bars.

### Dynamic Parameters & Lookbacks
- Lookback ∝ volatility: `len = math.max(10, math.round(baseLen * medVol / curVol))`
  (curVol = ATR ratio); longer in quiet, shorter in wild markets.
- KAMA-style adaptation: ER = \|net move\| / Σ\|moves\| (skill 35 manual KAMA);
  ER→1 fast (trend), ER→0 slow (chop). Same ER can drive thresholds,
  cooldowns, and score weights — one adaptation variable, many uses.

### Volatility Normalization
- Normalize ALL comparisons by vol: z-scores of ATR-scaled distances
  ((price − level) / ta.atr(14)), vol-normalized returns (skill 26), RVOL
  participation (skill 38). Raw-price thresholds break across regimes.

### Regime-Dependent Parameter Sets
```pine
int stopMult  = regime == TRENDING ? 3 : regime == RANGING ? 1 : 2   // ATR mults
float targetR = trending ? 3.0 : 1.2
```
- Discrete parameter switching per regime (skill 47) beats continuous chaos;
  parameter COUNT = overfitting surface (skill 54) — switch few parameters.

### Anti-Overfitting Rules for Adaptivity
- Adaptive ≠ better by default: every adaptive mechanism adds degrees of freedom.
- Validate: fixed-param baseline vs adaptive version OUT-OF-SAMPLE (skill 53);
  adaptive must beat baseline OOS to earn its complexity.
- Bound all adaptive values (math.max/min clamps) — runaway adaptation (e.g.,
  lookback → 3) is a silent failure.

## Common Mistakes
- Adaptive lookback changing every bar (numerical instability) — smooth the
  adaptation variable first (EMA of the ratio).
- Percentile thresholds computed on tiny windows.
- Unbounded adaptive state → 500ms loops or degenerate params.
- Adding adaptivity without an OOS comparison (complexity for nothing).

## Corrections & Updates
- [2026-09] Created; KAMA/ER and percentile patterns verified vs sources/reference.
