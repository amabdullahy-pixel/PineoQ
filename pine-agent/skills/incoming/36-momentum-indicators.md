---
name: momentum-indicators
category: Technical Analysis
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/support/solutions/43000502338-relative-strength-index-rsi/
---

# Momentum Indicators

## Purpose
RSI, Stochastic, CCI, ROC, Williams %R, Momentum — exact formulas, pitfalls.

## When to Use
- Exhaustion, acceleration, divergence, mean-reversion triggers.

## Core Knowledge

### Verified Formulas
- RSI: `ta.rsi(src, len)` = 100 − 100/(1+RS), RS = rma(avgGain)/rma(avgLoss)
  (Wilder). Overbought/oversold are regime-relative — in strong trends RSI
  stays pinned 60–80 (skill 47 gate first).
- Stochastic: `ta.stoch(src, high, low, len)` = raw %K = 100·(src −
  lowest(low,len)) / (highest(high,len) − lowest(low,len)). NO built-in
  smoothing/slowing/%D — apply `ta.sma(raw, 3)` manually for slow %K / %D.
- CCI: `ta.cci(src, len)` = (src − sma(src)) / (0.015 · meanDeviation).
- ROC: `ta.roc(src, len)` = (src − src[len])/src[len] × 100. MOM: `ta.mom` = src − src[len].
- Williams %R: `ta.wpr(len)` = −100·(highest − close)/(highest − lowest) ∈ [−100, 0].
- TSI: `ta.tsi(src, short, long, signal)` — double-smoothed momentum.

### Divergence Engineering
- Divergence = price HH/LL vs indicator opposite — detect with
  `ta.pivothigh/ta.pivotlow` on BOTH series (confirmed-with-lag, skill 12);
  store pivots in arrays and compare levels; require indicator-peak within a
  bar-tolerance window of price-peak.

### Oscillator Behavior Across Regimes
- Trend: oscillators pin/extreme → "oversold" ≠ buy (skill 47 first).
- Range: oscillators shine as reversion triggers.
- Normalize across assets via z/percentrank (skill 21) when fusing (skill 46).

## Common Mistakes
- Expecting built-in slow stochastic (manual SMA needed).
- Trading RSI extremes against strong trends without regime filter.
- na in the warm-up window (divide-by-zero on flat windows, skill 20).
- Divergence detection on UNconfirmed pivots (repaint).

## Corrections & Updates
- [2026-09] Created; formulas verified against reference/support articles.
