# Skill: analytical-geometry

## Metadata

```yaml
id: analytical-geometry
name: Analytical Geometry
version: 1.0.0
path: skills/normalized/quant/analytical-geometry/skill.md
layer: QUANT
domains: [mathematics, geometry]
triggers:
  english:
    - trendline math
    - line.get_price projection
    - intersection of two lines
    - slope per bar
    - chart.point
    - perpendicular distance
    - measured move projection
    - polyline curve
  persian:
    - هندسه تحلیلی
    - خط روند و شیب
    - تلاقی دو خط
    - پیش‌بینی خطی
    - فاصله عمودی از خط
dependencies:
  mandatory: []
  optional: [drawing-and-visualization, linear-algebra, fibonacci-and-harmonic, advanced-market-geometry]
status: normalized
priority: 2
```

## Purpose

Coordinates, distance, slope, angles, lines, intersections, and projections —
both as price-chart math and as drawing implementations (`chart.point`,
`line.get_price`, polyline). Required for trendlines/channels, S/R geometry,
pattern-angle questions, ray projections, and breakout projections.

## Triggers

Select for: trendline/channel construction or projection; support-resistance
geometry; "what angle is this trendline" questions; ray/level projections;
pattern symmetry/measured-move math; polyline curve construction.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Geometric requirement | description | formalization contract | yes |
| Anchor type (index vs time) | design fact | drawing plan | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Geometry formulas + Pine mapping | knowledge applied | Implementation |
| Anchor-consistency requirements | constraint notes | Implementation Planning |
| Angle-illusion warnings | verification checks | Pre-Verification |

## Rules

1. Chart coordinate systems: x = bar_index (or time), y = price;
   `chart.point.new(index, time, price)`, `chart.point.from_index(i, price)`,
   `chart.point.from_time(t, price)`, `chart.point.now(price)`,
   `chart.point.copy(p)`; mixing index/time anchors in one drawing = error —
   keep consistent.
2. Lines: `line.new(p1, p2, xloc, extend, ...)`; `line.get_price(ln, x)`
   extrapolates the line's price at ANY bar x including outside [x1, x2] —
   the core projection tool; slope (price per bar) = `(y2 - y1) / (x2 - x1)`
   with x in bar_index; bar spacing is TIME-uneven across sessions —
   time-anchored lines have non-constant price/bar slopes.
3. Angle caveat: chart pixel scaling makes visual angles meaningless — define
   angles via price-per-bar or normalized units, never screen degrees.
4. Distance & measures: vertical distance = price difference (or ATR/R
   multiples); Euclidean on (bar, price) mixes units — only meaningful after
   normalization (e.g., x in ATR-scaled bars); perpendicular distance of point
   P to line through A with direction d: `dist = |(P−A) × d| / |d|`
   (2D cross product).
5. Intersections & projections: two lines — solve `a1·x + b1 = a2·x + b2`
   (slopes/intercepts from two points); horizontal ray via `extend.right`;
   projection target `line.get_price(trendLn, bar_index + n)`; confluence =
   min distance between levels < tolerance (in ATR or %).
6. Pattern geometry: parallel channel — offset endpoints by constant Δprice,
   verify with `line.get_price` equality of Δ at both anchors; measured moves
   — project first-leg height from the breakout point; symmetry — midpoint
   `(A + B) / 2` per axis; reflection tests for AB=CD-style patterns (see
   fibonacci-and-harmonic).
7. Polyline: `polyline.new(array<chart.point>, curved, closed, ...)` — up to
   10,000 vertices; max 100 polylines (see drawing-and-visualization); build
   curves (circles, arcs, regression envelopes) as point arrays.

## Workflow

1. Choose the anchor system (index vs time) and keep it consistent (rule 1).
2. Express the geometry with slopes/intercepts or `line.get_price` (rule 2).
3. Normalize any distance/angle metric (rules 3–4) — never screen degrees.
4. Implement projections/intersections (rule 5) and pattern math (rule 6).
5. For curves, budget polylines/vertices per rule 7 and drawing-and-visualization
   limits.

## Constraints

- Anchor mixing is an error (rule 1).
- Visual angles are meaningless on scaled charts (rule 3).
- Polyline caps: 100 objects, 10,000 vertices each (rule 7).

## Assumptions

- `chart.point`/`line`/`polyline` APIs per v6 reference as claimed by the
  source.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| "Angle = 30°" reasoning | screen-degree illusion | rule 3: price-per-bar units |
| Mixed anchors | runtime error | rule 1: consistent xloc |
| Slope constant across session gap | wrong projections | rule 2: time-uneven spacing |
| Projection on noise-fit line | absurd targets | rule 2: extrapolation caveat |

## Dependencies

Optional: drawing-and-visualization (drawing objects/limits), linear-algebra
(transforms), fibonacci-and-harmonic (pattern reflection tests),
advanced-market-geometry (geometry depth). Load only on their own triggers.

## Examples

- "Project my trendline 20 bars ahead" → rule 2/5 `line.get_price`.
- "Is price close to both the channel and the 0.618 level?" → rule 5 confluence
  with ATR tolerance.
- Persian: «زاویه خط روندم چقدره؟» → rule 3: define via price-per-bar.

## Verification Criteria

- One anchor system per drawing; no mixed xloc.
- Angles/distances expressed in normalized units only.
- Projections use `line.get_price` with fit-quality caveats where relevant.
- Polyline/vertex counts within caps.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-002` import from `skills/incoming/19-analytical-geometry.md`.
- Structural reorganization only; no semantic changes. Cross-references to
  skills 10/42/43 became optional dependencies (10 already registered;
  42/43 pending with deterministic ids).

## Source Reference

- Original filename: `19-analytical-geometry.md`
- Original source path: `skills/incoming/19-analytical-geometry.md`
- Import batch: `batch-002`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-002)
