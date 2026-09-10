# Skill: strategy-engine

## Metadata

```yaml
id: strategy-engine
name: Strategy Engine
version: 1.0.0
path: skills/normalized/implementation/strategy-engine/skill.md
layer: IMPLEMENTATION
domains: [strategies, backtesting]
triggers:
  english:
    - strategy.entry
    - strategy.exit
    - strategy.order
    - pyramiding
    - OCA group
    - process_orders_on_close
    - calc_on_every_tick
    - broker emulator
    - bar magnifier
    - position sizing
    - commission slippage margin
    - strategy.position_avg_price
    - trade introspection
  persian:
    - موتور استراتژی
    - ورود و خروج سفارش
    - پرامیدینگ
    - سایز پوزیشن
    - کارمزد و اسلیپیج
    - شبیه‌ساز بروکر
dependencies:
  mandatory: []
  optional: [tradingview-execution-model, indicator-strategy-library-architecture, backtesting-science, trade-management, pine-v6]
status: normalized
priority: 2
```

## Purpose

Order mechanics, fills, pyramiding, sizing, commission/slippage/margin, and the
broker emulator's assumptions — the mechanics layer for building, backtesting,
and debugging any `strategy()` script, and for interpreting strategy reports
without trusting unrealistic fills.

## Triggers

Select for: building/backtesting any strategy; interpreting strategy reports;
debugging fills (gapped stops, missed limit fills, entry/exit timing);
sizing/pyramiding/commission questions; trade introspection API usage.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Strategy semantics question | description | user request | yes |
| Declaration settings (qty type, commission, slippage) | script metadata | target script | no |
| Plan tier (bar magnifier availability) | context | user request | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Order/exit/bracket design | implementation pattern | Implementation |
| Fill-assumption warnings | risk notes | Feasibility, Post-Verification |
| Trade-introspection API usage | implementation detail | Implementation |

## Rules

1. Order functions: `strategy.entry()` — main entry, REVERSES an opposite
   position, same-id re-entry = pyramiding addition (if allowed);
   `strategy.order()` — raw order, does NOT reverse (long + short = netted
   position); `strategy.exit()` — bracket exits tied to entries
   (`profit`, `loss`, `limit`, `stop`, `trail_price`, `trail_points`,
   `trail_offset`, `qty_percent`); plus `strategy.close()`,
   `strategy.close_all()`, `strategy.cancel()`.
2. OCA groups via `oca_name`: `strategy.oca.cancel` (fill cancels others),
   `strategy.oca.reduce` (fill reduces remaining qty proportionally); TP + SL
   on the same entry behave as a classic bracket (same OCA group).
3. Execution timing (default): signal on bar N → order placed → filled at open
   of bar N+1; `process_orders_on_close = true` fills at close of bar N
   (faster but an unrealistic assumption — treat with suspicion);
   `calc_on_every_tick = true` enables realtime per-tick execution (deviates
   from backtest); v6: the historic 9,000-order limit no longer errors —
   oldest orders are trimmed automatically.
4. Broker emulator fill assumptions (historical bars): no true intrabar path
   exists; emulator assumes Open → High → Low → Close if open is nearer to
   high, else Open → Low → High → Close; gaps contain no intrabars →
   stop/limit orders gapped over fill at the bar's OPEN price, not the trigger
   price; `use_bar_magnifier = true` (Premium+) uses LTF intrabar data for
   realistic fills.
5. Position & money mechanics: sizing via `strategy.fixed` (contracts),
   `strategy.cash` (currency), `strategy.percent_of_equity`, or explicit
   `qty`/`qty_percent`; pyramiding N = max same-direction concurrent entries,
   each tracked separately, `strategy.position_avg_price` = weighted average;
   commission via `strategy.commission.percent` | `cash_per_contract` |
   `cash_per_order`; slippage in ticks applied adversely; `margin_long/short`
   % (100 = no leverage), equity below margin requirement → margin call
   liquidation (`strategy.margin_calls` counter).
6. Trade introspection: `strategy.position_size`,
   `strategy.position_avg_price`, `strategy.opentrades.*` (entry price, bars
   held, unrealized MAE/MFE per tranche), `strategy.closedtrades.*`
   (`entry_price`, `exit_price`, `profit`, `return`, `max_drawdown` = MAE,
   `max_runup` = MFE, `entry_bar_index`, `exit_bar_index`).

## Workflow

1. Map the trading logic to order functions (rule 1); choose
   `strategy.entry` vs `strategy.order` by reversal semantics.
2. Wire exits as OCA brackets (rule 2); confirm tick-vs-price unit usage.
3. Set sizing/commission/slippage/margin explicitly (rule 5) — never defaults.
4. Interpret any backtest anomaly through the emulator assumptions (rule 4)
   before suspecting code.
5. Record fill-assumption warnings into Feasibility for the backtest design.

## Constraints

- `use_bar_magnifier` and bar-detalization features are plan-gated — never
  assumed available.
- Emulator fill assumptions are approximations; backtest results are not
  promises of live fills.

## Assumptions

- Pine v6 strategy semantics as claimed by the source (verified against
  official strategies docs per source).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| "Backtest fills too perfectly" | default settings | rule 4 assumptions + configure rule 5 costs |
| Position reversed unexpectedly | `strategy.order` used for reversal | use `strategy.entry` |
| TP/SL triggers at wrong distance | ticks vs price confusion | `profit`/`loss` = ticks; `limit`/`stop` = price |
| Inflated metrics | zero commission/slippage | rule 5 explicit configuration |

## Dependencies

Optional: tradingview-execution-model (fill timing vs realtime),
indicator-strategy-library-architecture (declaration params), backtesting-science
(evaluation methodology), trade-management (exit design depth), pine-v6 (order
trimming change). Load only on their own triggers.

## Examples

- "Add TP/SL to my entry" → rule 1 `strategy.exit` + rule 2 OCA bracket.
- "My stop filled at a price the bar never touched" → rule 4 gap-fill-at-open.
- Persian: «چرا بک‌تست من اغراق‌شده است؟» → rule 4/5: emulator assumptions + costs.

## Verification Criteria

- Exit brackets use consistent units (ticks for `profit`/`loss`, price for
  `limit`/`stop`).
- Reversal intent implemented via `strategy.entry`, not `strategy.order`.
- Commission/slippage/margin configured explicitly in any backtest.
- Backtest conclusions acknowledge emulator assumptions (Post-Verification
  honesty note).

## Ambiguities

- None from the source.

## Missing Information

- July 2026 release-note changes (recorded during import verification; not
  invented into rules): new `calc_on_every_history_tick` declaration parameter
  (Premium+; per-tick execution across historical bars); Properties/report UI
  renamed (Bar detalization, leverage inputs, Limit order execution assumption
  dropdown with `backtest_fill_limits_assumption` parameter, Order execution
  delay). Declaration parameters cited in this Skill remain valid; a future
  source revision should cover the new parameter and UI naming.

## Import Notes

- Batch `batch-001` import from `skills/incoming/09-strategy-engine.md`.
- Structural reorganization into the Skill template only; no semantic changes.
  Source's cross-reference "see skill 09/12" style pointers resolved into
  optional dependencies per the no-duplication rule.

## Source Reference

- Original filename: `09-strategy-engine.md`
- Original source path: `skills/incoming/09-strategy-engine.md`
- Import batch: `batch-001`
- Normalization status: normalized
- Validation status: passed (with documented verification scope)
- Import date: 2026-09 (batch-001)
