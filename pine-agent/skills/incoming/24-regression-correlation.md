---
name: regression-correlation
category: Statistics & Probability
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Regression & Correlation

## Purpose
Correlation, covariance, least-squares regression, R², residuals,
autocorrelation.

## When to Use
- Relationship strength between series, trend fitting, pair-spread analysis
  (skill 50), regression channels.

## Core Knowledge

### Correlation & Covariance
- `ta.correlation(s1, s2, len)` — Pearson r of rolling window.
- Covariance: manual `cov = ta.sma(s1*s2, len) - ta.sma(s1,len)*ta.sma(s2,len)`
  (biased). Correlation = cov/(σ1·σ2).
- Interpretation guard: r measures LINEAR association only; nonlinearity,
  outliers, and regime shifts break it. Rolling r is itself a noisy series —
  require \|r\| persistence (e.g., r > 0.7 for K consecutive bars).

### Least Squares Regression (manual, for R² & residuals)
```pine
// rolling OLS on x = 0..len-1 over src
olsCalc(float src, int len) =>
    float xm = (len - 1) / 2.0
    float ym = ta.sma(src, len)
    float num = 0.0, float den = 0.0
    for i = 0 to len - 1
        num += (i - xm) * (src[i] - ym)
        den += (i - xm) * (i - xm)
    float slope = den != 0 ? num / den : na
    float intercept = ym - slope * xm
    [slope, intercept]
```
- Fitted value at offset k back: ŷ = intercept + slope·(len−1−k) — this is
  exactly what `ta.linreg(src, len, offset)` returns (offset=0 → current fit point).
- Residual eᵢ = yᵢ − ŷᵢ; residual σ via ta.stdev of residual series.
- R² = 1 − SSres/SStot; for 2-variable OLS, R² = r².

### Linear Regression Channel Pattern
- Mid = `ta.linreg(close, len, 0)`; bands = mid ± mult·stdev(residuals).
- Draw via line.new from fit endpoints (skill 19); slope = per-bar fit slope.

### Autocorrelation
- r(h) = corr(x, x[h]) over window: `ta.correlation(src, src[h], len)`.
- Significance ≈ ±1.96/√N (white-noise band). Significant positive lag-1 →
  trending persistence; negative → mean-reversion tendency (skill 26/27).

## Common Mistakes
- Regressing two non-stationary price series and trusting a high R² (spurious
  regression — needs cointegration thinking, skill 50).
- Reading slope from ta.linreg values without dividing by bar distance.
- Forgetting ta.linreg(src, len, offset) shifts WITHIN the window (not history).
- Confusing correlation stability across regimes (recompute per regime, skill 47).

## Corrections & Updates
- [2026-09] Created; ta.linreg offset semantics verified against v6 reference.
