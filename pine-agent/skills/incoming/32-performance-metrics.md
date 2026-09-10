---
name: performance-metrics
category: Financial Math & Risk
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/support/solutions/43000681694-sharpe-ratio/
  - https://www.tradingview.com/support/solutions/43000681697-sortino-ratio/
  - https://www.tradingview.com/support/solutions/43000681698-profit-factor/
---

# Performance Metrics

## Purpose
Expectancy, PF, win rate, Sharpe/Sortino/Calmar, recovery factor, MAE/MFE —
native access + manual computation.

## When to Use
- Evaluating/comparing strategies; building custom dashboards (skill 10).

## Core Knowledge

### Native Code Access (verified names)
- Totals: `strategy.netprofit`, `strategy.netprofit_percent`,
  `strategy.grossprofit`, `strategy.grossloss`, `strategy.openprofit`,
  `strategy.equity`, `strategy.initial_capital`.
- Counts: `strategy.closedtrades`, `strategy.wintrades`, `strategy.losstrades`,
  `strategy.eventrades`, `strategy.opentrades`.
- Extremes: `strategy.max_drawdown(_percent)`, `strategy.max_runup(_percent)`.
- Per trade i: `strategy.closedtrades.profit(i)`, `.profit_percent(i)`,
  `.max_drawdown(i)` = MAE, `.max_runup(i)` = MFE, `.entry_price/.exit_price`, `.bars`.

### NO built-in ratio functions
- Sharpe/Sortino/Calmar exist ONLY in the Strategy Tester report — no
  `strategy.sharpe()` in code. Manual patterns:
```pine
// trade-level stats
int n  = strategy.closedtrades
float wr = n > 0 ? strategy.wintrades / float(n) : na
float pf = strategy.grossloss != 0 ? strategy.grossprofit / strategy.grossloss : na
// expectancy per trade (in R or currency):
float exp = n > 0 ? strategy.netprofit / n : na
```

### Sharpe (tester convention) — monthly returns vs risk-free
- Sharpe = (MR − RFR_monthly) / SD_monthly; annualized ≈ ×√12 when comparing
  externally. risk_free_rate param in strategy() (default 2%/yr).
- In-script: build monthly return array from equity (bucket by month, skill 26),
  compute mean/σ, divide.

### Sortino — same numerator, denominator = downside deviation
- DD = sqrt( mean( min(0, r)² ) ) over monthly returns (only downside counts).

### Calmar & Recovery Factor
- Calmar = CAGR / \|maxDD\| (CAGR from skill 29; maxDD = strategy.max_drawdown_percent).
- Recovery Factor = netprofit / \|max drawdown\|.

### MAE/MFE usage
- Exit-efficiency: MFE far above realized profit → exit too late; MAE ≈ risk →
  stops about right.

### Reading Discipline
- Judge metrics JOINTLY: PF<1.3 weak; Sharpe<1 (annualized, daily data) weak;
  Calmar>1 solid; expectancy must exceed costs; verify N (skill 25 CIs).
- Report metrics WITH trade count and period.

## Common Mistakes
- Quoting Sharpe from the report without checking monthly-return basis/RFR.
- PF computed including open trades (official: realized only).
- Optimizing one metric (e.g., PF) → overfit (skill 54); use metric SETS.
- MAE/MFE confusion: max_drawdown(i) is the ADVERSE excursion of the trade.

## Corrections & Updates
- [2026-09] Created; native names verified against v6 reference; tester
  formulas verified against support articles.
