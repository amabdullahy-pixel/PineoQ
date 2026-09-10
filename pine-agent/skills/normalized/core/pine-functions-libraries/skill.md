# Skill: pine-functions-libraries

## Metadata

```yaml
id: pine-functions-libraries
name: Pine Functions & Libraries
version: 1.0.0
path: skills/normalized/core/pine-functions-libraries/skill.md
layer: CORE
domains: [pine-syntax, libraries]
triggers:
  english:
    - user-defined function
    - library export
    - import library version pin
    - built-in namespaces
    - method overload
    - tuple return
    - conditional call trap
    - exported function global scope
  persian:
    - تابع کاربر
    - کتابخانه
    - ایمپورت کتابخانه
    - نیم‌اسپیس داخلی
    - سربارگذاری متد
dependencies:
  mandatory: []
  optional: [pine-language-core, pine-code-architecture, pine-v6]
status: normalized
priority: 1
```

## Purpose

Namespaces, user-defined functions/methods, and building/importing Pine
libraries — including the export constraints (no global-scope references, no
`input.*()` in libraries) and version-pinned imports. Required whenever logic
is factored into reusable components or community libraries are consumed.

## Triggers

Select for: organizing reusable logic; publishing or importing libraries;
library compile errors about exports; behavior drift after library updates;
method design and overloading questions.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Component design / library question | description | user request | yes |
| Library identity + version (if importing) | text | user request | conditional |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Correct function/method/library pattern | knowledge applied | Implementation |
| Export-constraint flags | warnings | Pre-Verification |
| Version-pin requirement | constraint note | Implementation Planning |

## Rules

1. Built-in namespaces include: `ta`, `math`, `str`, `array`, `matrix`, `map`,
   `request` (security/financial/seed/dividends/splits/footprint), `ticker`,
   `syminfo`, `timeframe`, `time`, `color`, `input`, drawing namespaces
   (`plot*`/`label`/`line`/`box`/`table`/`polyline`), `alert`, `strategy`,
   `position`, `order`, `session`, `barstate`, `chart`, `currency`,
   `dayofweek`, `extend`, `format`, `hline`, `location`, `size`, `xloc`,
   `yloc`, `display`.
2. UDF return = last expression; params may have defaults; tuple returns
   supported; each call site creates an independent instance with its own
   internal history.
3. Conditional-call trap: a `ta.*` call inside `if`/`for` updates only when
   executed → wrong series. Standard fix: compute globally, branch on result.
4. Methods: `method name(Type firstParam, ...) =>`, called via dot syntax;
   overload by first-parameter type; can extend built-in types and UDTs.
5. Libraries export functions, methods, UDTs, enums; libraries cannot be added
   to a chart and cannot plot directly; exported functions must not reference
   global-scope variables — pass everything as parameters.
6. Import with explicit version (`import user/mylib/1 as my`); bump the
   library `#version` on breaking changes; version pinning freezes behavior.
7. Reusable-component design: expose tunables via `input.*` (not magic
   numbers), single responsibility per function, no hidden global state,
   type-annotate public signatures, validate inputs and handle `na` explicitly.

## Workflow

1. Identify the component boundary (function, method, or library export).
2. Check export constraints (rules 5) and call-site history semantics (rules 2–3).
3. For imports, require a version pin; flag unpinned imports as a risk.
4. Feed constraint flags into Pre-Verification.

## Constraints

- Libraries: no `strategy.*`, no `input.*()`, no direct chart alerts, no plotting.
- Exported functions cannot close over globals.

## Assumptions

- Pine v6; library semantics per official docs as claimed by the source.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Export closes over a global | compile error | convert to parameter |
| Unpinned import | behavior drift after update | pin version in import path |
| Double UDF call diverges | differing series per call site | expected: independent instances; restructure if sharing needed |
| Library mutates caller's array | side-effect leak | document/avoid in-place mutation |

## Dependencies

Optional: pine-language-core (function base), pine-code-architecture (file
structure), pine-v6 (migration notes). Load only on their own triggers.

## Examples

- "Split my indicator into an importable library" → rules 5–7.
- "Two calls to my function give different series" → rule 2 (independent
  instances per call site).
- Persian: «کتابخانه‌ام پلات نمی‌کند» → constraint: libraries cannot plot.

## Verification Criteria

- No exported function references global-scope variables.
- Every `import` statement pins a version.
- No `input.*()`/`strategy.*` calls inside library code.
- Public signatures are type-annotated.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-001` import from `skills/incoming/04-pine-functions-libraries.md`.
- Structural reorganization only; all namespace/constraint facts preserved
  from source, including `request.footprint` in the `request` namespace
  (consistent with the Jan 2026 release notes verified during this import).

## Source Reference

- Original filename: `04-pine-functions-libraries.md`
- Original source path: `skills/incoming/04-pine-functions-libraries.md`
- Import batch: `batch-001`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-001)
