# Skill: pine-v6

## Metadata

```yaml
id: pine-v6
name: Pine Script v6
version: 1.0.0
path: skills/normalized/core/pine-v6/skill.md
layer: CORE
domains: [pine-syntax, version-compatibility]
triggers:
  english:
    - pine v6
    - version 6 migration
    - v5 to v6
    - dynamic requests
    - strict booleans
    - lazy and or
    - negative array indices
    - order trimming 9000
    - timeframe.period 1D
    - transp removed
    - when removed
  persian:
    - پایین اسکریپت نسخه ۶
    - مهاجرت نسخه ۵ به ۶
    - تغییرات نسخه ششم
    - درخواست‌های داینامیک
dependencies:
  mandatory: []
  optional: [pine-version-intelligence, pine-language-core, pine-type-system]
status: normalized
priority: 1
```

## Purpose

Current-version behavior, defining v6 changes vs v5, post-release additions,
migration checklist, platform limits, and best practices. The baseline
compatibility authority for every script the agent writes or audits.

## Triggers

Select for: writing any new script (target v6); migrating v5 code; auditing
legacy v5-era assumptions; questions about dynamic requests, strict booleans,
lazy logical operators, or removed parameters (`transp`, `when`).

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Script version declaration | `//@version=` | target script | yes |
| Migration / behavior question | description | user request | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| v6 behavior verdict / migration step | knowledge applied | Implementation |
| Migration checklist results | checklist | Pre-Verification |
| Platform-limit constraints | constraint notes | Feasibility |

## Rules

1. v6 released 2024-12-10; treat as current stable until official sources state
   otherwise. Do not assume v7 exists.
2. Defining v6 changes vs v5: (a) dynamic requests by default
   (`dynamic_requests = true`); (b) strict booleans — `bool` cannot be `na`,
   numeric→bool implicit cast removed; (c) lazy `and`/`or` (short-circuit);
   (d) negative array indices; (e) strategy order trimming at the historic
   ~9,000-order limit (trims oldest instead of erroring); (f) `timeframe.period`
   always includes the multiplier (`"1D"`, not `"D"`); (g) `const int / const
   int` division may return fractional float; (h) `[]` cannot index history of
   literals or UDT fields; (i) `when` and `transp` parameters removed;
   (j) loop end boundary evaluated dynamically before every iteration.
3. Post-release additions recorded by the source: `request.footprint()`
   (2026-01, plan-gated), multiline string literals (`"""…"""`/`'''…'''`,
   2026-04), UDT array/matrix sort + binary search via `sort_field`, `once`
   conditional structure (2026-08).
4. Migration checklist (v5→v6): replace implicit numeric→bool with `bool()`;
   remove `na()`/`nz()` on booleans; check `timeframe.period` string
   comparisons; review dynamic requests for accidental series-string requests;
   remove `transp`/`when`; re-test strategies relying on bool `na` states.
5. Platform limits (summary per source): total execution 20 s (Basic) / 40 s
   (paid); loop ≤ 500 ms/bar; compiled size ≤ 100,256 tokens; 64 plot counts;
   drawings 50 default → 500 max (labels/lines/boxes), 100 polylines, 9 tables;
   `request.*` 40 unique calls (64 on Ultimate); LTF intrabars 100K–200K by
   plan; ≤ 127 total tuple elements across requests; 1,000 variables per scope.
6. Best practices: always `//@version=6`; compile clean with no warnings;
   prefer `var`+arrays for state with explicit buffer trimming; guard request
   calls for plan limits (never assume Ultimate); keep loops O(n) and bounded.
7. Version-sensitive claims must pass the pine-version-intelligence pipeline;
   the release-notes subset cited here was verified during import (2026-09) —
   see Import Notes for verification scope and post-import updates.

## Workflow

1. Confirm the script's `//@version=` target.
2. For migration: run checklist (rule 4) item by item; flag each violation.
3. For behavior questions: apply rule 2/3 facts; if not covered, defer to
   pine-version-intelligence before asserting.
4. Record plan-dependent limits into Feasibility when relevant.

## Constraints

- v6 only; do not answer v5 questions from v6 facts (per-version deprecations).
- Plan-dependent limits (footprint, bar magnifier, intrabar counts, Ultimate
  request counts) must never be assumed available.

## Assumptions

- Source-claimed 2026 additions are accurate as of 2026-09 (verified subset
  listed in Import Notes).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| v5 bool handling in migrated code | compile error / logic flip | apply rule 4 fixes |
| `"D"` comparison fails | `timeframe.period` returns `"1D"` | use multiplier-inclusive strings |
| Series-string request in a loop | runtime error / limit blowup | guard + restrict dynamic requests |
| `transp=`/`when=` argument | compile error | remove per rule 4 |

## Dependencies

Optional: pine-version-intelligence (verification pipeline — mandatory
companion for any fact not covered by rule 7's verified subset),
pine-language-core, pine-type-system.

## Examples

- "Migrate my v5 strategy to v6" → rule 4 checklist.
- "Why does my strategy stop at 9,000 trades?" → rule 2e: trimming semantics.
- Persian: «کد v5 من در v6 کامپایل نمی‌شود» → checklist + strict booleans.

## Verification Criteria

- `//@version=6` present; no removed-parameter usage (`transp`, `when`).
- No numeric→bool implicit casts; no bool `na` assumptions.
- Dynamic requests audited for series-string usage when loops are present.
- Plan-gated features guarded or explicitly unavailable.

## Ambiguities

- The source's "post-release additions" list may be incomplete relative to the
  live release notes (see Import Notes); treat rule 3 as non-exhaustive and
  defer unknown facts to pine-version-intelligence.

## Missing Information

- July 2026 release-note items are absent from the source (recorded here from
  the import-time verification; not invented into the Skill's rules):
  `calc_on_every_history_tick` strategy parameter; strategy UI/Properties
  reorganization (Bar detalization replacing Bar Magnifier UI, leverage inputs
  replacing margin inputs, order execution delay input); automatic parentheses
  editor feature. These do not invalidate any source rule but should be added
  by a future source revision.

## Import Notes

- Batch `batch-001` import from `skills/incoming/05-pine-v6.md`.
- Import-time verification (2026-09, official TradingView release notes):
  CONFIRMED — `once` conditional structure (Aug 2026, executes block once when
  condition first true on a closed bar); `request.footprint()` (Jan 2026);
  multiline strings (Apr 2026); UDT sort + binary search via `sort_field`
  (Apr + Aug 2026). NOT PRESENT IN SOURCE but found in release notes: July 2026
  `calc_on_every_history_tick` and the strategy Properties/report UI changes —
  recorded under Missing Information. No source rule required semantic
  correction; all normalization was structural.

## Source Reference

- Original filename: `05-pine-v6.md`
- Original source path: `skills/incoming/05-pine-v6.md`
- Import batch: `batch-001`
- Normalization status: normalized
- Validation status: passed (with documented verification scope)
- Import date: 2026-09 (batch-001)
