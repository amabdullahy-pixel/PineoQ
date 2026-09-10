# Skill: time-series-analysis

## Metadata

```yaml
id: time-series-analysis
name: Time Series Analysis
version: 1.0.0
path: skills/normalized/quant/time-series-analysis/skill.md
layer: QUANT
domains: [statistics, time-series]
triggers:
  english:
    - rolling vs expanding statistics
    - stationarity
    - variance ratio
    - seasonality day of week
    - volatility clustering
    - EWMA volatility
    - warm-up period
  persian:
    - تحلیل سری زمانی
    - ایستایی
    - فصلی بودن
    - خوشه‌ای بودن نوسان
dependencies:
  mandatory: []
  optional: [regression-correlation, statistical-distributions, volatility-indicators, data-integrity]
status: normalized
priority: 2
```

## Purpose

Rolling/expanding statistics, stationarity, trend/seasonality decomposition,
autocorrelation, and volatility clustering as trading-time-series practice in
Pine — with warm-up honesty and timezone-correct bucketing built in.

## Triggers

Select for: regime characterization; volatility modeling (EWMA/ATR ranks);
calendar/seasonality effects; signal preprocessing; "is this series
stationary?"; expanding-window statistics.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Time-series question / preprocessing need | description | formalization contract | yes |
| Bars available per bucket/window | context | data characteristics | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Stationarity/modeling verdict | design decision | Implementation Planning |
| Seasonality/volatility estimators | implementation pattern | Implementation |
| Warm-up gating requirements | verification checks | Pre-Verification |

## Rules

1. Rolling vs expanding: rolling = any `ta.*` with a length parameter
   (window slides); expanding = `ta.cum`, `ta.max`/`ta.min` (running
   extremes), or `var` sums/counts for expanding mean/variance. Warm-up
   honesty: all rolling stats are na/garbage before `len` bars — gate logic on
   `bar_index >= warmupBars`.
2. Stationarity (practical diagnostics): prices are non-stationary; returns
   ≈ stationary-ish (still fat-tailed — see statistical-distributions).
   Informal checks: rolling mean drifting? rolling variance ratio far from 1?
   ACF of returns decaying fast vs ACF of prices not decaying? Variance-ratio
   sketch: Var(k-bar returns)/(k·Var(1-bar returns)) — ≈1 random walk, >1
   trending, <1 mean-reverting. ALWAYS model returns or spreads (not raw
   prices) for statistical logic.
3. Trend & seasonality decomposition (informal): trend via long SMA/linreg
   slope (see regression-correlation); seasonality via average return per
   day-of-week/month bucket accumulated in `var` arrays; report seasonality
   only with enough samples per bucket + CI (see statistical-testing); ALWAYS
   use `syminfo.timezone` in `dayofweek(time, syminfo.timezone)` bucketing
   (timezone discipline — see data-integrity).
4. Autocorrelation & persistence: ACF via `ta.correlation(r, r[h], len)` per
   lag; white-noise band ±1.96/√N; Ljung-Box-style aggregation (sum of r(h)²
   weighted) as a manual persistence score.
5. Volatility clustering: |r| autocorrelation ≫ r autocorrelation → clusters
   (GARCH concept). Pine approximations: EWMA volatility
   σ²ₜ = λ·σ²ₜ₋₁ + (1−λ)·r²ₜ (λ≈0.94, RiskMetrics) via `var` recursion; ATR
   percentile ranks (see volatility-indicators).

## Workflow

1. Decide the modeling object: returns/spreads, never raw prices (rule 2).
2. Apply warm-up gating to every rolling statistic (rule 1).
3. Diagnose stationarity with the informal checks (rule 2); route trending vs
   mean-reverting conclusions to stochastic-processes.
4. Bucket seasonality with timezone-correct arrays and CI reporting (rule 3).
5. Detect clustering; implement EWMA/ATR-rank volatility proxies (rule 5).

## Constraints

- No formal stationarity tests (ADF) in Pine — informal/variance-ratio
  approximations only.
- Seasonality claims require per-bucket sample sufficiency + CI.

## Assumptions

- Pine idiom patterns verified against the reference by the source; λ≈0.94 is
  the RiskMetrics convention.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Stats run on prices | nonsense correlations | rule 2: returns/spreads |
| Seasonality from few observations | unstable buckets | rule 3: samples + CI |
| Warm-up na in logic | early-bar garbage signals | rule 1: bar_index gate |
| Chart-timezone dayofweek buckets | DST-shifted seasonality | rule 3: syminfo.timezone |

## Dependencies

Optional: regression-correlation (slope/ACF math),
statistical-distributions (fat-tailed returns), volatility-indicators
(ATR ranks), data-integrity (timezone rules). Load only on their own
triggers.

## Examples

- "Is Monday different for this symbol?" → rule 3 bucketed returns + CI.
- "Model volatility that reacts to clusters" → rule 5 EWMA recursion.
- Persian: «فیلتر روز هفته‌ام جواب نمی‌دهد» → rule 3: timezone + sample checks.

## Verification Criteria

- Statistical logic operates on returns/spreads, not raw prices.
- Warm-up gating present on all rolling statistics.
- Seasonality reported with per-bucket sample sizes and CIs.
- Timezone-correct bucketing verified (syminfo.timezone).

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-003` import from `skills/incoming/26-time-series-analysis.md`.
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `26-time-series-analysis.md`
- Original source path: `skills/incoming/26-time-series-analysis.md`
- Import batch: `batch-003`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-003)
