# Skill: performance-metrics

## Metadata

```yaml
id: performance-metrics
name: Performance Metrics
version: 1.0.0
path: skills/normalized/quant/performance-metrics/skill.md
layer: QUANT
domains: [performance-metrics, evaluation]
triggers:
  english:
    - expectancy
    - profit factor
    - win rate
    - Sharpe Sortino Calmar
    - recovery factor
    - MAE MFE
    - strategy.netprofit
    - custom metrics dashboard
  persian:
    - شاخص‌های عملکرد
    - نسبت سود به ضرر
    - نرخ برد
    - شارپ و سورتینو
dependencies:
  mandatory: []
  optional: [financial-mathematics, statistical-testing, drawing-and-visualization, strategy-engine]
status: normalized
priority: 1
```

## Purpose

Expectancy, profit factor, win rate, Sharpe/Sortino/Calmar, recovery factor,
and MAE/MFE — native strategy.* access plus manual computation for evaluation,
comparison, and custom dashboards.

## Triggers

Select for: evaluating/comparing strategies; building custom metric
dashboards; interpreting tester reports (Sharpe basis, PF definition);
exit-efficiency analysis via MAE/MFE; metric-based overfitting checks.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Strategy results | data | strategy script/tester | yes |
| Metric set to compute | list | user/formalization | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Metric implementations | code patterns | Implementation |
| Joint-reading discipline | verification output | Post-Verification |
| Dashboard data plumbing | design output | drawing-and-visualization |

## Rules

1. Native code access (verified names): totals — strategy.netprofit,
   netprofit_percent, grossprofit, grossloss, openprofit, equity,
   initial_capital; counts — closedtrades, wintrades, losstrades, eventrades,
   opentrades; extremes — max_drawdown(_percent), max_runup(_percent); per
   trade i — closedtrades.profit(i), .profit_percent(i), .max_drawdown(i)
   (= MAE), .max_runup(i) (= MFE), .entry_price/.exit_price, .bars.
2. NO built-in ratio functions — Sharpe/Sortino/Calmar exist ONLY in the
   Strategy Tester report; there is no `strategy.sharpe()` in code (negative
   claim → verify-before-use gate). Manual patterns: win rate
   wintrades/float(n) (guard n>0); PF = grossprofit/grossloss (guard 0;
   realized trades only — official definition excludes open trades);
   expectancy per trade = netprofit/n.
3. Sharpe (tester convention): monthly returns vs risk-free —
   (MR − RFR_monthly)/SD_monthly; annualized ≈ ×√12 when comparing
   externally; risk_free_rate param in strategy() (default 2%/yr); in-script:
   build monthly return array from equity (bucket by month — see
   time-series-analysis), compute mean/σ, divide.
4. Sortino: same numerator, denominator = downside deviation
   DD = sqrt(mean(min(0, r)²)) over monthly returns.
5. Calmar & recovery factor: Calmar = CAGR/|maxDD| (CAGR per
   financial-mathematics; maxDD = strategy.max_drawdown_percent); Recovery
   Factor = netprofit/|max drawdown|.
6. MAE/MFE usage: MFE far above realized profit → exit too late; MAE ≈ risk →
   stops about right; max_drawdown(i) is the ADVERSE excursion of the trade.
7. Reading discipline: judge metrics JOINTLY — PF < 1.3 weak; Sharpe < 1
   (annualized, daily data) weak; Calmar > 1 solid; expectancy must exceed
   costs; verify N with CIs (see statistical-testing); always report metrics
   WITH trade count and period.

## Workflow

1. Pull native totals/counts/trade arrays (rule 1).
2. Compute ratios manually where needed (rules 2–5); state the convention
   (monthly basis, RFR) for Sharpe-class metrics.
3. Apply MAE/MFE exit-efficiency analysis (rule 6).
4. Read jointly with N and period reported (rule 7); feed sets (not single
   metrics) to optimization decisions.

## Constraints

- No strategy.sharpe()-style calls (rule 2 gate).
- PF from realized trades only.
- Single-metric optimization is forbidden (overfitting) — use metric sets.

## Assumptions

- Native names verified against the v6 reference; tester formulas verified
  against TradingView support articles (Sharpe/Sortino/PF) by the source.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Sharpe quoted without basis | convention unclear | rule 3: state monthly/RFR/annualization |
| PF includes open trades | definition drift | rule 2: realized only |
| One-metric optimization | overfit signature | rule 7: metric sets |
| MAE/MFE swapped | wrong exit analysis | rule 6: max_drawdown(i) = MAE |

## Dependencies

Optional: financial-mathematics (CAGR/annualization),
statistical-testing (CIs on N), drawing-and-visualization (dashboard
rendering), strategy-engine (trade introspection). Load only on their own
triggers.

## Examples

- "Compute expectancy and PF in-script" → rule 2 manual patterns.
- "Why is my tester Sharpe not comparable?" → rule 3 convention check.
- Persian: «داشبورد آمار استراتژی بساز» → rules 1–2 + dashboard skill.

## Verification Criteria

- All ratio guards present (n>0, grossloss≠0).
- Sharpe-class metrics state their basis (monthly, RFR, annualization).
- PF realized-only; metrics reported with N and period.
- MAE/MFE semantics correct in any exit analysis.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-004` import from `skills/incoming/32-performance-metrics.md`.
- The "no built-in ratio functions" claim is a negative claim — preserved as a
  verify-before-use gate per convention. Resolves batch-003 pending pointers
  from financial-mathematics and probability. Structural reorganization only.

## Source Reference

- Original filename: `32-performance-metrics.md`
- Original source path: `skills/incoming/32-performance-metrics.md`
- Import batch: `batch-004`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-004)
