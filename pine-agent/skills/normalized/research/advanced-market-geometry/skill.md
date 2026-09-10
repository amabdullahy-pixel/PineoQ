# Skill: advanced-market-geometry

## Metadata

```yaml
id: advanced-market-geometry
name: Advanced Market Geometry
version: 1.0.0
path: skills/normalized/research/advanced-market-geometry/skill.md
layer: RESEARCH
domains: [market-structure, geometry]
triggers:
  english:
    - regression channel
    - parallel channel construction
    - trendline break test
    - Gann fan normalized
    - square of nine
    - Elliott wave segmentation
    - measured move flag pole
  persian:
    - هندسه پیشرفته بازار
    - کانال‌ها و خط روند
    - گان و زاویه‌ها
    - امواج الیوت
dependencies:
  mandatory: []
  optional: [analytical-geometry, regression-correlation, fibonacci-and-harmonic, falsification-and-counterexamples]
status: normalized
priority: 2
```

## Purpose

Channels, trendline geometry, symmetry, projections, and Gann/angle-based
analysis — Pine implementation patterns. Elliott Wave and Gann live HERE by
design (not separate schools).

## Triggers

Select for: dynamic S/R lines; channel systems (regression/parallel);
trendline break tests; time-price projections; Gann fans/square-of-9
heuristic tools; Elliott-style wave segmentation as probabilistic context.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Geometry requirement | description | formalization contract | yes |
| Gann unit definition / wave segmentation rules | parameters | user/formalization | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Channel/trendline implementation | code patterns | Implementation |
| Normalized Gann/wave design | implementation pattern | Implementation |
| Unfalsifiability warnings | warnings | Pre-Verification |

## Rules

1. Channels: regression channel — mid = `ta.linreg(src, len, 0)`, bands = mid
   ± k·stdev(residuals) (see regression-correlation), drawn via line.new +
   line.get_price for boundary tests; parallel (equidistant) channel — two
   anchors of a trendline offset by the extreme between them, validity = 2+
   touches per side; Donchian/KC/BB are STATISTICAL channels (see
   volatility-indicators) — geometric channels are anchor-based (pivots);
   different families, don't mix blindly.
2. Trendline geometry: connect two confirmed pivots; validation = subsequent
   pivot tests without close-through breaks; break test = `close >
   line.get_price(tl, bar_index)` for bull lines; slope discipline —
   price-per-bar units (see analytical-geometry); time-anchored lines have
   non-constant slopes across sessions — prefer bar_index anchors for math.
3. Symmetry & projections: AB=CD |CD| = |AB| ± tolerance — completion
   projects D from C; measured move — next leg ≈ first leg; flag/pole — pole
   height projected from breakout; midpoint/reflection mid = (A+B)/2;
   symmetry breaks = structure shifts.
4. Gann (normalized): 1×1 = one price unit per bar — SCALE-DEPENDENT: define
   the unit explicitly (e.g., 1×1 = 1·ATR(50) per bar), fan = multiples
   (2×1, 1×1, 1×2…, m ∈ {4, 2, 1, 0.5, 0.25}); fan lines via line.new from a
   pivot with slopes = m·unit per bar; square-of-9-style sqrt price steps
   (`p_next = (sqrt(p) + step)²`) are HEURISTIC hypothesis generators (see
   hypothesis-and-formula-engineering), not laws; angle-based "45°" claims
   are meaningless in raw pixels — always normalize.
5. Elliott Wave (probabilistic only): no built-in wave counting; practical
   Pine = wave segmentation from confirmed pivots (ZigZag-style swing arrays)
   with rule checks as filters (W2 doesn't retrace beyond W1 start; W3 not
   shortest) — used as probabilistic context, NEVER deterministic counting;
   Fibonacci coupling (1.618×W1 for W3, 0.618 retrace for W2 — see
   fibonacci-and-harmonic); wave counts redrawn every bar are unfalsifiable —
   define segmentation rules (see falsification-and-counterexamples).

## Workflow

1. Choose channel family by need (regression vs parallel vs statistical —
   rule 1); never mix families blindly.
2. Build trendlines from confirmed pivots with validation/break tests
   (rule 2).
3. For Gann, declare the unit and construct the normalized fan (rule 4).
4. For Elliott-style work, fix segmentation rules first and use output as
   probabilistic context (rule 5).

## Constraints

- No degree/pixel angle claims; Gann units must be explicit.
- No deterministic wave counting; no trendlines fitted to noise (validate
  pivot count).
- Line extrapolation respects the 500-bar future cap (see
  drawing-and-visualization).

## Assumptions

- line.get_price / no-built-ins facts verified against the v6 reference by
  the source (consistent with analytical-geometry).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Trading every touch of a noise-fit line | no validation | rule 2: pivot-count validation |
| Gann angles in degrees | pixel illusion | rule 4: normalized units |
| Wave counts redrawn every bar | unfalsifiable | rule 5: fixed segmentation rules |
| Extrapolation beyond fit range | absurd projections | constraint: 500-bar cap |

## Dependencies

Optional: analytical-geometry (line math), regression-correlation
(regression channel stats), fibonacci-and-harmonic (fib coupling),
falsification-and-counterexamples (rule falsification). Load only on their
own triggers.

## Examples

- "Dynamic channel S/R with break alerts" → rules 1–2.
- "Normalized Gann fan on crypto" → rule 4 with ATR unit.
- Persian: «زاویه ۴۵ درجه گان معنی داره؟» → rule 4: normalize first.

## Verification Criteria

- Channel family documented; trendlines pivot-validated.
- Gann unit explicit; fan slopes in price-per-bar.
- Wave segmentation rules fixed before use; output labeled probabilistic.
- Drawing/extrapolation within platform caps.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-005` import from `skills/incoming/43-advanced-market-geometry.md`.
- Resolves the batch-002/003 pending pointer from analytical-geometry.
- Source explicitly designates itself as the home for Elliott/Gann ("kept
  here by design") — recorded to prevent future duplicate-skill drift.
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `43-advanced-market-geometry.md`
- Original source path: `skills/incoming/43-advanced-market-geometry.md`
- Import batch: `batch-005`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-005)
