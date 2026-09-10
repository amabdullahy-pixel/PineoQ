# Skill: pine-type-system

## Metadata

```yaml
id: pine-type-system
name: Pine Type System
version: 1.0.0
path: skills/normalized/core/pine-type-system/skill.md
layer: CORE
domains: [pine-syntax, type-safety]
triggers:
  english:
    - qualifier hierarchy
    - const input simple series
    - type casting
    - bool na
    - tuple destructuring
    - type inference
    - enum
    - request.security argument qualifier
  persian:
    - سیستم تایپ پایین اسکریپت
    - کوالایفایر
    - تبدیل نوع
    - تاپل
    - شمارش enum
dependencies:
  mandatory: []
  optional: [pine-language-core, pine-v6, pine-functions-libraries]
status: normalized
priority: 1
```

## Purpose

Exact rules for Pine qualifiers (`const < input < simple < series`), casting,
tuples, `na`, and type inference. Qualifier errors and v6's strict boolean/`na`
rules are among the most common compile-time failures; this Skill supplies the
authoritative behavior so Pre-Verification can catch them statically.

## Triggers

Select for: compiler errors mentioning "simple/series"; designing function or
library signatures; `na` or boolean handling questions; tuple destructuring;
enum usage; passing values into `request.*` argument slots.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Construct / error in question | text | user request | yes |
| Target version | script metadata | user request | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Qualifier/casting/na verdict | knowledge applied | Implementation, Review skills |
| Type-risk flags | warnings | Formalization, Pre-Verification |
| Signature design guidance | design notes | Implementation Planning |

## Rules

1. Qualifier hierarchy: `const < input < simple < series`; a parameter expecting
   qualifier Q accepts any qualifier ≤ Q; expression qualifier = strongest among
   operands; cannot be downgraded manually.
2. Reference types (arrays, maps, UDT objects) are always `series`.
3. Implicit cast: `int → float` only. No implicit numeric→bool. `bool` no longer
   auto-casts to `int`/`float`.
4. `bool` can never be `na`; `na()`, `nz()`, `fixnan()` reject bool arguments
   (compile error); `myBool[1]` on the first bar returns `false`; unspecified
   `if`/`switch` branches returning bool yield `false`; unique-type parameters
   (e.g. plot styles) no longer accept `na`.
5. Tuple items are NEW variables — cannot destructure onto pre-declared variables;
   all items inherit the strongest qualifier in the tuple; total tuple elements
   across all `request.*()` calls ≤ 127.
6. Types may be inferred from initializers; declare types explicitly for
   readability and precise autocomplete.
7. Enums are named int constants; valid as map keys and input options.

## Workflow

1. Identify the type/qualifier question from the request or failing construct.
2. Apply hierarchy/casting/na rules; identify the minimal correct form.
3. Record type-risk flags (e.g. series-into-simple slot) for Pre-Verification.
4. For signature design, annotate explicit types and note qualifier requirements.

## Constraints

- v6 semantics only; do not apply to v5 without consulting pine-v6 migration rules.
- Does not cover runtime execution timing (tradingview-execution-model) or
  container operation specifics (pine-data-structures).

## Assumptions

- The script targets Pine v6.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| series passed where simple/input required | compile error | restructure value or declare input |
| `nz()` on bool | compile error | replace with explicit false handling |
| tuple onto existing variables | compile error | introduce new tuple variables |
| 0 interpreted as false | logic bug | explicit `bool(x)` cast |

## Dependencies

Optional: pine-language-core (base syntax), pine-v6 (migration checklist),
pine-functions-libraries (export signature rules). Not loaded unless their own
triggers match.

## Examples

- "Why can't I pass `close` into this `request.security` argument?" → rule 1
  qualifier hierarchy at work.
- "`nz(isSignal)` fails to compile" → rule 4: bool rejects `nz` in v6.
- Persian: «چرا 0 شرط من را true نمی‌کند؟» → rule 3/4: no implicit cast; `bool(x)`.

## Verification Criteria

- No qualifier violation in emitted signatures (Post-Verification: type gate).
- No `na()`/`nz()` applied to bool expressions anywhere.
- Tuple destructuring only onto new variables.
- Explicit `bool()` cast used for any numeric→bool intent.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-001` import from `skills/incoming/02-pine-type-system.md`.
- Structural reorganization into the Skill template only; no semantic changes.
  Source's v6 na/bool/casting rules are asserted as verified-against-docs by the
  source; consistent with pine-v6 release-notes review performed at import.

## Source Reference

- Original filename: `02-pine-type-system.md`
- Original source path: `skills/incoming/02-pine-type-system.md`
- Import batch: `batch-001`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-001)
