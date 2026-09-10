---
name: drawing-and-visualization
category: TradingView Architecture
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/visuals/text-and-shapes/
  - https://www.tradingview.com/pine-script-docs/visuals/lines-and-boxes/
  - https://www.tradingview.com/pine-script-docs/visuals/tables/
  - https://www.tradingview.com/pine-script-docs/writing/limitations/
---

# Drawing & Visualization

## Purpose
Plots vs drawing objects, coordinate systems, limits, and dashboard patterns.

## When to Use
- Any visual output: plots, labels, zones, tables, dashboards.

## Core Knowledge

### Two Visualization Families
1. **Plot-based** (fixed series per bar, no per-object management):
   `plot`, `plotshape`, `plotchar`, `plotarrow`, `plotcandle`, `plotbar`,
   `bgcolor`, `barcolor`, `fill`, `hline`.
2. **Object drawings** (managed instances): `label.new`, `line.new`, `box.new`,
   `polyline.new`, `table.new` — creatable in LOCAL scopes (if/loops/functions),
   with `set_*` / `get_*` / `delete` management.

### Scope Rules
- Global-only: `plot`, `hline`, `fill`, `bgcolor`, `barcolor`.
- Local-allowed: `plotshape`, `plotchar`, `plotarrow`, `plotbar`, `plotcandle`
  (with const-string params in local scope), and ALL object drawings.
- Verify exact per-version scope rules via skill 76 when in doubt.

### Limits (plot counts & drawings)
- **64 plot counts** max. Each `plot*`/`bgcolor`/`barcolor`/`fill`(series
  color)/`alertcondition` call consumes counts (a dynamic `plotcandle` can use 7).
- Drawings: label/line/box default 50 → max **500** each (`max_*_count`
  params); polyline max **100**; tables max **9** (one per anchor position).
- Overflow → oldest drawing auto-deleted. Setting coords to `na` still burns
  an ID — prefer conditional creation via `if`.

### Coordinates
- `xloc.bar_index` (default): bar indices; ≥ `bar_index - 10000` lookback;
  ≤ 500 bars into the future.
- `xloc.bar_time`: UNIX ms of bar open — use beyond 10k-bar history or MTF anchors.
- `yloc.price` (default) | `yloc.abovebar` | `yloc.belowbar` (y ignored).
- `extend.none/left/right/both`; styles: `line.style_*`, `label.style_*`.
- `polyline.new(array<chart.point>, ...)` — connected vertices via `chart.point`.

### Dashboard Pattern (performance-critical)
```pine
var table t = table.new(position.top_right, 4, 3)
if barstate.islast
    table.cell(t, 0, 0, "Metric", text_color = color.white)
    table.cell(t, 1, 0, str.tostring(value, format.mintick))
```
- Declare with var; populate ONLY under `if barstate.islast`; update cells
  with table.cell() (overwrites in place, no leak).

## Common Mistakes
- Calling table.cell() on every bar/history → severe slowdown.
- Creating labels/lines per-bar without caps → garbage-collected surprise.
- Burning drawing IDs with na coordinates instead of if-gated creation.
- Exceeding 64 plot counts with many plotshape/bgcolor calls.

## Corrections & Updates
- [2026-09] Created; verified against official visuals & limitations docs.
- [2026-09] Rewritten in archive: heading structure restored (was flattened).
