---
name: quantitative-analysis
category: Quantitative Trading
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://waylandz.com/quant-book-en/Lesson-09-Supervised-Learning-in-Quantitative-Trading/
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Quantitative Analysis

## Purpose
Alpha signals, factor normalization, ranking, scoring, IC concept — quant
pipeline thinking mapped to Pine.

## When to Use
- Building composite indicators, signal scoring systems, factor-style filters.

## Core Knowledge

### Alpha & Factors
- Alpha signal = any computed predictor of future relative returns (momentum,
  reversion, volume, structure). In single-symbol Pine, factors are
  TIME-SERIES (asset vs its own history); cross-sectional factors need
  multi-symbol requests (skill 15) — Pine cannot rank a large universe
  efficiently in one script.

### Signal Normalization (the core discipline)
- Z-score: `(x - ta.sma(x, len)) / ta.stdev(x, len, false)` (skill 21).
- Rank: `ta.percentrank(x, len)` ∈ [0,100] → robust to outliers.
- Min-max window: `(x - ta.lowest(x, len)) / (ta.range(x, len))` (guard div-0).
- ALWAYS normalize before combining factors with different units.

### Composite Scoring
```pine
f1 = ta.percentrank(ta.roc(close, 20), 100)           // momentum factor
f2 = ta.percentrank(volume / ta.sma(volume, 20), 100) // participation factor
f3 = 100 - ta.percentrank(ta.atr(14), 100)            // vol alignment factor
score = 0.4 * f1 + 0.3 * f2 + 0.3 * f3               // ∈ [0,100]
bool longBias = score > 70
```
- Weights: equal start; change only with validation (skill 53). Fewer, distinct
  factors > many correlated ones (skill 22 independence).

### Information Coefficient (IC) concept
- IC = corr(signal_t, return_{t→t+h}) measured over history.
- Pine proxy: `ta.correlation(signal[shift], ta.change(close, h)[shift], N)`.
- Spearman-flavored (rank) IC preferred (fat tails): correlate percentranks.
- IR = mean(IC)/stdev(IC) — consistency of the signal, not one lucky period.

### Feature Engineering Hygiene
- Stationarize (returns/normalized scores, never raw prices — skill 26).
- Warm-up gating; no lookahead: features built from [1]-confirmed data when
  feeding future-return tests (skill 12).

## Common Mistakes
- Averaging raw (unnormalized) factor values.
- One-factor family in disguise (RSI + ROC + Stoch = momentum three times).
- Testing IC on overlapping returns without lag discipline.
- Cross-sectional fantasies in single-script Pine (use request budget wisely).

## Corrections & Updates
- [2026-09] Created; normalization/IC patterns verified vs reference + quant sources.
