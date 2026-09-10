---
name: trade-management
category: Financial Math & Risk
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/strategies/
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Trade Management

## Purpose
Stops, targets, trailing, break-even, R:R, dynamic/structure exits.

## When to Use
- Every entry needs a planned exit family BEFORE firing.

## Core Knowledge

### strategy.exit Parameters (units matter — skill 09)
- `profit` / `loss` = distance in TICKS from entry price.
- `limit` / `stop` = ABSOLUTE prices.
- `trail_price` (trigger price) or `trail_points` (ticks) + `trail_offset`
  (ticks trail distance).
- `qty` / `qty_percent` for partial exits; `from_entry` ties to entry id.
- TP+SL on one exit = OCA bracket (one fills → other cancels).

### Stop Families
- Fixed price/tick stops — simple, regime-blind.
- ATR stop: `stop = entry − mult·ta.atr(len)` (volatility-normalized).
- Chandelier (trailing): `stop = ta.highest(high, len) − mult·ta.atr(len)` (long).
- Structure stop: below last confirmed swing low (`ta.pivotlow(low, l, r)`
  confirmed r bars later — lag acknowledged).
- Time stop: exit after N bars via `strategy.closedtrades.bars`/bar counters.

### Trailing Patterns
1. Native trailing: `strategy.exit(..., trail_points = X, trail_offset = Y)`.
2. Manual ratchet (full control):
```pine
var float trailStop = na
if strategy.position_size > 0
    float atr = ta.atr(14)
    trailStop := na(trailStop) ? close - 3 * atr :
         math.max(trailStop, close - 3 * atr)      // only moves UP (long)
    strategy.exit("X", "L", stop = trailStop)
```
- Update trailing on bar close for backtest-consistent behavior (skill 07).

### Break-Even Logic
```pine
if strategy.position_size > 0 and high >= strategy.position_avg_price + 1.5 * riskDist
    strategy.exit("X", "L", stop = strategy.position_avg_price + ticksBuffer)
```
- Move stop to BE + costs after 1–1.5R; be careful: naive BE stops increase
  scratch rate — measure effect (skill 32 MAE/MFE).

### R:R & Dynamic Exits
- Plan R multiples: initial risk defines unit; targets at 2R/3R or trail.
- Dynamic: partial at 1R (qty_percent = 50), remainder trailed by
  structure/ATR.
- Exit design responds to regime (skill 47): trend regimes trail wide; range
  regimes take quick fixed targets.

### Discipline
- Every strategy.exit variant must exist for ALL entry paths.
- Verify exit assumptions: gap fills at open (skill 09), intrabar path
  ambiguity (OCA tie ordering), and that stops aren't inside spread noise.

## Common Mistakes
- Mixing tick-distance and absolute-price params in one call.
- Trailing stops that also move AGAINST the trade (missing math.max/min ratchet).
- Break-even + tight trail = death by scratches.
- Structure stops using unconfirmed pivots (repaint, skill 12).

## Corrections & Updates
- [2026-09] Created; parameter semantics verified against strategies docs.
