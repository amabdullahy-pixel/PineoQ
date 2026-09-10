# Skill: monte-carlo-and-resampling

## Metadata

```yaml
id: monte-carlo-and-resampling
name: Monte Carlo & Resampling
version: 1.0.0
path: skills/normalized/quant/monte-carlo-and-resampling/skill.md
layer: QUANT
domains: [statistics, simulation]
triggers:
  english:
    - bootstrap
    - Monte Carlo equity
    - drawdown distribution
    - probability of ruin
    - block bootstrap
    - math.random seed reproducibility
    - scenario analysis
  persian:
    - مونت کارلو
    - بوت‌استرپ
    - توزیع افت سرمایه
    - احتمال نابودی
dependencies:
  mandatory: []
  optional: [strategy-engine, overfitting-and-robustness, stochastic-processes, pine-performance-engineering]
status: normalized
priority: 2
```

## Purpose

Bootstrap, Monte Carlo equity simulation, and scenario analysis implementable
inside Pine's execution budget — robustness checks of a strategy's trade
sequence, drawdown distributions, and CI bands on expectancy.

## Triggers

Select for: robustness checks of trade sequences; risk envelopes /
drawdown distributions; probability-of-ruin estimates; CI bands on expectancy;
"stress test my equity curve" requests.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Trade sample (closed trades) | data | strategy results | yes |
| Iteration count + seed policy | design decision | user/agent | yes |
| Loss-cap definition (for P(ruin)) | parameter | user | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Bootstrap/MC harness design | implementation pattern | Implementation |
| Percentile/DD/ruin outputs | analysis artifacts | Post-Verification reporting |
| Budget constraints | feasibility notes | Feasibility |

## Rules

1. Randomness in Pine: `math.random(min, max, seed)` — CONST seed = fully
   reproducible sequence across reloads; seed omitted/varies = new sequence
   per execution. Run ALL simulation on the LAST bar only, inside one bounded
   loop (`if barstate.islast` → collect trades → simulate → report).
2. Trade sample: iterate `strategy.closedtrades` collecting
   `strategy.closedtrades.profit_percent(i)` into an array; trade lists cap
   around 9,000 historic trades (v6 trims oldest otherwise — see
   strategy-engine); Deep Backtesting retains more (plan-dependent — verify).
3. Bootstrap (with replacement): resample trade indices within a capped
   iteration loop; accumulate equity/peak/maxDD per path; store only summary
   outcomes; report percentiles of the static results array (5th/50th/95th
   percentile final equity, DD distribution, P(ruin) = share of paths
   breaching −X%).
4. Block bootstrap: resample BLOCKS of k consecutive trades (k ≈ 5–20) instead
   of singles when trades are serially correlated — preserves win/loss
   clustering (volatility clustering, see time-series-analysis).
5. Scenario analysis (parametric MC): fit per-bar log-return μ, σ → simulate
   GBM paths (see stochastic-processes) → stress the strategy's logic
   conceptually or simulate equity with the resampled return stream.
6. Budget rules (hard constraints): loop ≤ 500 ms/bar, total ≤ 20 s/40 s;
   practical caps — iterations ≤ a few thousand with n ≤ ~2,000 trades on
   last bar only; test the actual budget; arrays ≤ 100,000 elements — store
   summary stats, not every path; fixed seeds → identical results per reload
   (auditable).

## Workflow

1. Collect the trade sample once on the last bar (rule 2).
2. Choose bootstrap vs block-bootstrap by autocorrelation of trades
   (rules 3–4; ACF via regression-correlation/time-series-analysis).
3. Cap iterations and arrays per budget rules (rule 6); fix seeds (rule 1).
4. Report percentile outcomes with honest framing — they model the PAST trade
   set, not guarantees.

## Constraints

- Simulation runs on the last bar only — never per-bar heavy MC.
- All loops capped; fixed seeds mandatory for auditable results.

## Assumptions

- `math.random` seed reproducibility and trade-list access verified against
  reference/FAQ by the source; the ~9,000-trade cap note is consistent with
  strategy-engine (batch-001, v6 trim behavior).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Heavy MC every bar | script killed | rule 1: last-bar-only execution |
| Single-trade shuffle on autocorrelated trades | underestimated DD risk | rule 4: block bootstrap |
| Percentiles treated as guarantees | overconfidence | honest framing: models the past trade set |
| Nested loops uncapped | 500 ms explosion | rule 6: iteration caps |

## Dependencies

Optional: strategy-engine (trade introspection APIs),
overfitting-and-robustness (robustness framing), stochastic-processes (GBM
engines), pine-performance-engineering (budget depth). Load only on their own
triggers.

## Examples

- "How bad can my drawdown get?" → rules 2–3 bootstrap DD distribution.
- "My wins cluster — resample fairly" → rule 4 block bootstrap.
- Persian: «احتمال نابودی استراتژی‌ام چقدره؟» → rule 3 P(ruin) from paths.

## Verification Criteria

- Simulation gated to `barstate.islast`; iteration caps present.
- Fixed seeds used; results reproducible across reloads.
- Serial correlation handled (block bootstrap where indicated).
- Output framed as past-trade-set modeling, not guarantees.

## Ambiguities

- None from the source.

## Missing Information

- Deep Backtesting trade-retention specifics (plan-dependent — re-verify at
  use time, consistent with shared plan-limit caveat).

## Import Notes

- Batch `batch-003` import from `skills/incoming/28-monte-carlo-and-resampling.md`.
- Structural reorganization only; no semantic changes. The ~9,000-trade cap
  cross-reference aligns with strategy-engine's v6 order-trimming facts
  (batch-001).

## Source Reference

- Original filename: `28-monte-carlo-and-resampling.md`
- Original source path: `skills/incoming/28-monte-carlo-and-resampling.md`
- Import batch: `batch-003`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-003)
