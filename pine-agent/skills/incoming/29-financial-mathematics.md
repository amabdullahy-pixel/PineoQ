---
name: financial-mathematics
category: Financial Math & Risk
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/support/solutions/43000681694-sharpe-ratio/
---

# Financial Mathematics

## Purpose
Returns, log returns, cumulative/annualized returns, compounding — exact Pine forms.

## When to Use
- Any performance calculation, normalization, or return-based statistic.

## Core Knowledge

### Returns
- Simple return per bar: `r = close / close[1] - 1` (≈ `ta.change(close)/close[1]`).
- Log return: `lr = math.log(close / close[1])` — ADDITIVE across bars;
  `Σlr = math.log(close / close[n])`. Prefer for statistics (skill 26).
- Reconstruct price from cumulative log return: `math.exp(ta.cum(lr))`.
- Conversion: `r = exp(lr) − 1`; for small r, r ≈ lr.

### Cumulative & Compounding
- Cumulative simple return — accumulate:
```pine
var float eq = 1.0
eq *= (1.0 + r)
float cumReturn = eq - 1.0
```
- Multiplicative growth: `(1+r)^n` via `math.pow(1 + r, n)`.
- Geometric mean return per bar: `math.pow(eq, 1.0 / n) - 1`.

### Annualization (μ scales linearly, σ scales with √N)
- barsPerYear: 1D crypto ≈ 365 · 1D equities ≈ 252 · hourly crypto ≈ 8760.
- annualμ = μ_bar × barsPerYear; annualσ = σ_bar × sqrt(barsPerYear).
- Annualized return from total: `(1 + total)^(barsPerYear/n) − 1` (CAGR form).
- Monthly-based Sharpe convention (tester): annualize monthly stats with √12.

### Pine-Native Anchors
- `strategy.netprofit_percent` — total return vs initial capital.
- `strategy.equity` — live compounding curve (base for DD/metrics, skill 32).

## Common Mistakes
- Averaging simple returns across long horizons instead of compounding.
- Annualizing σ linearly (must be √N) or μ with √N (must be linear).
- Mixing log and simple returns in the same statistic.
- Using 252 bars/year for a 24/7 market (wrong σ scaling).

## Corrections & Updates
- [2026-09] Created; formulas standard; tester Sharpe convention verified
  (monthly returns, risk_free_rate param).
