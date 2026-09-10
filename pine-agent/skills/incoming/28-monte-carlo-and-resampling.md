---
name: monte-carlo-and-resampling
category: Statistics & Probability
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/pine-script-docs/writing/limitations/
  - https://www.tradingview.com/pine-script-docs/faq/strategies/
---

# Monte Carlo & Resampling

## Purpose
Bootstrap, Monte Carlo equity simulation, scenario analysis — implementable
inside Pine's execution budget.

## When to Use
- Robustness checks of a strategy's trade sequence (skill 54), risk envelopes,
  drawdown distributions, CI bands on expectancy.

## Core Knowledge

### Randomness in Pine
- `math.random(min, max, seed)` → series float. CONST seed = fully reproducible
  sequence across reloads; seed omitted/varies = new sequence per execution.
- Pattern: run ALL simulation on the LAST bar only, inside one bounded loop:
  `if barstate.islast` → collect trades → simulate → report.

### Building the Trade Sample
```pine
array<float> profits = array.new<float>()
for i = 0 to strategy.closedtrades - 1
    array.push(profits, strategy.closedtrades.profit_percent(i))
```
- Trade lists cap at ~9,000 historic trades (v6 trims oldest otherwise);
  Deep Backtesting retains more (plan-dependent — verify).

### Bootstrap (with replacement)
```pine
mcBootstrap(array<float> p, int iters, int seedBase) =>
    int n = array.size(p)
    var array<float> finals = array.new<float>()
    for it = 1 to iters                       // cap iters: budget!
        float eq = 0.0, float maxDD = 0.0, float peak = 0.0
        for i = 1 to n
            int j = int(math.floor(math.random(0, n - 1, seedBase + it * 1000 + i)))
            eq += array.get(p, j)
            peak := math.max(peak, eq)
            maxDD := math.max(maxDD, peak - eq)
        array.push(finals, eq)
        // optionally store maxDD per iteration too
```
- Report percentiles of outcomes: sort results array → pick by index
  (percentile-style on the STATIC results array).
- Outputs: 5th/50th/95th percentile final equity, DD distribution,
  P(ruin) = share of paths breaching −X%.

### Block Bootstrap (better for serially correlated trades)
- Resample BLOCKS of k consecutive trades (k≈5–20) instead of singles —
  preserves clustering of wins/losses (volatility clustering, skill 26).

### Scenario Analysis (parametric MC)
- Fit per-bar log-return μ, σ → simulate GBM paths (skill 27) → stress the
  strategy's logic conceptually, or simulate equity with resampled return stream.

### Budget Rules (hard constraints)
- Loop ≤ 500ms/bar; total ≤ 20s/40s (skill 01). Practical caps: iterations ≤ a
  few thousand with n ≤ ~2,000 trades on last bar only; test actual budget.
- Arrays ≤ 100,000 elements; store only summary stats, not every path.
- Reproducibility: fixed seeds → identical results per reload (auditable).

## Common Mistakes
- Running heavy MC every bar → script killed. LAST BAR ONLY.
- Naive single-trade shuffle on autocorrelated trades → underestimates DD risk.
- Treating bootstrap percentiles as guarantees (they model the PAST trade set).
- No iteration cap on nested loops (500ms explosion).

## Corrections & Updates
- [2026-09] Created; math.random seed reproducibility + trade-list access
  verified against reference/FAQ; ~9,000 trade cap note (v6 trims, skill 09).
