# Skill: tradingview-execution-model

## Metadata

```yaml
id: tradingview-execution-model
name: TradingView Execution Model
version: 1.0.0
path: skills/normalized/core/tradingview-execution-model/skill.md
layer: CORE
domains: [execution-model, repainting]
triggers:
  english:
    - execution model
    - historical vs realtime
    - rollback
    - barstate.isconfirmed
    - barstate.isnew
    - varip rollback
    - intrabar behavior
    - realtime discrepancy
    - why realtime differs from history
  persian:
    - مدل اجرا
    - تاریخی در برابر لحظه‌ای
    - بازگشت وضعیت rollback
    - تایید شدن کندل
    - تفاوت رفتار realtime با تاریخچه
dependencies:
  mandatory: []
  optional: [repainting-and-lookahead, strategy-engine, mtf-engineering, pine-language-core]
status: normalized
priority: 1
```

## Purpose

Exact runtime semantics of TradingView: historical vs realtime execution,
tick rollback and commit, `var`/`varip` persistence under rollback, bar state
built-ins, and the canonical sources of historical/realtime discrepancy.
Required for any repaint-safe design and any code touching intrabar state,
bar-close gating, or alerts.

## Triggers

Select for: explaining why realtime behavior differs from history; designing
repaint-safe logic; using `barstate.*` correctly; `var`/`varip` intrabar
behavior; alerts at bar close; intrabar/tick-level logic questions.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Execution-semantics question | description | user request | yes |
| Context: indicator vs strategy, `calc_on_every_tick` | script metadata | formalization contract | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Execution-semantics verdict | knowledge applied | Implementation |
| Repaint-risk sources identified | risk classification | Pre/Post-Verification, repainting-and-lookahead |
| `barstate` guard recommendation | design decision | Implementation Planning |

## Rules

1. Historical bars: script runs ONCE per bar, left→right, OHLCV fixed; state
   committed at each bar's end.
2. Realtime bar (rightmost): script runs ONCE PER TICK; `high/low/close` are
   fluid; `open` fixed; only the FINAL tick's state is committed to history.
3. Rollback: before EVERY realtime-tick recalculation, all series and `var`
   variables roll back to their committed state at the previous bar close —
   intra-bar `var` increments vanish each tick.
4. `varip` escapes rollback (retains updates across ticks within the bar);
   trade-off: tick-level state is NOT reproducible on historical bars — a
   repainting source (see repainting-and-lookahead).
5. Bar state built-ins: `barstate.ishistory` (historical bars only);
   `barstate.isrealtime` (realtime updates); `barstate.isconfirmed` (historical
   bars AND closing tick of the realtime bar — **the repaint guard**; does NOT
   work inside `request.security()`); `barstate.isnew` (historical bars AND
   first tick of the realtime bar); `barstate.islast` (rightmost bar);
   `barstate.islastconfirmedhistory` (last historical bar when market closed /
   bar before realtime bar when open).
6. Historical/realtime discrepancy sources: fluid `high/low/close`;
   `timenow`; unconfirmed `request.security` values; `varip` state;
   order fills with `calc_on_every_tick`; deleted drawings.
7. Strategy fill timing (depth in strategy-engine): default execution at bar
   close with orders on bar N filling at open of bar N+1; no per-tick execution
   unless `calc_on_every_tick = true`; order-fill alerts fire immediately
   regardless.

## Workflow

1. Classify the question: state persistence, bar-state gating, discrepancy
   explanation, or fill timing (defer depth to strategy-engine).
2. Apply rollback/commit semantics to the concrete `var`/`varip` usage.
3. Recommend `barstate.isconfirmed`-style guards where bar-close confirmation
   is required (noting the `request.security` exclusion).
4. Route identified repaint sources to repainting-and-lookahead for
   classification; record in the Formalization contract's repaint_risk field.

## Constraints

- `barstate.isconfirmed` is unsupported inside `request.security()` — no
  exception path exists in this Skill.
- This Skill explains semantics; it does not provide the repaint taxonomy
  (that is repainting-and-lookahead's responsibility).

## Assumptions

- TradingView cloud runtime follows the documented execution model as claimed
  by the source (verified against official execution-model & bar-states docs
  per source; semantics are stable, long-documented behavior).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| `barstate.isnew` gate expected false on history | logic runs every historical bar | rule 5: it is TRUE on all historical bars |
| `isconfirmed` inside `request.security` | compile/runtime limitation | unsupported per rule 5; restructure confirmation |
| `var` tick accumulator "disappears" | rollback | use `varip` only if intrabar state truly required |
| "bug" report from screenshot-vs-history comparison | discrepancy source | rule 6: expected behavior, not a defect |

## Dependencies

Optional: repainting-and-lookahead (repaint taxonomy), strategy-engine (fill
depth), mtf-engineering (security-context confirmation semantics),
pine-language-core (var/varip base). Load only on their own triggers.

## Examples

- "My counter resets every tick" → rule 3 rollback; `varip` trade-off.
- "How do I signal only on confirmed bars?" → rule 5 `barstate.isconfirmed`
  guard (+ its security-context exclusion).
- Persian: «چرا اندیکاتور من روی کندل آخر فرق دارد؟» → rule 2/6 fluid values.

## Verification Criteria

- Every bar-state gate matches rule 5 semantics (Post-Verification: runtime).
- No `barstate.isconfirmed` usage inside `request.security()`.
- `varip` usage is justified in writing (intrabar requirement stated).
- Identified discrepancy sources are recorded in the contract's repaint_risk field.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-001` import from `skills/incoming/07-tradingview-execution-model.md`.
- Structural reorganization only; all semantics preserved verbatim in meaning.
  Cross-references to skills 09 and 12 became optional dependencies per the
  no-duplication rule.

## Source Reference

- Original filename: `07-tradingview-execution-model.md`
- Original source path: `skills/incoming/07-tradingview-execution-model.md`
- Import batch: `batch-001`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-001)
