---
name: advanced-market-geometry
category: Market Structure & Geometry
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/visuals/lines-and-boxes/
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Advanced Market Geometry

## Purpose
Channels, trendline geometry, symmetry, projections, Gann and angle-based
analysis — Pine implementation patterns. (Elliott Wave & Gann live HERE, not
as separate schools.)

## When to Use
- Dynamic S/R lines, channel systems, time-price projections, geometric confluence.

## Core Knowledge

### Channels
- Regression channel: mid = `ta.linreg(src, len, 0)`; bands = mid ± k·stdev of
  residuals (skill 24); draw with line.new + line.get_price for boundary tests.
- Parallel (equidistant) channel: two anchors of a trendline + offset by the
  extreme between them; validity: 2+ touches per side.
- Donchian/KC/BB = statistical channels (skill 37); geometric channels are
  anchor-based (pivots) — different families, don't mix blindly.

### Trendline Geometry
- Construction: connect two confirmed pivots; validation = subsequent pivot
  tests without close-through breaks.
- Break test: `close > line.get_price(tl, bar_index)` (bull line broken).
- Slope discipline: price-per-bar units (skill 19); time-anchored lines have
  non-constant slopes across sessions — prefer bar_index anchors for math.

### Symmetry & Projections
- AB=CD: \|CD\| = \|AB\| (± tolerance) — completion projects D from C.
- Measured move: next leg ≈ first leg; flag/pole: pole height projected from
  breakout.
- Midpoint/reflection: mid = (A+B)/2; symmetry breaks = structure shifts.

### Gann (kept here by design)
- 1×1 = one price unit per bar — SCALE-DEPENDENT (define the unit explicitly,
  e.g., 1×1 = 1·ATR(50) per bar, then fan = multiples: 2×1, 1×1, 1×2...):
```pine
unit = ta.atr(50)
g1x1 = anchorPrice - unit * (bar_index - anchorBar)   // descending fan example
```
- Fan lines via line.new from a pivot with slopes = m·unit per bar
  (m ∈ {4, 2, 1, 0.5, 0.25} family).
- Square-of-9 style ideas (sqrt price steps): `p_next = math.pow(math.sqrt(p) + step, 2)`
  — heuristic tools; treat as hypothesis generators (skill 63), not laws.
- Angle-based "45°" claims are meaningless in raw pixels — always normalize.

### Elliott Wave (kept here by design)
- No built-in wave counting. Practical Pine: wave segmentation from confirmed
  pivots (ZigZag-style arrays of swing points), rule checks as filters (e.g.,
  W2 doesn't retrace beyond W1 start; W3 not shortest) — used as probabilistic
  context, never as deterministic counting.
- Fibonacci coupling: targets at 1.618×W1 for W3, 0.618 retrace for W2 (skill 42).

## Common Mistakes
- Fitting trendlines to noise then trading every touch (validate pivot count).
- Gann angles in degrees/pixels instead of normalized price-per-bar units.
- Wave counts redrawn every bar (unfalsifiable — define segmentation rules, skill 66).
- Extrapolating lines far beyond fit range (500-bar future cap, skill 10).

## Corrections & Updates
- [2026-09] Created; line.get_price/no-built-ins verified; Gann normalization
  approach documented — inject your canonical unit choice below.
