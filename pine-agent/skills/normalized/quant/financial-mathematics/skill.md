# Skill: financial-mathematics

## Metadata

```yaml
id: financial-mathematics
name: Financial Mathematics
version: 1.0.0
path: skills/normalized/quant/financial-mathematics/skill.md
layer: QUANT
domains: [mathematics, performance-metrics]
triggers:
  english:
    - simple vs log return
    - cumulative return compounding
    - annualization sqrt N
    - CAGR
    - geometric mean return
    - bars per year
  persian:
    - ریاضیات مالی
    - بازده ساده و لگاریتمی
    - سده مرکب
    - سالانه‌سازی
dependencies:
  mandatory: []
  optional: [mathematical-foundation, performance-metrics, backtesting-science, time-series-analysis]
status: normalized
priority: 2
```

## Purpose

Returns, log returns, cumulative/annualized returns, and compounding in exact
Pine forms — the return-computation baseline for any performance calculation,
normalization, or return-based statistic.

## Triggers

Select for: any performance calculation or return normalization; log-vs-simple
return choices; annualization (μ vs σ scaling); CAGR/geometric-mean questions;
reconstructing prices from cumulative returns.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Return/compounding question | description | formalization contract | yes |
| Market calendar (bars per year) | context | target symbol | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Return-statistic implementation | knowledge applied | Implementation |
| Annualization parameters | design facts | performance-metrics |
| Scaling-correctness checks | verification items | Pre/Post-Verification |

## Rules

1. Returns: simple return per bar `r = close / close[1] - 1` (≈
   `ta.change(close)/close[1]`); log return `lr = math.log(close / close[1])`
   — ADDITIVE across bars, Σlr = math.log(close/close[n]); prefer log returns
   for statistics; reconstruct price from cumulative log return via
   `math.exp(ta.cum(lr))`; conversion r = exp(lr) − 1 (for small r, r ≈ lr).
2. Cumulative & compounding: accumulate multiplicative equity
   (`var float eq = 1.0` then `eq *= (1.0 + r)`); multiplicative growth
   `(1+r)^n` via `math.pow(1 + r, n)`; geometric mean return per bar
   `math.pow(eq, 1.0/n) - 1`.
3. Annualization: μ scales LINEARLY (annualμ = μ_bar × barsPerYear); σ scales
   with √N (annualσ = σ_bar × sqrt(barsPerYear)); barsPerYear — 1D crypto ≈
   365, 1D equities ≈ 252, hourly crypto ≈ 8760; annualized return from total
   via the CAGR form `(1 + total)^(barsPerYear/n) − 1`; the tester's
   Sharpe convention annualizes monthly stats with √12.
4. Pine-native anchors: `strategy.netprofit_percent` (total return vs initial
   capital); `strategy.equity` (live compounding curve — base for
   DD/metrics, see performance-metrics).

## Workflow

1. Choose simple vs log returns per use (statistics → log; reporting →
   either, consistently — rule 1).
2. Compound multiplicatively; never average simple returns across long
   horizons (rule 2).
3. Annualize with the correct scaling (rule 3); match barsPerYear to the
   actual market calendar.
4. Wire tester anchors (rule 4) where strategy context exists.

## Constraints

- Never mix log and simple returns in the same statistic.
- Annualization scaling is asymmetric: μ linear, σ √N — never swapped.

## Assumptions

- Formulas are standard; the tester Sharpe convention (monthly returns,
  risk-free-rate parameter) verified by the source against TradingView's
  Sharpe documentation.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Averaging simple returns long-horizon | understated growth | rule 2: compound multiplicatively |
| σ annualized linearly (or μ with √N) | wrong risk numbers | rule 3: correct scaling |
| 252 bars/year on 24/7 market | wrong σ scaling | rule 3: market-matched barsPerYear |
| Mixed log/simple in one stat | inconsistent totals | constraint: pick one basis |

## Dependencies

Optional: mathematical-foundation (exp/log precision),
performance-metrics (metric consumers), backtesting-science (evaluation
context), time-series-analysis (return-series statistics). Load only on their
own triggers.

## Examples

- "Annualize my hourly strategy's Sharpe inputs" → rule 3 with 8760 bars/year.
- "Rebuild price from my cumulative log-return indicator" → rule 1
  `math.exp(ta.cum(lr))`.
- Persian: «بازده کل را سالانه کن» → rule 3 CAGR form.

## Verification Criteria

- Return basis (log/simple) consistent within each statistic.
- Annualization scaling correct (μ linear, σ √N) and calendar-matched.
- Compounding uses multiplicative accumulation.
- Tester anchors used where strategy context exists.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-003` import from `skills/incoming/29-financial-mathematics.md`.
- Resolves the batch-002 pending optional-dependency pointer from
  mathematical-foundation. Structural reorganization only; no semantic
  changes.

## Source Reference

- Original filename: `29-financial-mathematics.md`
- Original source path: `skills/incoming/29-financial-mathematics.md`
- Import batch: `batch-003`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-003)
