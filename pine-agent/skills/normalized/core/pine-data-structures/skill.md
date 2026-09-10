# Skill: pine-data-structures

## Metadata

```yaml
id: pine-data-structures
name: Pine Data Structures
version: 1.0.0
path: skills/normalized/core/pine-data-structures/skill.md
layer: CORE
domains: [pine-syntax, state-management]
triggers:
  english:
    - array
    - matrix
    - map
    - user-defined type
    - UDT
    - object reference vs copy
    - shallow copy
    - persistent buffer
    - negative indices
    - state persistence across bars
  persian:
    - آرایه
    - ماتریس
    - نگاشت map
    - نوع کاربر UDT
    - کپی و مرجع
    - نگهداری وضعیت بین کندل‌ها
dependencies:
  mandatory: []
  optional: [pine-language-core, pine-type-system, pine-performance-engineering]
status: normalized
priority: 1
```

## Purpose

Arrays, matrices, maps, UDTs, and persistence patterns (`var`, `varip`,
clear-on-condition) with exact size limits. Provides the correct container
choice and mutation semantics (reference vs copy) so state survives bars
without hitting limits or aliasing bugs.

## Triggers

Select for: state that must survive bars (signal history, zones, positions);
container selection questions; copy/reference aliasing bugs; container size or
limit errors; UDT design and field defaults.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| State/container need | description | formalization contract | yes |
| Expected element counts | estimate | user request / planning | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Container choice + persistence pattern | design decision | Implementation Planning |
| Limit/aliasing risk flags | warnings | Feasibility, Pre-Verification |
| Buffer-trimming requirement | constraint note | Implementation |

## Rules

1. Arrays: 1-D `array<T>`; limit 100,000 elements; v6 negative indices supported
   in `array.get/set/insert/remove` (−1 = last element).
2. Matrices: `matrix<T>`; rows × cols ≤ 100,000 total elements.
3. Maps: `map<K,V>`; ≤ 100,000 elements = 50,000 key/value pairs; keys must be
   value types (int, float, bool, string, color, enum) — arrays/UDTs as keys are
   not allowed.
4. UDTs: objects are references — assignment and passing share ONE object;
   `.copy()` is shallow (nested collections still shared → deep-copy manually);
   fields may hold any type incl. other UDTs, arrays, maps; UDT arrays/matrices
   support sort & binary search via `sort_field`.
5. Persistence: `var` for across-bar buffers (trim with shift to cap memory);
   `var` object mutation per bar; `varip` only for state that must survive
   intrabar ticks (accepting historical/realtime discrepancy); clear-on-condition
   via reassignment inside `if` using `:=`.
6. Unbounded `array.push` per bar eventually hits the 100,000 limit and can
   trigger loop timeouts — buffers must have an explicit trimming policy.

## Workflow

1. Determine state semantics: per-bar, across-bars, or across-ticks.
2. Choose container and persistence pattern; state the size bound and trimming rule.
3. Flag aliasing risks where objects are passed/copied.
4. Record limits into Feasibility (runtime/numerical) for the target bar counts.

## Constraints

- Value-type map keys only; no arrays/UDTs as map keys.
- Limits are platform values as documented by the source (100k elements;
  50k map pairs); treat as binding until official docs change.

## Assumptions

- Pine v6 (negative indices, UDT sort_field are v6-era capabilities).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Alias bug: two variables mutate one object | unexpected shared state | `.copy()` + manual deep copy |
| Missing nested copy | partial mutation of "copy" | explicit deep-copy procedure |
| Buffer overflow at 100k | runtime error | add trimming policy (shift/oldest-drop) |
| UDT used as map key | compile error | key by primitive/enum field |

## Dependencies

Optional: pine-language-core (var/varip semantics), pine-type-system (reference
types are series), pine-performance-engineering (loop/memory budgets). Load only
on their own trigger match.

## Examples

- "Keep the last 200 swing highs and drop the oldest" → `var` array + shift trimming.
- "My zones duplicate instead of updating" → rule 4 reference semantics.
- Persian: «آرایه‌ام پر می‌شود» → rule 6: unbounded push; add trim.

## Verification Criteria

- Every persistent buffer has a documented size bound and trim policy (Pre-Verification).
- No array/UDT used as map key.
- Object copies use `.copy()` with nested-collection handling stated when nesting exists.
- Container limits respected for projected bar counts (Feasibility).

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-001` import from `skills/incoming/03-pine-data-structures.md`.
- Structural reorganization only; limits and v6 negative-index/sort_field facts
  preserved verbatim from source claims; consistent with the 2026 release notes
  reviewed during this import (UDT sort/binary search: Apr+Aug 2026 — confirmed).

## Source Reference

- Original filename: `03-pine-data-structures.md`
- Original source path: `skills/incoming/03-pine-data-structures.md`
- Import batch: `batch-001`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-001)
