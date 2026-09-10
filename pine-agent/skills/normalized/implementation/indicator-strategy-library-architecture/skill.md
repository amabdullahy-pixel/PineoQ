# Skill: indicator-strategy-library-architecture

## Metadata

```yaml
id: indicator-strategy-library-architecture
name: Indicator / Strategy / Library Architecture
version: 1.0.0
path: skills/normalized/implementation/indicator-strategy-library-architecture/skill.md
layer: IMPLEMENTATION
domains: [script-architecture, declaration-parameters]
triggers:
  english:
    - indicator or strategy or library
    - script type selection
    - declaration statement parameters
    - overlay setting
    - max_labels_count
    - max_bars_back
    - convert indicator to strategy
    - convert strategy to indicator
  persian:
    - انتخاب نوع اسکریپت
    - اندیکاتور یا استراتژی یا کتابخانه
    - پارامترهای اعلان اسکریپت
    - تبدیل اندیکاتور به استراتژی
dependencies:
  mandatory: []
  optional: [pine-functions-libraries, strategy-engine, pine-v6, documentation-verification]
status: normalized
priority: 2
```

## Purpose

Choosing the right script type (`indicator()` / `strategy()` / `library()`) and
configuring declaration parameters correctly — type capability matrix,
const-only declaration values, drawing caps, and type-conversion workflows.
Required at the start of any new script and for any type conversion.

## Triggers

Select for: starting any new script; deciding indicator vs strategy vs library;
configuring declaration/limit parameters; converting between script types;
suspicion that declaration params received non-const values.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Intended script purpose | description | user request | yes |
| Target plan tier (for premium params) | context | user request | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Script-type + declaration decision | design decision | Implementation Planning |
| Conversion procedure | workflow | Implementation |
| Limit parameters (drawing caps, max_bars_back) | constraint notes | Feasibility |

## Rules

1. Script-type selection matrix: visuals/oscillators/alerts/screener integration
   → `indicator()`; backtesting/order simulation/reports/fill alerts →
   `strategy()`; reusable functions/UDTs/enums for other scripts → `library()`.
2. Capability split: indicator — no `strategy.*`, cannot export functions,
   supports `alertcondition()`; strategy — full `strategy.*`, NO
   `alertcondition()`, uses `alert()` + order-fill alerts; library — exports
   functions/methods/UDTs/enums, NO `strategy.*`, NO `input.*()`, no direct
   chart alerts, version-pinned via import path.
3. Declaration parameters take const-only values; `overlay` selects chart pane
   vs separate pane (`scale.none` overlay only); `format`/`precision` control
   number display.
4. Drawing caps: `max_labels_count`/`max_lines_count`/`max_boxes_count` (1–500,
   default 50); `max_polylines_count` (1–100, default 10); `max_bars_back`
   (0–5000) sets the history buffer — usually leave automatic.
5. `timeframe`/`timeframe_gaps` are indicator-only MTF parameters at
   declaration level.
6. Indicator → Strategy conversion: swap declaration; configure
   capital/commission/slippage; replace signal plots with `strategy.entry`/`exit`
   inside the same conditions; keep plots for visual debugging (allowed
   alongside orders).
7. Strategy → Indicator conversion: swap declaration; DELETE all `strategy.*`
   calls (compile errors otherwise); recreate trade markers with
   plotshape/bgcolor if needed.
8. Do not leave `initial_capital`/commission at defaults and trust backtest
   results; do not set `calc_on_every_tick = true` "to be realistic" — it makes
   realtime deviate MORE from the historical backtest (different fill timing).

## Workflow

1. Map the request's intent through the selection matrix (rule 1) at
   Implementation Planning.
2. Choose declaration parameters; verify every value is const (rule 3).
3. Set drawing/request caps according to planned visual density (rule 4).
4. For conversions, execute rule 6 or rule 7 exactly; run a regression check
   that signal conditions were preserved 1:1.

## Constraints

- Library constraints (no input/strategy/plotting) are enforced by the
  platform; see pine-functions-libraries for library export details.
- Premium-gated parameters (`use_bar_magnifier`) must never be assumed
  available.

## Assumptions

- Declaration-parameter behavior per official declaration/strategies/libraries
  docs as claimed by the source.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Series value in declaration param | compile error (const required) | move value to input or compute inside script |
| `alertcondition()` in strategy / `strategy.*` in indicator | compile error | rule 2 capability split |
| `input.*()` in library | compile error | move inputs to consumer scripts |
| Untrustworthy backtest | default capital/commission | configure per rule 8 |

## Dependencies

Optional: pine-functions-libraries (library exports in depth), strategy-engine
(strategy parameter semantics), pine-v6 (removed/changed parameters),
documentation-verification (verify per-version parameter changes). Load only
on their own triggers.

## Examples

- "Should this be an indicator or a strategy?" → rule 1 matrix.
- "Convert my signal indicator into a backtestable strategy" → rule 6 workflow.
- Persian: «کتابخانه‌ام اینپوت می‌خواهد» → rule 2: libraries cannot take inputs.

## Verification Criteria

- Script type matches the capability requirements of the design.
- All declaration values are const.
- No `strategy.*` in indicators; no `alertcondition()` in strategies; no
  `input.*()` in libraries.
- Converted scripts preserve signal conditions exactly (Post-Verification:
  signal equivalence).

## Ambiguities

- None from the source.

## Missing Information

- July 2026 release-note UI changes (recorded during import verification; not
  invented into rules): strategy "Properties" tab items were renamed/reorganized
  (Bar detalization menu replacing the Bar Magnifier checkbox, Long/Short
  leverage inputs replacing margin inputs, Order execution delay input) —
  `margin_long`/`margin_short`/`use_bar_magnifier`/`process_orders_on_close`
  parameters remain valid as declaration-level defaults (backward compatibility
  stated in release notes). A future source revision should reflect the UI
  naming.

## Import Notes

- Batch `batch-001` import from `skills/incoming/08-indicator-strategy-library-architecture.md`.
- The source's own Corrections section states it was previously rewritten in an
  archive pass ("heading structure restored (was flattened)") — provenance
  preserved here; content treated as the current authoritative wording.
- Structural reorganization into the Skill template only; no semantic changes.

## Source Reference

- Original filename: `08-indicator-strategy-library-architecture.md`
- Original source path: `skills/incoming/08-indicator-strategy-library-architecture.md`
- Import batch: `batch-001`
- Normalization status: normalized
- Validation status: passed (with documented verification scope)
- Import date: 2026-09 (batch-001)
