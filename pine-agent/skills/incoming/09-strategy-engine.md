
---
name: strategy-engine
category: TradingView Architecture
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/strategies/
  - https://www.tradingview.com/pine-script-docs/faq/strategies/
---

# Strategy Engine

## Purpose
Order mechanics, fills, pyramiding, sizing, commission/slippage/margin, and
the broker emulator's assumptions.

## When to Use
- Building/backtesting any strategy; interpreting strategy reports; debugging fills.

## Core Knowledge

### Order Placement Functions
- `strategy.entry(id, direction, qty, limit, stop, ...)` — main entry; REVERSES
  an opposite position; same-id re-entry = pyramiding addition (if allowed).
- `strategy.order(id, direction, ...)` — raw order; does NOT reverse
  (long + short order = netted position).
- `strategy.exit(id, from_entry, profit, loss, limit, stop, trail_price,
  trail_points, trail_offset, qty_percent, ...)` — bracket exits tied to entries.
- `strategy.close(id)` / `strategy.close_all()` / `strategy.cancel(id)`.

### OCA Groups (via `oca_name`)
- `strategy.oca.cancel` — filling one order cancels the others in group.
- `strategy.oca.reduce` — filling one reduces remaining qty proportionally.
- TP + SL on same entry = same OCA group behavior (classic bracket).

### Execution Timing (default)
- Signal on bar N → order placed → **filled at open of bar N+1**.
- `process_orders_on_close = true` → fills at close of bar N (faster but
  unrealistic assumption; treat with suspicion).
- `calc_on_every_tick = true` → realtime per-tick execution (deviates from backtest).
- v6: strategy no longer errors at the historic 9,000-order limit — it trims
  the oldest orders automatically.

### Broker Emulator Fill Assumptions (historical bars)
- No true intrabar path exists; emulator assumes bar path:
  Open → High → Low → Close if open is nearer to high, else
  Open → Low → High → Close.
- Gaps: no intrabars assumed inside gaps → stop/limit orders gapped over fill at
  the bar's OPEN price, not the trigger price.
- `use_bar_magnifier = true` (Premium+): uses LTF intrabar data for realistic fills.

### Position & Money Mechanics
- Sizing: `strategy.fixed` (contracts), `strategy.cash` (currency),
  `strategy.percent_of_equity` (% of equity); or explicit `qty`/`qty_percent`.
- Pyramiding: N = max same-direction concurrent entries; each entry tracked
  separately; `strategy.position_avg_price` = weighted average.
- Commission: `strategy.commission.percent` | `cash_per_contract` | `cash_per_order`.
- Slippage: in ticks, applied adversely to fills.
- Margin: `margin_long/short` % (100 = no leverage). Equity < margin requirement
  → margin call liquidation (`strategy.margin_calls` counter).

### Trade Introspection
- `strategy.position_size`, `strategy.position_avg_price`,
  `strategy.opentrades.*` (entry price, bars held, unrealized MAE/MFE per tranche),
  `strategy.closedtrades.*` (`entry_price`, `exit_price`, `profit`, `return`,
  `max_drawdown` = MAE, `max_runup` = MFE, `entry_bar_index`, `exit_bar_index`).

## Common Mistakes
- Believing backtest fills exactly (OHLC path assumption + gap fills at open).
- Forgetting entries only reverse via `strategy.entry`; `strategy.order` nets.
- TP/SL distances set in price units vs ticks confusion (`profit`/`loss` = TICKS;
  `limit`/`stop` = price).
- Ignoring commission/slippage → inflated metrics.

## Corrections & Updates
- [2026-09] Created; verified against official strategies docs.
