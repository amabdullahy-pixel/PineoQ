# Skill: regression-correlation

## Metadata

```yaml
id: regression-correlation
name: Regression & Correlation
version: 1.0.0
path: skills/normalized/quant/regression-correlation/skill.md
layer: QUANT
domains: [statistics, trend-fitting]
triggers:
  english:
    - correlation Pearson
    - covariance
    - least squares regression
    - R squared
    - residuals
    - autocorrelation
    - regression channel
    - linreg offset
  persian:
    - همبستگی
    - کوواریانس
    - رگرسیون خطی
    - خودهمبستگی
    - کانال رگرسیون
dependencies:
  mandatory: []
  optional: [statistics-core, time-series-analysis, statistical-arbitrage, analytical-geometry]
status: normalized
priority: 2
```

## Purpose

Correlation, covariance, least-squares regression, R², residuals, and
autocorrelation in Pine — including `ta.linreg` offset semantics, manual OLS
for R²/residual work, and the spurious-regression guard for trending series.

## Triggers

Select for: relationship-strength questions between series; trend fitting and
regression channels; pair-spread analysis; autocorrelation/persistence
testing; "is my R² meaningful?" audits.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Relationship/fitting question | description | formalization contract | yes |
| Series stationarity character | context | time-series-analysis | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Regression/correlation implementation | knowledge applied | Implementation |
| Spurious-regression warnings | warnings | Pre-Verification |
| Channel/fit geometry | design output | Implementation Planning |

## Rules

1. Correlation & covariance: `ta.correlation(s1, s2, len)` = rolling Pearson r;
   covariance manually `cov = ta.sma(s1*s2, len) − ta.sma(s1,len)·ta.sma(s2,len)`
   (biased); correlation = cov/(σ1·σ2). Interpretation guard: r measures LINEAR
   association only — nonlinearity, outliers, and regime shifts break it;
   rolling r is itself noisy — require |r| persistence (e.g., r > 0.7 for K
   consecutive bars) before acting.
2. Least-squares regression (manual OLS on x = 0..len−1 over src) for R² and
   residuals: slope/intercept via centered sums (guard den ≠ 0); fitted value
   at offset k back is ŷ = intercept + slope·(len−1−k) — exactly what
   `ta.linreg(src, len, offset)` returns (offset=0 → current fit point; offset
   shifts WITHIN the window, not history). Residual eᵢ = yᵢ − ŷᵢ; residual σ
   via `ta.stdev` of the residual series; R² = 1 − SSres/SStot; for
   2-variable OLS, R² = r².
3. Linear regression channel: mid = `ta.linreg(close, len, 0)`; bands = mid ±
   mult·stdev(residuals); draw via `line.new` from fit endpoints (see
   analytical-geometry); slope = per-bar fit slope (divide by bar distance —
   never read slope from raw linreg values).
4. Autocorrelation: r(h) = `ta.correlation(src, src[h], len)` per lag;
   significance ≈ ±1.96/√N (white-noise band); significant positive lag-1 →
   trending persistence; negative → mean-reversion tendency (see
   time-series-analysis / stochastic-processes).
5. Spurious regression: regressing two non-stationary price series can give
   high R² with no relationship — needs cointegration thinking (see
   statistical-arbitrage); model returns/spreads, not raw prices.

## Workflow

1. Establish stationarity of inputs first (rule 5); switch to returns/spreads
   when needed.
2. Choose built-in (`ta.correlation`, `ta.linreg`) vs manual OLS by need
   (rules 1–2); manual when R²/residuals are required.
3. Apply the persistence/significance guards (rules 1, 4).
4. Build channels from residuals, not raw σ (rule 3).

## Constraints

- `ta.linreg(src, len, offset)` shifts within the window — it is not a
  history offset.
- High R² on trending prices is not evidence of relationship (rule 5).

## Assumptions

- `ta.linreg` offset semantics verified against the v6 reference by the
  source.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| High R² on two trending prices | spurious regression | rule 5: returns/spreads + cointegration thinking |
| Slope misread from linreg | no bar-distance division | rule 3: slope = Δfit / bars |
| offset treated as history shift | wrong series | rule 2: window-internal shift |
| Correlation unstable across regimes | contradictory signals | rule 1: recompute per regime |

## Dependencies

Optional: statistics-core (dispersion tools), time-series-analysis
(stationarity diagnostics), statistical-arbitrage (cointegration/spreads),
analytical-geometry (channel drawing). Load only on their own triggers.

## Examples

- "Fit a regression channel with 2σ bands" → rule 3.
- "Is my pair spread mean-reverting?" → rule 4 autocorrelation + rule 5
  stationarity (see statistical-arbitrage for depth).
- Persian: «ضریب همبستگی‌ام ناپایدار است» → rule 1: persistence requirement.

## Verification Criteria

- Stationarity of regressed series established or returns/spreads used.
- Persistence/significance guards applied to rolling correlations.
- Channel bands computed from residual σ.
- linreg offset usage matches window-internal semantics.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-003` import from `skills/incoming/24-regression-correlation.md`.
- Structural reorganization only; no semantic changes. Cross-references to
  skills 19/26/27/47/50 became optional dependencies (19/26 registered this
  batch or earlier; 27/47/50 pending with deterministic ids).

## Source Reference

- Original filename: `24-regression-correlation.md`
- Original source path: `skills/incoming/24-regression-correlation.md`
- Import batch: `batch-003`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-003)
