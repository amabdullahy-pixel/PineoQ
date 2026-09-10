---
name: backtesting-science
category: Backtesting & Optimization
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/support/solutions/43000669285-what-is-bar-magnifier-backtesting-mode/
  - https://www.tradingview.com/support/solutions/43000666265-how-deep-backtesting-works/
  - https://www.tradingview.com/pine-script-docs/writing/limitations/
---

# Backtesting Science

## Purpose
Bias taxonomy and execution assumptions that make or break backtest validity.

## When to Use
- EVERY backtest interpretation; before trusting ANY strategy report.

## Core Knowledge

### Bias Taxonomy
1. **Lookahead bias** — future data leaking in (skill 12 patterns: unconfirmed
   HTF, lookahead_on without [1], plotting into past).
2. **Survivorship bias** — backtesting only symbols that "made it". TradingView
   backtests run on ONE symbol's current data feed; delisted-history handling
   is not exposed — treat single-symbol results as conditionally valid.
3. **Selection bias** — cherry-picking the symbol/timeframe/period that worked.
4. **Data-mining bias** — testing many variants, keeping the best (K-trials
   inflation, skill 25/54).
5. **Execution-assumption bias** — fill mechanics below.

### Execution Assumptions (verified defaults)
- No Bar Magnifier: OHLC path heuristic — Open→High→Low→Close (or O→L→H→C,
  closer extreme first). Orders gapped over fill at bar OPEN, not trigger price.
- `use_bar_magnifier = true` (Premium+): broker emulator checks LTF intrabar
  data for trigger breaches. Budget: ≤200,000 LTF bars; on long charts the
  EARLIEST bars lose magnifier coverage beyond
  `last_bar_index − (200000 / LTFbarsPerChartBar)`.
- Slippage = fixed adverse ticks (`slippage` param); commission: percent /
  cash_per_contract / cash_per_order. Spread NOT modeled natively — widen
  slippage or add commission to approximate.
- v6: 9,000-order historic cap → oldest orders TRIMMED silently (skill 09).
- Deep Backtesting (Premium+): up to ~2M bars / 1M trades; results in report
  only (not drawn on chart).
- Realtime: strategies execute at bar close unless calc_on_every_tick —
  backtest ≠ realtime by default (skill 07).

### Backtest Validation Gate (minimum bar to clear)
- [ ] Commission + slippage configured realistically.
- [ ] ≥ 100 closed trades (CIs, skill 25).
- [ ] Repaint audit clean (skill 12 checklist).
- [ ] OOS segment tested (skill 53).
- [ ] Robustness checks (skill 54).
- [ ] Expectancy > 2× costs per trade.

## Common Mistakes
- Reading Net Profit without costs/N/period context.
- process_orders_on_close=true inflating realism (same-bar close fills).
- Ignoring gap-fill-at-open behavior for stop-based systems.
- Comparing backtests across symbols without cost normalization.

## Corrections & Updates
- [2026-09] Created; Bar Magnifier/Deep Backtesting parameters verified vs
  support articles.
