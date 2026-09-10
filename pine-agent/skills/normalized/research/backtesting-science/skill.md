# Skill: backtesting-science

## Metadata

```yaml
id: backtesting-science
name: Backtesting Science
version: 1.0.0
path: skills/normalized/research/backtesting-science/skill.md
layer: RESEARCH
domains: [backtesting, validation]
triggers:
  english:
    - backtest interpretation
    - bar magnifier
    - deep backtesting
    - slippage commission costs
    - lookahead survivorship selection bias
    - backtest validation gate
  persian:
    - بک‌تست
    - سوگیری‌های بک‌تست
    - ذره‌بین کندل
    - هزینه و اسلیپیج
dependencies:
  mandatory: []
  optional: [strategy-engine, repainting-and-lookahead,
    walk-forward-and-validation, overfitting-and-robustness,
    statistical-testing]
status: normalized
priority: 1
```

## Purpose

Bias taxonomy and execution assumptions that make or break backtest validity —
the minimum validation bar before trusting ANY strategy report.

## Triggers

Select for: every backtest interpretation; before trusting any strategy
report; cost-model configuration; Bar Magnifier / Deep Backtesting usage and
budget questions; bias audits of results.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Backtest results to interpret | report | strategy run | yes |
| Cost model (commission/slippage) | parameters | user/broker reality | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Bias classification of a result | analysis | Pre-Verification |
| Execution-assumption model | parameters | Implementation |
| Validation gate verdict | checklist result | Post-Verification |

## Rules

1. Bias taxonomy: lookahead bias (future data leaking in — unconfirmed HTF,
   `lookahead_on` without `[1]`, plotting into past — see
   repainting-and-lookahead); survivorship bias (backtests run on ONE
   symbol's CURRENT data feed; delisted-history handling is not exposed —
   treat single-symbol results as conditionally valid); selection bias
   (cherry-picked symbol/timeframe/period); data-mining bias (many variants,
   keeping the best — K-trials inflation, see statistical-testing and
   overfitting-and-robustness); execution-assumption bias (fill mechanics,
   rule 2).
2. Execution assumptions (verified defaults): without Bar Magnifier — OHLC
   path heuristic (Open→High→Low→Close, or O→L→H→C with the closer extreme
   first); orders gapped over fill at bar OPEN, not trigger price. With
   `use_bar_magnifier = true` (Premium+): broker emulator checks LTF intrabar
   data for trigger breaches — budget ≤200,000 LTF bars; on long charts the
   EARLIEST bars lose magnifier coverage beyond
   `last_bar_index − (200000 / LTFbarsPerChartBar)`. Slippage = fixed adverse
   ticks (`slippage` param); commission = percent / cash_per_contract /
   cash_per_order; spread is NOT modeled natively — widen slippage or add
   commission to approximate. v6: 9,000-order historic cap → oldest orders
   TRIMMED silently (see strategy-engine). Deep Backtesting (Premium+): up to
   ~2M bars / 1M trades; results appear in the report only (not drawn on
   chart). Realtime: strategies execute at bar close unless
   `calc_on_every_tick` — backtest ≠ realtime by default (see
   tradingview-execution-model).
3. Backtest validation gate (minimum bar to clear): commission + slippage
   configured realistically; ≥ 100 closed trades (CIs — statistical-testing);
   repaint audit clean (repainting-and-lookahead checklist); OOS segment
   tested (walk-forward-and-validation); robustness checks
   (overfitting-and-robustness); expectancy > 2× costs per trade.

## Workflow

1. Classify which biases could affect the result (rule 1).
2. Verify the execution assumptions actually configured (rule 2).
3. Run the validation gate checklist (rule 3); interpret only after it clears.

## Constraints

- Net Profit read without costs/N/period context is invalid evidence.
- Single-symbol results are conditionally valid (survivorship limits).
- `process_orders_on_close = true` inflates realism (same-bar close fills).
- Comparing backtests across symbols without cost normalization is invalid.

## Assumptions

- Bar Magnifier/Deep Backtesting parameters verified vs official support
  articles (import-verified 2026-09: 200k LTF-bar cap, 2M bars / 1M trades).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Trusting one great backtest | no gate | rule 3: validation gate |
| Stop system filled at trigger price | no magnifier | rule 2: gap-fill-at-open reality |
| Silent order trimming | >9,000 orders | rule 2: v6 cap awareness |
| Costs ignored | unrealistic PF | rule 3: configure first |

## Dependencies

Optional: strategy-engine (order caps, strategy params),
repainting-and-lookahead (lookahead bias patterns),
walk-forward-and-validation (OOS gate), overfitting-and-robustness
(robustness battery), statistical-testing (CI/N requirements). Load only on
their own triggers.

## Examples

- "Is my backtest trustworthy?" → rule 3 gate.
- "Why did my stop fill worse than expected?" → rule 2 gap-fill-at-open.
- Persian: «چرا بک‌تست با واقعیت فرق داره؟» → rules 1–2 biases + fills.

## Verification Criteria

- Bias taxonomy applied before any result is reported.
- Cost model configured and documented.
- Validation gate checklist passed and recorded.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-006` import from `skills/incoming/51-backtesting-science.md`.
- Bar Magnifier 200,000-LTF-bar budget and Deep Backtesting ~2M bars / 1M
  trades independently re-verified at import (official support article +
  blog); v6 9,000-order cap consistent with strategy-engine (batch-001).
- Resolves the batch-001 parked candidates {09↔51} (related_but_distinct) —
  see index. Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `51-backtesting-science.md`
- Original source path: `skills/incoming/51-backtesting-science.md`
- Import batch: `batch-006`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-006)
