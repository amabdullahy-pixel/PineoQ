---
name: liquidity-and-price-structure
category: Market Structure & Geometry
version: 1.0.0
last_updated: 2026-09
confidence: medium
sources:
  - https://tradethepool.com/technical-skill/smart-money-concepts-terminology/
  - https://www.zeiierman.com/blog/liquidity-sweeps-with-fair-value-gaps/
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Liquidity & Price Structure

## Purpose
Liquidity pools, sweeps/stop runs, FVG, order blocks, imbalances — definitions
plus Pine detection patterns. NOTE: SMC concepts lack a single canonical
specification — treat thresholds as parameters to falsify (skill 66).

## When to Use
- Liquidity-aware entries, stop placement, SMC systems.

## Core Knowledge

### Liquidity Pools & Sweeps
- Buy-side liquidity (BSL) = stop clusters ABOVE highs; sell-side (SSL) below lows.
- Equal highs/lows (EQH/EQL) = flat levels = dense liquidity magnets.
- Sweep (stop run) = wick through level + close back inside:
```pine
bool sweepSSL = low  < ta.lowest(low, 20)[1]  and close > ta.lowest(low, 20)[1]
bool sweepBSL = high > ta.highest(high, 20)[1] and close < ta.highest(high, 20)[1]
```
- EQH detection: \|high[i] − high[j]\| ≤ tol for two pivots (tol in ATR units,
  e.g., 0.1–0.25·ATR) with min bar separation.

### Fair Value Gap (3-candle standard)
- Bullish FVG: `low[0] > high[2]` → gap zone = [high[2], low[0]] (middle
  candle = displacement body). Bearish FVG mirrored: `high[0] < low[2]`.
- Consequent Encroachment (CE) = 50% of the gap (entry/target reference).
- Inverse FVG (iFVG): a filled/broken FVG flips role (broken bull FVG → resistance).
- Mitigation: zone "used" when price trades fully through it; track with a UDT
  array {top, bottom, dir, state} (skill 03) and delete/mark mitigated zones.

### Order Blocks & Displacement
- Bullish OB = last DOWN candle before an up displacement that breaks
  structure; zone = that candle's open–low (or high–low variants per school —
  parameterize).
- Displacement filter (validates OB/FVG):
```pine
avgBody = ta.sma(math.abs(close - open), 20)
bool displacement = math.abs(close - open) > 1.5 * avgBody
     and (close - low) / math.max(ta.tr(true), syminfo.mintick) > 0.6
```
- Breaker block = failed OB that price broke through → opposite role on retest.

### Engineering Notes
- Store zones as UDT arrays; cap counts (skill 10 limits); merge overlapping
  zones by tolerance; render with box.new; evaluate mitigations on CLOSE basis.
- Sweep+FVG+OB confluence scoring → skill 46 (not additive-blind).

## Common Mistakes
- Hard-coding school-specific variants (open-low vs wick OB) without declaring.
- Unmitigated zone arrays growing unbounded (memory/timeouts).
- Treating every gap as FVG (require displacement context).
- Live-bar zone detection without confirmation (repaint).

## Corrections & Updates
- [2026-09] Created; confidence=medium intentionally: SMC definitions vary by
  school; all thresholds flagged as tunable. Inject your preferred canonical
  rules in the Updates section below.
