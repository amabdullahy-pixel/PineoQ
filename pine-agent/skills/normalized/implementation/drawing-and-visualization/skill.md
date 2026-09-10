# Skill: drawing-and-visualization

## Metadata

```yaml
id: drawing-and-visualization
name: Drawing & Visualization
version: 1.0.0
path: skills/normalized/implementation/drawing-and-visualization/skill.md
layer: IMPLEMENTATION
domains: [visualization, performance]
triggers:
  english:
    - plot vs label
    - drawing objects
    - table dashboard
    - plot counts limit
    - max_labels_count overflow
    - polyline
    - xloc.bar_time
    - drawing garbage collected
    - table.cell slow
  persian:
    - رسم و نمایش
    - جدول داشبورد
    - محدودیت تعداد پلات
    - لیبل و خط و باکس
dependencies:
  mandatory: []
  optional: [indicator-strategy-library-architecture, pine-performance-engineering, documentation-verification]
status: normalized
priority: 2
```

## Purpose

Plots vs managed drawing objects, coordinate systems, plot-count and drawing
limits, and the performance-critical dashboard pattern. Required for any visual
output (plots, labels, zones, tables, dashboards) and for diagnosing
"my drawings disappear" / "my table lags" failures.

## Triggers

Select for: any visual output design; choosing plot-based vs object drawings;
drawing-count overflow or garbage collection surprises; table/dashboard
performance; coordinate/anchor questions (bar index vs bar time, future bars).

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Visual requirement | description | user request | yes |
| Expected drawing density (objects per bar) | estimate | formalization contract | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Plot vs object decision + limits | design decision | Implementation Planning |
| Dashboard pattern | implementation pattern | Implementation |
| Plot-count/drawing budget | constraint notes | Feasibility, Post-Verification |

## Rules

1. Two visualization families: (a) plot-based — `plot`, `plotshape`,
   `plotchar`, `plotarrow`, `plotcandle`, `plotbar`, `bgcolor`, `barcolor`,
   `fill`, `hline` (fixed series per bar, no per-object management);
   (b) object drawings — `label.new`, `line.new`, `box.new`, `polyline.new`,
   `table.new` (managed instances with `set_*`/`get_*`/`delete`).
2. Scope: global-only — `plot`, `hline`, `fill`, `bgcolor`, `barcolor`;
   local-allowed — `plotshape`, `plotchar`, `plotarrow`, `plotbar`,
   `plotcandle` (const-string params in local scope) and ALL object drawings.
   Verify exact per-version scope rules via documentation-verification when in
   doubt.
3. Limits: 64 plot counts max — each `plot*`/`bgcolor`/`barcolor`/`fill`
   (series color)/`alertcondition` call consumes counts (a dynamic `plotcandle`
   can use 7). Drawings: labels/lines/boxes default 50 → max 500 each via
   `max_*_count`; polylines max 100; tables max 9 (one per anchor position).
4. Drawing overflow → oldest drawing auto-deleted; setting coords to `na`
   still burns an ID — prefer conditional creation via `if`.
5. Coordinates: `xloc.bar_index` (default) — indices ≥ `bar_index - 10000`
   lookback, ≤ 500 bars into the future; `xloc.bar_time` — UNIX ms of bar
   open, for beyond-10k-bar history or MTF anchors; `yloc.price` (default) /
   `yloc.abovebar` / `yloc.belowbar` (y ignored); `extend.*` and style
   constants; `polyline.new(array<chart.point>, ...)` connects vertices.
6. Dashboard pattern (performance-critical): declare the table with `var`
   ONCE; populate cells ONLY under `if barstate.islast`; update via
   `table.cell()` (overwrites in place, no leak).

## Workflow

1. Classify the visual need: fixed per-bar series → plot family; discrete
   managed objects → drawing family (rule 1).
2. Check scope legality of the chosen call (rule 2) before planning code.
3. Budget plot counts and drawing caps (rules 3–4) into the design.
4. Select coordinate system (rule 5) based on lookback/MTF anchoring needs.
5. For dashboards, apply rule 6 exactly; feed the plot/drawing budget into
   Post-Verification checks.

## Constraints

- Plot-count (64) and drawing caps (500/500/500/100/9) are hard platform
  limits as documented by the source.
- `xloc.bar_index` drawing lookback limited to ~10,000 bars back.

## Assumptions

- Scope and limit behavior per official visuals & limitations docs as claimed
  by the source.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Table updates on every bar → lag | visible slowdown | rule 6: `barstate.islast` gating |
| Drawings vanish on old bars | overflow GC | rule 3/4: raise caps or conditional creation |
| Plot-count compile error | > 64 counts | consolidate plot calls |
| Drawing at bar_index − 15000 fails | lookback limit | switch to `xloc.bar_time` |

## Dependencies

Optional: indicator-strategy-library-architecture (declaration cap parameters),
pine-performance-engineering (runtime budgets), documentation-verification
(per-version scope verification). Load only on their own triggers.

## Examples

- "Show a live stats panel" → rule 6 dashboard pattern.
- "My 400 labels disappear one by one" → rule 4 overflow semantics; raise
  `max_labels_count` or gate creation.
- Persian: «داشبورد من چارت را کند کرده» → rule 6: per-bar table.cell calls.

## Verification Criteria

- Plot-family calls appear only in global scope; local plotting limited to
  rule-2-allowed calls.
- Table population gated by `barstate.islast` with `var`-declared table.
- Planned plot counts ≤ 64; drawing caps declared when density requires.
- No per-bar unconditional drawing creation without a cap strategy.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-001` import from `skills/incoming/10-drawing-and-visualization.md`.
- The source's own Corrections section states it was previously rewritten in an
  archive pass ("heading structure restored (was flattened)") — provenance
  preserved; content treated as current authoritative wording.
- Structural reorganization into the Skill template only; no semantic changes.

## Source Reference

- Original filename: `10-drawing-and-visualization.md`
- Original source path: `skills/incoming/10-drawing-and-visualization.md`
- Import batch: `batch-001`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-001)
