# Skill: pine-language-core

## Metadata

```yaml
id: pine-language-core
name: Pine Language Core
version: 1.0.0
path: skills/normalized/core/pine-language-core/skill.md
layer: CORE
domains: [pine-syntax]
triggers:
  english:
    - pine syntax
    - variable declaration
    - reassignment operator
    - var vs varip
    - lazy and or short circuit
    - history-reference operator
    - user-defined function
    - method overloading
    - local scope rules
    - switch default branch
    - loop timeout
  persian:
    - سینتکس پایین اسکریپت
    - تعریف متغیر
    - تفاوت var و varip
    - ارجاع به تاریخچه
    - تابع کاربر
    - متد
    - محدوده محلی
    - حلقه و مدت اجرا
dependencies:
  mandatory: []
  optional: [pine-type-system, pine-data-structures, pine-functions-libraries, pine-v6]
status: normalized
priority: 1
```

## Purpose

Canonical reference for Pine Script v6 syntax — variables, types, operators,
expressions, functions, methods, scope, conditionals, and loops. Without it,
the agent risks v5-era errors (`=` vs `:=`, eager logical evaluation, bool `na`,
history-indexing restrictions) that produce wrong series or compile failures.
Select whenever any Pine construct is being written, read, or debugged.

## Triggers

Select when the request involves: Pine syntax or semantics of variables,
operators, functions/methods, scope, conditionals, or loops; debugging syntax
or scope errors; deciding between `var`/`varip`/`once`; loop runtime limits.
Persian requests using «سینتکس», «متغیر», «حلقه», «تابع», «متد» route here.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Target `//@version=` | script metadata | user request / project state | yes |
| Construct in question | text description | user request | yes |
| (For loop budget) bar count / plan | context | formalization contract | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Correct v6 construct / fix | knowledge applied in plan or code | Implementation, Review skills |
| Syntax-risk flags | warnings into Formalization contract | Pre-Verification |
| Loop/scope limit checks | constraint notes | Feasibility |

## Rules

1. Reassignment uses `:=`; `=` is only for first declaration.
2. `var` initializes once (first bar) and persists across bars; `varip` persists
   across realtime ticks and intrabar rollbacks; `once` (v6) runs its block once
   when the condition first becomes true on a closed bar.
3. `and`/`or` are lazily evaluated (short-circuit); safe pattern:
   `if array.size(a) > 0 and array.get(a, 0) > 0`.
4. `[]` cannot index history of literals or UDT fields.
5. Calling `ta.*` functions conditionally (inside `if`/`for`) corrupts their
   internal history — compute globally, branch on the result.
6. Methods bind to their mandatory first-parameter type; overload by first-param type.
7. `switch` used as an expression MUST have a default branch (else → `na` result).
8. Numeric values are not implicitly cast to bool — use `bool(x)` explicitly.
9. Loop hard limits: ≤ 500 ms per bar per loop; total script ≤ 20 s (Basic) /
   40 s (other plans).
10. Scope limit: 1000 variables per scope.

## Workflow

1. Identify the construct and the target version from the request (Pre-Implementation stage).
2. If the construct is version-sensitive, cross-check via the
   pine-version-intelligence pipeline before asserting behavior.
3. Produce the correct v6 pattern; flag any v5-era assumption found in user code.
4. Feed syntax-risk flags into the Formalization contract and Pre-Verification.

## Constraints

- Applies to Pine Script v6 only; v5 behavior may differ (see pine-v6).
- Does not cover type qualifiers in depth (pine-type-system), containers
  (pine-data-structures), libraries (pine-functions-libraries), or execution
  timing (tradingview-execution-model) — use those Skills instead.
- 1000 variables per scope; 500 ms/loop, 20 s/40 s total (plan-dependent).

## Assumptions

- The user's script targets Pine v6 (verify via `//@version=`).
- TradingView cloud runtime limits hold at their documented values.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| v5-era construct in v6 script | compile error / behavior mismatch | flag, propose v6 replacement |
| Conditional `ta.*` call | divergent series / repaint symptoms | restructure to global call |
| Loop timeout | runtime error at 500 ms/loop | reduce complexity, consult pine-performance-engineering |

## Dependencies

Optional: pine-type-system (qualifier errors), pine-data-structures (container
syntax), pine-functions-libraries (library/method details), pine-v6 (migration
checklist). Each independently matches its own triggers per routing policy.

## Examples

- "Why does my RSI change when I move the call inside an `if`?" → Rule 5:
  conditional-call history corruption; restructure.
- "Translate this v5 bool handling to v6" → rules 4/8: no bool `na`, no implicit cast.
- Persian: «چرا حلقه‌ام timeout می‌شود؟» → rule 9 limits; loop budgeting.

## Verification Criteria

- Any emitted construct compiles as valid v6 (Post-Verification: syntax gate).
- No `ta.*` call placed inside a conditional/loop body without a global twin.
- All reassignments use `:=`; no bool `na` assumptions present.
- Loop count/complexity documented against the 500 ms/bar budget in Feasibility.

## Ambiguities

- None recorded from the source. If a user's plan tier differs (Basic vs paid),
  total-time limits differ — resolve at Formalization, not here.

## Missing Information

- None beyond the source's own scope boundaries (see Constraints).

## Import Notes

- Batch `batch-001` import from `skills/incoming/01-pine-language-core.md`.
- Normalization was structural only: the source's sections (Purpose / When to
  Use / Core Knowledge / Common Mistakes / Corrections) were re-organized into
  the standard Skill template fields; no rule was added, removed, or reworded
  semantically. Persian triggers are faithful renderings; technical terms kept
  untranslated where translation would reduce accuracy.
- Source self-declared confidence: high; content verified against official docs
  by the source author (stated in source); spot-checked during import.

## Source Reference

- Original filename: `01-pine-language-core.md`
- Original source path: `skills/incoming/01-pine-language-core.md`
- Import batch: `batch-001`
- Normalization status: normalized
- Validation status: passed (static review + release-notes cross-check)
- Import date: 2026-09 (batch-001)
