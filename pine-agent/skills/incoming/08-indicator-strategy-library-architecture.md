---
name: indicator-strategy-library-architecture
category: TradingView Architecture
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/language/declaration-statements/
  - https://www.tradingview.com/pine-script-docs/concepts/strategies/
  - https://www.tradingview.com/pine-script-docs/concepts/libraries/
---

# Indicator / Strategy / Library Architecture

## Purpose
Choosing the right script type and configuring declaration parameters correctly.

## When to Use
- Starting any new script; converting between types; configuring limits/resources.

## Core Knowledge

### Script Types — Selection Matrix
| Need | Type |
|---|---|
| Visuals, oscillators, alerts, screener integration | `indicator()` |
| Backtesting, order simulation, strategy reports, fill alerts | `strategy()` |
| Reusable functions/UDTs/enums imported by other scripts | `library()` |

- Indicator: no `strategy.*`; cannot export functions; supports `alertcondition()`.
- Strategy: full `strategy.*`; NO `alertcondition()`; uses `alert()` + order-fill alerts.
- Library: exports functions/methods/UDTs/enums; NO `strategy.*`, NO `input.*()`,
  no direct chart alerts; version-pinned via import path.

### Key Declaration Parameters (const-only values)
```pine
//@version=6
indicator("Name", overlay = true, max_labels_count = 500)
strategy("Name", overlay = true, initial_capital = 10000,
     default_qty_type = strategy.percent_of_equity, default_qty_value = 10,
     commission_type = strategy.commission.percent, commission_value = 0.05,
     slippage = 2, pyramiding = 0, process_orders_on_close = false,
     calc_on_every_tick = false, margin_long = 100, margin_short = 100,
     use_bar_magnifier = false)   // premium feature
```
- overlay: true = chart pane; false = separate pane. scale.none (overlay only).
- format / precision: number display.
- Drawing caps: max_labels_count / max_lines_count / max_boxes_count (1–500,
  default 50); max_polylines_count (1–100, default 10).
- max_bars_back (0–5000): history buffer; usually leave automatic.
- timeframe / timeframe_gaps: indicator-only MTF at declaration level.

### Conversion Workflows
**Indicator → Strategy:**
- Swap declaration; configure capital/commission/slippage.
- Replace signal plots with strategy.entry/exit inside the same conditions.
- Keep plots for visual debugging (allowed alongside orders).

**Strategy → Indicator:**
- Swap declaration; DELETE all strategy.* calls (compile errors otherwise).
- Recreate trade markers with plotshape/bgcolor if needed.

## Common Mistakes
- Using series values in declaration parameters (must be const).
- Leaving initial_capital/commission at defaults and trusting backtest results.
- Setting calc_on_every_tick = true "to be realistic" — actually makes
  realtime deviate more from the historical backtest (different fill timing).
- Trying input.* inside a library.

## Corrections & Updates
- [2026-09] Created; verified against official declaration/strategies/libraries docs.
- [2026-09] Rewritten in archive: heading structure restored (was flattened).
