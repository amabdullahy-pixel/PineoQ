---
name: technical-analysis-core
category: Technical Analysis
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/support/solutions/
---

# Technical Analysis Core

## Purpose
The five pillars (trend, momentum, volatility, volume, price action) as a
classification and combination discipline for building indicators in Pine.

## When to Use
- Designing any indicator/strategy; deciding what each component contributes.

## Core Knowledge

### The Five Pillars (what each measures)
| Pillar | Question answered | Pine anchors |
|---|---|---|
| Trend | direction & persistence | MA family, ta.supertrend, ADX, structure |
| Momentum | speed of change, exhaustion | RSI, ROC/MOM, Stochastic, MACD hist |
| Volatility | dispersion of outcomes | ATR, BB, KC, HV (manual) |
| Volume | participation/conviction | volume, OBV, VWAP, RVOL (manual) |
| Price Action | raw structure | pivots, candles, levels (manual) |

### Combination Discipline
- One indicator per pillar per signal — stacked momentum oscillators are
  redundant (high correlation, fake confirmation, skill 22/46).
- Anti-constructive combos: momentum (mean-reverting flavor) inside strong
  trend filters — define regime first (skill 47), then choose pillar logic.
- Normalization: compare indicators on z-scores/percentiles (skill 21/48),
  not raw values across symbols/timeframes.

### Reference Behavior Notes
- Smoothed indicators (RMA/EMA-based) inherit warm-up bias — gate on
  `bar_index >= warmup` (skill 26).
- Pivots confirm late by design (rightBars lag); never treat as real-time
  signals (skill 12).

### Built-in vs Manual (headline rules — details in skills 35–39)
- KAMA, Donchian, HV, CVD, Volume Profile, candlestick patterns: NO built-ins.
- Supertrend direction convention is COUNTERINTUITIVE (see skill 35).

## Common Mistakes
- Same-family stacking (RSI+Stoch+CCI = one opinion three times).
- Mixing timeframe contexts without MTF discipline (skill 13).
- Trusting defaults (lengths/mults) across asset classes without revalidation.

## Corrections & Updates
- [2026-09] Created; classification framework + verified built-in availability.
