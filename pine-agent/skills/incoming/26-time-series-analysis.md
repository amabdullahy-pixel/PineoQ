---
name: time-series-analysis
category: Statistics & Probability
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Time Series Analysis

## Purpose
Rolling/expanding statistics, stationarity, trend, seasonality,
autocorrelation, volatility clustering — as trading-time-series practice in Pine.

## When to Use
- Regime characterization, volatility modeling, calendar effects, signal preprocessing.

## Core Knowledge

### Rolling vs Expanding Statistics
- Rolling: every `ta.*` with length parameter (window slides).
- Expanding (since dataset start): `ta.cum`, `ta.max/ta.min` (running extremes),
  or accumulate `var` sums/counts for expanding mean/variance.
- Warm-up honesty: all rolling stats are na/garbage before `len` bars — gate
  logic on `bar_index >= warmupBars`.

### Stationarity (practical Pine diagnostics)
- Prices = non-stationary; RETURNS ≈ stationary-ish (still fat-tailed, skill 23).
- Informal checks: rolling mean drifting? rolling variance ratio far from 1?
  ACF of returns decaying fast vs ACF of prices not decaying?
- Variance-ratio sketch: Var(k-bar returns) / (k·Var(1-bar returns)) —
  ≈1 random walk, >1 trending, <1 mean-reverting.
- ALWAYS model returns or spreads (not raw prices) for statistical logic.

### Trend & Seasonality Decomposition (informal)
- Trend: long SMA/linreg slope (skill 24); Seasonal: average return per
  day-of-week/month bucket:
```pine
var array<float> dowSum = array.new<float>(7, 0.0)
var array<int>   dowN   = array.new<int>(7, 0)
r = ta.change(close)
int d = dayofweek(time, syminfo.timezone)   // ALWAYS syminfo.timezone
array.set(dowSum, d, array.get(dowSum, d) + r)
array.set(dowN, d, array.get(dowN, d) + 1)
```
- Report seasonality only with enough samples per bucket + CI (skill 25).

### Autocorrelation & Persistence
- ACF via `ta.correlation(r, r[h], len)` per lag; white-noise band ±1.96/√N.
- Ljung-Box-style aggregation (sum of r(h)² weighted) as manual persistence score.

### Volatility Clustering
- \|r\| autocorrelation ≫ r autocorrelation → volatility clusters (GARCH concept).
- Pine approximations: EWMA volatility `σ²ₜ = λ·σ²ₜ₋₁ + (1−λ)·r²ₜ` (λ≈0.94,
  RiskMetrics) via var/recursion; ATR percentile ranks (skill 37/47).

## Common Mistakes
- Running stats on prices (non-stationary) instead of returns.
- Claiming seasonality from a handful of observations.
- Ignoring warm-up na period in logic.
- Using chart-timezone dayofweek for session buckets (DST bugs — skill 14).

## Corrections & Updates
- [2026-09] Created; Pine idiom patterns verified against reference.
