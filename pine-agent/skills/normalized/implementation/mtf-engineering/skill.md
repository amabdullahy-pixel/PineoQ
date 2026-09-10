# Skill: mtf-engineering

## Metadata

```yaml
id: mtf-engineering
name: MTF Engineering
version: 1.0.0
path: skills/normalized/implementation/mtf-engineering/skill.md
layer: IMPLEMENTATION
domains: [mtf, data-acquisition]
triggers:
  english:
    - request.security
    - request.security_lower_tf
    - higher timeframe request
    - lower timeframe intrabars
    - HTF confirmation lag
    - gaps_on gaps_off
    - dynamic requests
    - intrabar budget
  persian:
    - دیتای چند تایم‌فریم
    - تایم‌فریم بالاتر
    - اینتربار
    - تاخیر تایید HTF
    - بودجه اینتربار
dependencies:
  mandatory: []
  optional: [repainting-and-lookahead, data-integrity, multi-symbol-engineering, pine-v6]
status: normalized
priority: 1
```

## Purpose

Correct multi-timeframe data acquisition: `request.security()` semantics and
correct HTF patterns, `request.security_lower_tf()` intrabar analytics,
timeframe utilities, dynamic-request behavior, and synchronization pitfalls.
Required for any HTF context (daily trend on 15m chart), intrabar analytics,
or MTF confirmation design.

## Triggers

Select for: any HTF request or confirmation design; lower-timeframe intrabar
analytics; MTF synchronization/lag questions; request-budget planning;
choosing between security patterns (confirmed vs live vs lagged).

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| MTF requirement (which TFs, what data) | description | formalization contract | yes |
| Repaint tolerance | design decision | repainting-and-lookahead audit | yes |
| Plan tier (intrabar budget) | context | user request | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Request pattern choice (documented) | design decision | Implementation |
| LTF acquisition design | implementation pattern | Implementation |
| Request/intrabar budget | constraint notes | Feasibility |
| Confirmation-lag expectations | constraint notes | Formalization |

## Rules

1. `request.security()` semantics: timeframe `""`/`timeframe.period` = chart TF;
   gaps `barmerge.gaps_off` (default — fill with last known value historical /
   most recent developing value realtime) vs `barmerge.gaps_on` (na where no
   new confirmed data); lookahead semantics per repainting-and-lookahead.
   Mapping: without lookahead the HTF value appears on the LAST LTF bar of the
   HTF period (confirmation lag); with lookahead_on it appears on the FIRST LTF
   bar (future leak without `[1]`).
2. Correct HTF patterns — choose explicitly and DOCUMENT which one a script
   uses: non-repainting confirmed data (`close[1]` + lookahead_on, official);
   repainting-by-design live data (raw expression — updates intrabar, changes
   on reload); lagged simple (`close[1]` with default lookahead — one HTF
   period of lag).
3. Lower timeframes: `request.security_lower_tf()` returns an ARRAY of intrabar
   values per chart bar (oldest→newest); requested TF must be STRICTLY LOWER
   than chart TF; using `request.security()` for LTF returns only the LAST
   intrabar, discards the rest, and repaints — never do this.
4. Intrabar budget per plan: ~100K (Basic–Premium) / 125K (Expert) / 200K
   (Ultimate) total LTF bars; chart TFs below 1 second unsupported for data
   requests.
5. Timeframe utilities: `timeframe.in_seconds(tf)` (validation, ratio guards —
   e.g., only run logic when HTF ≥ 4× chart TF); `timeframe.from_seconds(n)`;
   `time(timeframe, session, timezone)` for session boundary checks within MTF
   logic.
6. Dynamic requests (v6 default on): series-string symbols/TFs, calls inside
   loops/conditionals/local scopes; limits 40 unique requests (64 Ultimate);
   tuple elements across all requests ≤ 127 (pack richer data into UDTs);
   duplicate requests (same args) don't count twice.
7. Synchronization pitfalls: HTF confirmation lag — a signal can only be as
   fast as the HTF bar close (unless intrabar HTF checks, which repaint);
   session alignment — HTF bars anchor to exchange sessions, comparing 24/7
   crypto HTF bars with equity HTF bars misaligns timestamps; `calc_bars_count`
   limits how far back requested-context history extends.

## Workflow

1. Classify the need: HTF confirmation, live HTF context, or LTF intrabar stats.
2. Select the request pattern per rules 1–3; record the repaint consequence of
   the choice with repainting-and-lookahead.
3. Validate TF relationships (strictly-lower rule; ratio guards via
   `timeframe.in_seconds`).
4. Budget requests/intrabars (rules 4, 6) into Feasibility.
5. Document synchronization expectations (rule 7) in the Formalization contract.

## Constraints

- LTF via `request.security()` is forbidden in designs (data loss + repaint).
- Request caps (40/64) and the 127 tuple-element cap are hard platform limits.
- Intrabar budget is plan-gated — never assume Ultimate counts.

## Assumptions

- Security/merging semantics per official other-timeframes docs as claimed by
  the source.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| LTF via request.security | partial data + repaint | rule 3: security_lower_tf |
| Security on LTF string by mistake | error/empty array | strictly-lower validation |
| gaps_on assumed "safer" | unexpected na | rule 1: handle na explicitly (data-integrity) |
| Tuple returns > 127 elements | compile error | rule 6: pack into UDTs |

## Dependencies

Optional: repainting-and-lookahead (lookahead mechanics + audit),
data-integrity (na/session semantics), multi-symbol-engineering (symbol
requests), pine-v6 (dynamic-requests default). Load only on their own triggers.

## Examples

- "Daily trend filter on a 15m chart without repainting" → rule 2 confirmed
  pattern.
- "Volume delta per 15m bar from 1m data" → rule 3 security_lower_tf + rule 4
  budget.
- Persian: «فیلتر روزانه‌ام روی چارت ۱۵ دقیقه ریپینت می‌کند» → rule 2.

## Verification Criteria

- Every request's pattern (confirmed/live/lagged) documented in the design.
- No `request.security()` usage with a lower-timeframe argument.
- Request count and intrabar budget within plan limits (Feasibility).
- Confirmation-lag expectations stated wherever HTF confirmation gates signals.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-002` import from `skills/incoming/13-mtf-engineering.md`.
- Structural reorganization only; no semantic changes. Source cross-reference
  "see skill 12" → optional dependency on repainting-and-lookahead (imported
  this batch). Resolves the batch-001 pending optional-dependency pointer from
  tradingview-execution-model and drawing-and-visualization.
- Intrabar budget numbers (100K/125K/200K) are plan-gated platform values —
  recorded as binding-per-source with the same re-verify caveat as other
  plan-dependent limits.

## Source Reference

- Original filename: `13-mtf-engineering.md`
- Original source path: `skills/incoming/13-mtf-engineering.md`
- Import batch: `batch-002`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-002)
