---
name: analytical-geometry
category: Mathematics
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/visuals/lines-and-boxes/
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Analytical Geometry

## Purpose
Coordinates, distance, slope, angles, lines, intersections, projections —
both as price-chart math and as drawing implementations.

## When to Use
- Trendlines/channels, support-resistance geometry, pattern angle measurement,
  ray projections, breakout projections.

## Core Knowledge

### Chart Coordinate Systems
- Two axes systems: bar_index (or time) on x, price on y.
- `chart.point`: `chart.point.new(index, time, price)`,
  `chart.point.from_index(i, price)`, `chart.point.from_time(t, price)`,
  `chart.point.now(price)`, `chart.point.copy(p)`.
- Mixing index/time anchors in one drawing = error — keep consistent.

### Lines
- `line.new(p1, p2, xloc, extend, ...)`.
- `line.get_price(ln, x)` — extrapolates the line's price at ANY bar x,
  including outside [x1, x2]. Core projection tool.
- Slope (price per bar): `(y2 - y1) / (x2 - x1)` — with x in bar_index.
  Note: bar spacing is TIME-uneven across sessions; time-anchored lines have
  non-constant price/bar slopes.
- Angle caveat: chart pixel scaling makes visual angles meaningless — define
  angles via price-per-bar or normalized units, never screen degrees.

### Distance & Measures
- Vertical distance = price difference (or ATR/R multiples).
- Euclidean on (bar, price) mixes units — only meaningful after normalization
  (e.g., x in ATR-scaled bars).
- Perpendicular distance of point P to line through A with direction d:
  `dist = |(P−A) × d| / |d|` (2D cross product).

### Intersections & Projections
- Two lines: solve `a1·x + b1 = a2·x + b2` (slopes/intercepts from two points).
- Horizontal ray from a level: `extend = extend.right`.
- Projection target: `line.get_price(trendLn, bar_index + n)`.
- Confluence: min distance between levels < tolerance (in ATR or %).

### Pattern Geometry (price structures)
- Parallel channel: offset a line's endpoints by constant Δprice; verify with
  `line.get_price` equality of Δ at both anchors.
- Measured moves: project first-leg height from breakout point.
- Symmetry: midpoint = `(A + B) / 2` per axis; reflection tests for AB=CD-style
  patterns (skill 42).

### Polyline
- `polyline.new(array<chart.point>, curved, closed, ...)` — up to 10,000
  vertices; max 100 polylines (skill 10). Build curves (circles, arcs,
  regression envelopes) as point arrays.

## Common Mistakes
- Interpreting on-screen angle of trendline (scale-dependent illusion).
- Mixing `xloc.bar_index` and `xloc.bar_time` anchors in one drawing.
- Assuming constant price/bar slope across session gaps.
- Forgetting line.get_price extrapolates — great for rays, dangerous if the
  line was fitted to noise.

## Corrections & Updates
- [2026-09] Created; verified against v6 reference (chart.point/line/polyline APIs).
