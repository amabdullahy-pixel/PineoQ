# Skill: fibonacci-and-harmonic

## Metadata

```yaml
id: fibonacci-and-harmonic
name: Fibonacci & Harmonic
version: 1.0.0
path: skills/normalized/research/fibonacci-and-harmonic/skill.md
layer: RESEARCH
domains: [market-structure, geometry]
triggers:
  english:
    - fib retracement extension
    - golden pocket confluence
    - harmonic XABCD
    - Gartley Bat Butterfly Crab
    - PRZ potential reversal zone
    - measured move projection
  persian:
    - فیبوناچی
    - الگوهای هارمونیک
    - ناحیه بازگشت احتمالی
    - هم‌پوشانی سطوح
dependencies:
  mandatory: []
  optional: [analytical-geometry, market-structure, signal-fusion, drawing-and-visualization]
status: normalized
priority: 2
```

## Purpose

Fib retracements/extensions/projections, confluence zone stacking, and
harmonic XABCD patterns — manual Pine implementations (NO built-ins exist for
Fibonacci, harmonic, Elliott, or Gann).

## Triggers

Select for: level-based targets/entries; pattern completion zones (PRZ);
confluence scoring; golden-pocket logic; harmonic detection design.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Level/pattern requirement | description | formalization contract | yes |
| Ratio table school (±tolerance) | parameters | user/formalization | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Level/projection implementation | knowledge applied | Implementation |
| Harmonic detector design | implementation pattern | Implementation |
| Confluence scoring rules | design output | signal-fusion |

## Rules

1. No built-ins (verified): no `ta.*` functions for Fibonacci, harmonic,
   Elliott, or Gann — chart tools only; all programmatic implementations are
   manual (pivots + arrays + line/label drawing).
2. Fibonacci levels: constants `math.phi` (1.618…), `math.rphi` (0.618…)
   (consistent with mathematical-foundation's verified inventory); from swing
   span — retracements `high − span·R` for R ∈ {0.236, 0.382, 0.5, 0.618,
   0.786}; extensions from low `low + span·E` for E ∈ {1.272, 1.618, 2.0,
   2.618}; projections (measured move from next swing) anchor + priorLeg·ratio;
   swing anchors from `ta.pivothigh/pivotlow` stored in UDT {price, barIndex};
   CURRENT active swing = last confirmed pivot pair (lag = rightBars — see
   repainting-and-lookahead).
3. Confluence (zone stacking): confluence zone = multiple INDEPENDENT level
   families within tolerance (e.g., 0.3·ATR) — fib 0.618 + prior S/R + VWAP
   band + round number; score = count of DISTINCT families (cap weights —
   see signal-fusion); overlapping fib levels of the SAME swing ≠ confluence.
4. Harmonic patterns (accepted ratio table, from StockCharts ChartSchool):
   Gartley B 0.618 / C 0.386–0.886 / D 0.786 XA; Bat B 0.382–0.50 (<0.618) /
   C 0.382–0.886 / D 0.886 XA; Butterfly B 0.786 / C 0.382–0.886 / D
   1.272–1.618 XA; Crab B 0.382–0.618 / C 0.386–0.886 / D 1.618 XA.
   Detection sketch: pivots → X,A,B,C,D candidates → ratio tests with
   tolerance (±5–10% per school) → D = potential reversal zone (PRZ); trade
   on reaction AT the zone, never on the projection alone; alt-leg checks
   (AB=CD symmetry; BC extension 1.13–3.618 for D projection) per school —
   DECLARE your table in the skill manifest.
5. Drawing discipline: pivot-anchored level maps must not redraw from
   unconfirmed swings (repaints the whole map); label/line sets respect
   drawing caps (see drawing-and-visualization).

## Workflow

1. Build confirmed-pivot swing storage (rule 2) — never auto-retrace from
   unconfirmed swings.
2. Compute retracement/extension/projected levels from the active swing.
3. Detect harmonics with declared tolerance tables (rule 4); mark PRZ.
4. Stack confluence by distinct families (rule 3); feed scores to
   signal-fusion.

## Constraints

- Zero-tolerance harmonic matching is forbidden (real data never matches
  exactly).
- Same-family level stacking does not count as confluence.

## Assumptions

- Ratio table is community convention (StockCharts ChartSchool provenance) —
  per-school variation handled by declared tolerance tables.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Levels redraw on refresh | unconfirmed swings | rule 2/5: confirmed anchors |
| Harmonic never matches | zero tolerance | rule 4: ±5–10% tolerance |
| Fake confluence | same-family stacking | rule 3: distinct families |
| Drawing limit hit | missing labels | rule 5: caps |

## Dependencies

Optional: analytical-geometry (projection math/drawing),
market-structure (swing anchors), signal-fusion (confluence scoring),
drawing-and-visualization (rendering caps). Load only on their own triggers.

## Examples

- "Mark the golden pocket of the last swing" → rule 2 retracements 0.618–0.65.
- "Detect a Gartley completion" → rule 4 ratio tests → PRZ.
- Persian: «سطوح فیبوی خودکار می‌پرند» → rule 2: confirmed swing anchors.

## Verification Criteria

- All levels derived from confirmed pivot pairs.
- Harmonic tolerance tables declared; PRZ traded on reaction only.
- Confluence counted by distinct families.
- Drawing counts within caps.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-005` import from `skills/incoming/42-fibonacci-and-harmonic.md`.
- The no-built-ins negative claim is consistent with the sibling geometry
  skill (43) and the established verify-before-use convention. Resolves
  batch-002 pending pointers from analytical-geometry. Structural
  reorganization only; no semantic changes.

## Source Reference

- Original filename: `42-fibonacci-and-harmonic.md`
- Original source path: `skills/incoming/42-fibonacci-and-harmonic.md`
- Import batch: `batch-005`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-005)
