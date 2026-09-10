---
name: tradingview-execution-model
category: TradingView Architecture
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/language/execution-model/
  - https://www.tradingview.com/pine-script-docs/concepts/bar-states/
---

# TradingView Execution Model

## Purpose
Exact runtime semantics: historical vs realtime execution, rollback, commit,
state persistence, bar confirmation.

## When to Use
- Explaining why realtime behavior differs from history.
- Designing repaint-safe logic; using barstate correctly.
- Any code involving var/varip, alerts at bar close, or intrabar logic.

## Core Knowledge

### Execution Layers
1. **Historical bars**: script runs ONCE per bar, left → right. OHLCV fixed.
   State committed at each bar's end.
2. **Realtime bar (rightmost)**: script runs ONCE PER TICK (every price/volume
   update). `high/low/close` are FLUID; `open` fixed.
3. **Commit**: only the FINAL tick of a realtime bar is committed to history.

### Rollback (critical)
- Before EVERY realtime-tick recalculation, all series and `var` variables roll
  back to their state as committed at the PREVIOUS bar close.
- Consequence: intra-bar increments via `var` vanish each tick; only the final
  tick's state is committed.
- **`varip` escapes rollback** — retains updates across ticks within the bar.
  Trade-off: tick-level state is NOT reproducible on historical bars →
  historical/realtime discrepancy (a repainting source, see skill 12).

### Bar State Built-ins
| Variable | Semantics |
|---|---|
| `barstate.ishistory` | true on historical bars only |
| `barstate.isrealtime` | true on realtime bar updates |
| `barstate.isconfirmed` | true on historical bars AND the closing tick of a realtime bar. **The repaint guard.** Does NOT work inside `request.security()`. |
| `barstate.isnew` | true on historical bars and first tick of realtime bar (reset points) |
| `barstate.islast` | true on the rightmost bar (efficient last-bar-only drawing) |
| `barstate.islastconfirmedhistory` | last historical bar when market closed / bar before realtime bar when open |

### Historical vs Realtime Discrepancies (sources of "difference")
- Fluid `high/low/close` during realtime → indicators fluctuate intrabar.
- `timenow`, `request.security` unconfirmed values change after reload.
- `varip` state, order fills with `calc_on_every_tick`, deleted drawings.

### Strategy Fill Timing (see skill 09 for depth)
- Default: strategy executes at bar close; orders placed on bar N fill at
  open of bar N+1.
- Realtime: no per-tick execution unless `calc_on_every_tick = true`;
  order-fill alerts fire immediately regardless.

## Common Mistakes
- Gating logic with `barstate.isnew` expecting it false on historical bars
  (it is TRUE on all historical bars).
- Trying `barstate.isconfirmed` inside `request.security` (unsupported).
- Accumulating tick state with `var` and wondering why it "disappears"
  (rollback) — use `varip` only if intrabar state is truly required.
- Comparing a realtime screenshot with historical values and concluding a bug.

## Corrections & Updates
- [2026-09] Created; verified against official execution model & bar states docs.
