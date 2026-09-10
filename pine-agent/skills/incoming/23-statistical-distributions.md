---
name: statistical-distributions
category: Statistics & Probability
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/pine-script-docs/faq/functions/
---

# Statistical Distributions

## Purpose
Normal, log-normal, Student-t, fat tails, skew/kurtosis — properties and
Pine implementations (no built-in distribution functions exist).

## When to Use
- Band construction, tail-risk estimates, return modeling, MC assumptions (skill 28).

## Core Knowledge

### Critical Fact
Pine has NO built-in erf/erfc/normal-CDF/quantile functions. Implement via
standard approximations:
- Normal CDF from erf (Abramowitz–Stegun, |ε|<1.5e-7):
```pine
erf(float x) =>
    int s = x < 0 ? -1 : 1
    float ax = math.abs(x)
    float t = 1.0 / (1.0 + 0.3275911 * ax)
    float y = 1.0 - (((((1.061405429 * t - 1.453152027) * t)
         + 1.421413741) * t - 0.284496736) * t + 0.254829592)
         * t * math.exp(-x * x)
    s * y
normCdf(float x) => 0.5 * (1.0 + erf(x / math.sqrt(2.0)))
```
- Inverse normal (probit) via Acklam rational approximation (for MC VaR, skill 28).
- t-distribution: for df>30 use normal; lower df → Cornish–Fisher expansion or
  precomputed critical-value tables.

### Families
| Distribution | Shape | Trading use |
|---|---|---|
| Normal | symmetric, thin tails | short-horizon returns approximation, Bollinger logic |
| Log-normal | positive-only, right skew | prices, compounded returns |
| Student-t | heavier tails (df-controlled) | daily returns, robust CIs |
| Empirical | whatever data says | ALWAYS validate against actual data first |

### Moments Beyond Mean/Variance
- Skewness: Σ(x−x̄)³/σ³ over window (manual loop).
- Kurtosis: Σ(x−x̄)⁴/σ⁴; excess = kurt−3. Financial returns: excess kurtosis
  typically > 0 (fat tails) → normal-based σ thresholds UNDERSTATE tail risk.
- Stable-vs-normal diagnostic: compare actual % of \|z\|>3 events vs 0.27% expected.

### Fat Tails — Practical Rules
- Use percentile bands or robust z (MAD-based, skill 21) instead of pure σ bands.
- For risk: prefer historical simulation / bootstrap (skill 28) over parametric VaR.
- Student-t with df≈3–6 often fits daily returns far better than normal.

## Common Mistakes
- Assuming returns are normal → σ-multiple stops too tight for real tails.
- Using normal quantiles for small-sample bootstrap CIs (df matters).
- Re-inventing erf incorrectly (wrong Horner nesting → silent inaccuracies).
- Fitting log-normal to prices of assets with regime jumps.

## Corrections & Updates
- [2026-09] Created; no built-in distribution fns confirmed in v6 reference.
