# Skill: data-integrity

## Metadata

```yaml
id: data-integrity
name: Data Integrity
version: 1.0.0
path: skills/normalized/implementation/data-integrity/skill.md
layer: IMPLEMENTATION
domains: [data-integrity, sessions-timezones]
triggers:
  english:
    - na handling
    - missing bars gaps
    - session filter
    - timezone bug
    - syminfo.timezone
    - holiday gaps
    - illiquid symbols
    - zero-volume bars
    - fixnan
  persian:
    - مدیریت مقدار na
    - کندل‌های غایب و گپ
    - فیلتر سشن
    - باگ منطقه زمانی
    - تعطیلات بازار
    - کم‌نقدینگی
dependencies:
  mandatory: []
  optional: [mtf-engineering, multi-symbol-engineering, repainting-and-lookahead, pine-type-system]
status: normalized
priority: 2
```

## Purpose

Handling `na`, gaps, sessions, time zones, holidays, and illiquid/synthetic
data so calculations never silently corrupt. Covers how `na` arises (history
overflow, missing bars, session boundaries, `gaps_on`, halted symbols), the
`na` toolkit, canonical session filtering, the timezone rules that prevent the
#1 silent bug, and cross-market data alignment.

## Triggers

Select for: session-filtered strategies; cross-market comparisons; illiquid or
halted symbols; missing-data/na symptoms (fake crashes, sudden zero values);
timezone/hour/dayofweek logic; holiday/weekend gap handling.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Data-corruption symptom or requirement | description | user request | yes |
| Markets involved (sessions, 24/7 vs scheduled) | context | formalization contract | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| na-guard / session / timezone design | design decision | Implementation |
| Gap/illiquidity handling rules | constraint notes | Feasibility, Post-Verification |
| Timezone correctness flags | verification checks | Pre/Post-Verification |

## Rules

1. How `na` arises: history overflow (`close[1000]` on a 500-bar dataset);
   missing bars/gaps (no trades, exchange outages, holidays); session
   boundaries (session-filtered `time()`); `request.*` with `gaps_on`;
   illiquid/halted symbols.
2. `na` toolkit: `na(x)` test; `nz(x, repl)` replace (default 0); `fixnan(x)`
   forward-fill with latest non-na value. v6: `bool` can't be na and
   `na()/nz()/fixnan()` reject bools — for tri-state (long/short/flat) use int
   codes `1 / -1 / 0`, not bool.
3. NEVER chain math on potentially-na series without explicit guards
   (e.g., `float r = na(raw) ? 0.0 : raw`; `bool valid = not na(v) and not na(w)`).
4. Sessions: state built-ins `session.ismarket`/`ispremarket`/`ispostmarket`;
   canonical filter
   `inSess = not na(time(timeframe.period, "0930-1600:23456", syminfo.timezone))`;
   session string `HHMM-HHMM[:days]` (days: 1=Sun…7=Sat); use
   `session.regular`/`session.extended` with `ticker.new()`/`ticker.modify()` to
   choose regular vs extended data context; the chart-level extended-hours
   toggle affects available bars and scripts can't force it.
5. Time zones (the #1 silent bug): time values are UNIX ms (UTC-based,
   zone-agnostic); rendering hours/days REQUIRES a zone — ALWAYS pass
   `syminfo.timezone` (exchange IANA zone, DST-safe) to `hour()`,
   `dayofweek()`, `time()`, `str.format_time()`. Never hardcode
   "America/New_York" for user symbols; never use UTC+X offsets (DST-unsafe);
   chart timezone setting ≠ syminfo.timezone.
6. Holidays/gaps/weekends: traditional markets have normal
   overnight/weekend/holiday gaps — detect with
   `time - time[1] > expected interval` rather than assuming contiguous bars;
   crypto is ~24/7 (only exchange maintenance breaks); cross-asset alignment
   on a common TF (usually "1D") or explicit na-fill; holidays = missing daily
   bars → indicator lookbacks silently span them — decide explicitly whether
   that's acceptable for the strategy.
7. Illiquid & synthetic symbols: zero-volume bars and stale prices
   (`high == low`, `volume == 0`) distort indicators and backtests — filter
   with `volume > 0` or minimum tick-move checks; synthetic/combined tickers
   (spreads via `ticker.modify`) inherit quirks of both legs — validate both
   legs' data first.

## Workflow

1. Identify the data-corruption surface: na sources, session model, timezone
   usage, market calendar (rules 1, 4, 6).
2. Apply the na toolkit with explicit guards (rules 2–3); tri-state via int
   codes where needed.
3. Enforce timezone discipline (rule 5) in any time-rendering code.
4. Add gap/illiquidity filters (rules 6–7) and document the chosen semantics.
5. Feed na/gap risks into Pre-Verification checks and Post-Verification audits.

## Constraints

- v6 bool/na strictness applies (rule 2) — see pine-type-system for the full
  qualifier/na rules.
- Extended-hours availability cannot be forced by scripts (rule 4).

## Assumptions

- Time/session semantics per official time/sessions/bar-merging docs as
  claimed by the source.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| `nz(price)` invents fake crashes | sudden 0 values in stats | rule 3: explicit guards, never blanket nz on prices |
| Hours shifted by DST | wrong session boundaries | rule 5: syminfo.timezone always |
| Signal across holidays | lookback spans gap silently | rule 6: decide + document |
| Backtest inflated by zero-volume bars | stale OHLC rows | rule 7: volume > 0 filter |

## Dependencies

Optional: mtf-engineering (gaps_on semantics, security data),
multi-symbol-engineering (cross-market alignment), repainting-and-lookahead
(discrepancy interactions), pine-type-system (bool/na strictness). Load only on
their own triggers.

## Examples

- "Strategy should trade RTH only" → rule 4 canonical session filter.
- "My indicator shows zero on early bars" → rules 1–3 na guards.
- Persian: «ساعت‌های سشن من یک ساعت جابجاست» → rule 5 timezone discipline.

## Verification Criteria

- Every price/indicator series has explicit na handling (no blanket nz on
  prices).
- All time rendering uses `syminfo.timezone` (grep-checkable).
- Session/gap/illiquidity assumptions documented per market involved.
- No bool-based tri-state states (int codes used).

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-002` import from `skills/incoming/14-data-integrity.md`.
- Structural reorganization only; no semantic changes. The v6 bool/na strictness
  facts align with pine-type-system (batch-001) — cross-referenced as an
  optional dependency rather than duplicated.

## Source Reference

- Original filename: `14-data-integrity.md`
- Original source path: `skills/incoming/14-data-integrity.md`
- Import batch: `batch-002`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-002)
