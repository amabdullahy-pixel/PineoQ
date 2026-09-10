---
name: risk-management
category: Financial Math & Risk
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/   # strategy.risk.* verified present in v6
  - https://www.tradingview.com/pine-script-docs/concepts/strategies/
---

# Risk Management

## Purpose
Risk per trade, drawdown control, risk of ruin, exposure, correlation risk,
daily loss limits — with verified v6 native tools.

## When to Use
- Any strategy build; before trusting any backtest; capital-preservation design.

## Core Knowledge

### Per-Trade Risk
- Risk$ = entry − stop distance × size; Risk% = Risk$ / equity.
- Design target: constant Risk% per trade (0.5–2% typical) → sizing in skill 31.
- Worst-case per trade must include gaps/slippage: effective stop worse than
  theoretical (broker emulator fills gaps at bar open, skill 09).

### Native Risk Guardrails (v6 — VERIFIED PRESENT)
- `strategy.risk.max_intraday_loss(value, type)` — halt when day's loss exceeds
  value; `type`: `strategy.percent_of_equity` / `strategy.cash`
  (reference also lists `strategy.fixed_loss_dollars` — verify exact accepted
  constants per symbol before relying).
- `strategy.risk.max_drawdown(value, type)` — halt at total DD threshold.
- `strategy.risk.max_intraday_filled_orders(count)` — order-count circuit breaker.
- `strategy.risk.max_cons_loss_days(count)` — consecutive losing days stop.
- `strategy.risk.max_position_size(count)` — absolute position cap (contracts).
- `strategy.risk.allow_entry_in(strategy.direction.long|short|all)`.
- Semantics: once a limit trips, it stops that day/session; CANNOT be undone
  intraday. These act in backtests too.

### Manual Daily Loss Limit (portable pattern)
```pine
var float dayStartEq = na
newDay = ta.change(time("D")) != 0
if newDay
    dayStartEq := strategy.equity
dayPnL = strategy.equity - dayStartEq
bool dailyStop = dayPnL <= -0.02 * strategy.initial_capital   // −2% of capital
if not dailyStop
    strategy.entry("L", strategy.long)   // gate ALL entries with `not dailyStop`
```

### Drawdown Accounting
- Equity high-water mark: `var float hwm = 0.0` → `hwm := math.max(hwm, strategy.equity)`;
  DD = 1 − strategy.equity / hwm.
- Native: `strategy.max_drawdown`, `strategy.max_drawdown_percent`
  (closed+open equity, tester definition).

### Risk of Ruin (conceptual → simulate)
- Analytic forms assume i.i.d. trades & fixed fraction — real trades cluster
  (skill 26). Practical estimate: Monte Carlo on trade history (skill 28),
  P(ruin) = fraction of paths breaching loss cap. Report with CIs (skill 25).

### Exposure & Correlation Risk
- Exposure = Σ\|position value\| / equity (with pyramiding >1 easily exceeds 100%).
- Correlated concurrent positions = one bet in disguise: cap correlated
  exposure jointly (e.g., BTC+ETH longs share one risk bucket, skill 15/57).
- v6 default margin 100% (no implicit leverage) — margin ≤100 simulates
  leverage and margin-call liquidations (skill 09).

## Common Mistakes
- Thinking strategy.risk.* was removed in v6 (it was NOT — verified; a popular
  false claim. Run skill 06 pipeline when in doubt).
- Ignoring gap risk in stop-distance math.
- Summing exposures of correlated positions as if diversified.
- No daily stop on strategies that trade continuously.

## Corrections & Updates
- [2026-09] Created. VERIFICATION EVENT: an earlier research pass claimed
  strategy.risk.* was removed in v6; direct reference check proved ALL six
  functions exist. Update any skill/assertion that repeats the removal claim.
