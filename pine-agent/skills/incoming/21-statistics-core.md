---
name: statistics-core
category: Statistics & Probability
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Statistics Core

## Purpose
Descriptive statistics (central tendency, dispersion, percentiles, robust stats)
with exact Pine v6 implementations.

## When to Use
- Any normalization, threshold, or summary of price/indicator distributions.

## Core Knowledge

### Central Tendency (Pine-verified)
- `ta.sma(src, len)` — mean; na values ignored.
- `ta.ema/ta.rma/ta.wma/ta.vwma` — weighted means (see skill 26 for smoothing ladder).
- `ta.median(src, len)` — median (robust to outliers).
- `ta.mode(src, len)` — most frequent value; TIE → smallest value returned.
- `ta.cog(src, len)` — center of gravity: −Σ(price·weight)/Σprice (weighted, reverses emphasis).

### Dispersion
- `ta.stdev(src, len, biased)` — biased=true (default): divide by N (population);
  false: divide by N−1 (sample). Default matters for z-scores!
- `ta.variance(src, len, biased)` — same biased flag; = stdev².
- `ta.dev(src, len)` — **Mean Absolute Deviation** around the SMA:
  (1/N)·Σ|xᵢ − mean|. Robust-ish alternative to stdev.
- `ta.range(src, len)` — max − min of window.
- `ta.tr(handle_na)` — true range: max(h−l, |h−c[1]|, |l−c[1]|); `ta.atr` = RMA of tr.

### Percentiles & Ranks (three distinct tools — don't confuse)
- `ta.percentile_linear_interpolation(src, len, pct)` — interpolates between
  neighboring ranks → value may NOT exist in data (smooth, good for bands).
- `ta.percentile_nearest_rank(src, len, pct)` — always returns an ACTUAL data
  point (discrete, good for "nth largest").
- `ta.percentrank(src, len)` — % of previous values ≤ CURRENT value (0–100
  rank of now within history — the normalization workhorse, skill 44/48).

### Z-Scores & Robust Statistics
```pine
z       = (src - ta.sma(src, len)) / ta.stdev(src, len, false)   // sample stdev
zRobust = (src - ta.median(src, len)) / (1.4826 * ta.dev(src, len))  // MAD-based
```
- 1.4826 = consistency constant making MAD comparable to σ under normality.
- Robust practice: median/MAD when fat tails or outliers present (skill 23);
  clamp z to ±N to stop a single bar dominating logic.

### Quartiles
- Q1/Q3 = percentiles 25/75; IQR = Q3−Q1; outlier fences = Q1−1.5·IQR / Q3+1.5·IQR.

## Common Mistakes
- Using default biased=true stdev in sample-statistics contexts (slightly
  underestimates dispersion for small len).
- Confusing ta.dev (mean abs deviation) with MAD-median (different center).
- Using percentile_nearest_rank expecting smooth interpolated bands.
- Computing z-scores on constant/flat windows → 0 division → inf/nan (skill 20).

## Corrections & Updates
- [2026-09] Created; all signatures verified against v6 reference.
