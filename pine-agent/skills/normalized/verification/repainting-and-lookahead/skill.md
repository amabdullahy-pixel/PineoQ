# Skill: repainting-and-lookahead

## Metadata

```yaml
id: repainting-and-lookahead
name: Repainting & Lookahead
version: 1.0.0
path: skills/normalized/verification/repainting-and-lookahead/skill.md
layer: VERIFICATION
domains: [repainting, data-integrity]
triggers:
  english:
    - repainting
    - lookahead
    - future leak
    - barmerge.lookahead_on
    - non-repainting HTF pattern
    - repaint audit
    - historical differs from realtime
  persian:
    - ریپینت
    - نشت اطلاعات آینده
    - lookahead
    - ممیزی ریپینت
    - ناسازگاری تاریخچه با لحظه‌ای
dependencies:
  mandatory: []
  optional: [tradingview-execution-model, mtf-engineering, strategy-engine, data-integrity]
status: normalized
priority: 1
```

## Purpose

Detect, prevent, and correctly reason about repainting, future leaks, and
historical/realtime discrepancies — the most dangerous failure class in Pine.
Provides the complete cause taxonomy, lookahead mechanics, the official
non-repainting HTF pattern, and the repaint audit checklist used at
Pre/Post-Verification.

## Triggers

Select ALWAYS before publishing, backtesting, or trusting any signal; when
auditing existing scripts (third-party or legacy); when designing alert logic
that must match backtest behavior; whenever a script's history "changes" after
reload.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Script or signal design to audit | code/design | user request | yes |
| Context: HTF usage, varip, plotting-into-past | design facts | formalization contract | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Repaint classification + audit results | verification verdict | Pre/Post-Verification |
| Non-repainting pattern prescriptions | design fixes | Implementation |
| repaint_risk field content | contract field | Formalization contract |

## Rules

1. Definition: repainting = script behavior where historical results differ
   from realtime results. TradingView states >95% of indicators repaint in some
   form. Not all repainting is evil (e.g., a volume profile updating on the
   live bar), but future-leaking repainting invalidates backtests.
2. Complete cause taxonomy: (1) fluid realtime OHLC — `high/low/close` change
   every tick until commit; (2) unconfirmed HTF data — `request.security()`
   without offset returns the developing HTF bar, reload bakes in the final
   value; (3) `varip` — tick-level state not reproducible from historical OHLC;
   (4) plotting into the past — pivot confirmed after N bars then drawn at
   `bar_index[N]` creates the illusion of instant historical signals;
   (5) `timenow` — wall-clock time, unreproducible on history;
   (6) intrabar alerts/orders — fire on ticks, vanish/alter at bar close.
3. Lookahead mechanics: `barmerge.lookahead_off` (default) — HTF data visible
   only at END of HTF period; `barmerge.lookahead_on` — HTF data visible from
   START of HTF period → **FUTURE LEAK unless paired with a `[1]` offset**.
   Lookahead_on is ONLY safe with a confirmed-data offset (`[1]`), or for
   equal/lower timeframe contexts. The leak pattern (requesting the current
   period's `high` with lookahead_on) is FORBIDDEN in publications.
4. The official non-repainting HTF pattern:
   `request.security(syminfo.tickerid, "1D", close[1], lookahead = barmerge.lookahead_on)`
   — `[1]` = last COMPLETED HTF bar; lookahead_on aligns it to the period start
   (removes lag without leaking); data is locked → no repaint.
5. Official anti-repaint recommendations: gate triggers on
   `barstate.isconfirmed` (not usable inside `request.security`); use prior-bar
   values for live-bar-sensitive calculations; use `open` (fixed during the
   bar) where possible; strategies — avoid `calc_on_every_tick = true`; avoid
   `varip` in backtest-critical logic.
6. Repaint audit checklist (run on any script): raw close/high/low in triggers
   without isconfirmed/`[1]`? request.security HTF without offset, or
   lookahead_on without `[1]`? varip used for signals/orders? shapes/labels
   drawn N bars into the past after confirmation? timenow or reload-sensitive
   barstate.isnew/isrealtime logic? calc_on_every_tick = true in a strategy?
7. Known traps: a `[1]`+lookahead_on HTF value is the PREVIOUS HTF bar's close
   by design (not "the same value" as the live HTF close); never trust a
   backtest from a script that plots into the past; "fixing" repaint by
   shifting everything `[1]` adds a full bar of lag instead.

## Workflow

1. At Pre-Verification: run the audit checklist (rule 6) against the design.
2. Classify each finding via the cause taxonomy (rule 2); set the contract's
   repaint_risk field.
3. Prescribe fixes from rules 3–5; distinguish benign live-bar updating from
   future leaks explicitly.
4. At Post-Verification: re-run the checklist on the artifact; confirm the
   implemented pattern matches the documented choice.

## Constraints

- `barstate.isconfirmed` cannot gate inside `request.security()` — use the
  `[1]`+lookahead_on pattern for HTF confirmation instead.
- The leak pattern of rule 3 is forbidden in any published script.

## Assumptions

- TradingView repainting docs semantics as claimed by the source (the
  `[1]`+lookahead_on pattern matches TradingView's official repainting
  documentation).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Backtest vs realtime mismatch | audit checklist hit | classify cause, apply rules 3–5 |
| History changes after reload | unconfirmed HTF data | rule 4 official pattern |
| "Instant" historical signals | plots into the past | rule 2 cause (4); document confirmation lag |
| Everything shifted `[1]` as a "fix" | full-bar lag introduced | rule 7: choose patterns deliberately |

## Dependencies

Optional: tradingview-execution-model (rollback/commit semantics),
mtf-engineering (security/LTF acquisition details), strategy-engine
(fill timing), data-integrity (na/gap interactions). Load only on their own
triggers.

## Examples

- "My daily trend signal disappears on reload" → rule 2 cause (2) → rule 4.
- "Audit this script before I publish" → rule 6 checklist, full pass.
- Persian: «سیگنال‌های گذشته‌ام همیشه درست بودند!» → rule 2 cause (4):
  plotting into the past.

## Verification Criteria

- Audit checklist executed and recorded for every signal-bearing script.
- Every `request.security` HTF call uses a documented pattern (confirmed/
  live/lagged) with repaint consequences stated.
- No lookahead_on without `[1]` on higher-timeframe contexts.
- repaint_risk field populated in the Formalization contract.

## Ambiguities

- The ">95% of indicators repaint" figure is a TradingView-stated marketing/
  docs statistic, not a precise measurement — used qualitatively only.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-002` import from `skills/incoming/12-repainting-and-lookahead.md`.
- Layer decision: primary layer VERIFICATION — the skill's function is
  detection/audit/classification (checklist + taxonomy) consumed at the
  verification gates, with prescriptive fixes as secondary. This resolves the
  batch-001 dependency pointer ("see skill 12") from
  tradingview-execution-model; that skill's optional dependency is now valid.
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `12-repainting-and-lookahead.md`
- Original source path: `skills/incoming/12-repainting-and-lookahead.md`
- Import batch: `batch-002`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-002)
