# Skill: pine-code-architecture

## Metadata

```yaml
id: pine-code-architecture
name: Pine Code Architecture
version: 1.0.0
path: skills/normalized/implementation/pine-code-architecture/skill.md
layer: IMPLEMENTATION
domains: [code-architecture, quality]
triggers:
  english:
    - layered script structure
    - separation of concerns pine
    - DRY single responsibility
    - dependency direction viz signals calc data
    - function architecture tuples
    - god script refactor
  persian:
    - معماری کد پاین
    - جداسازی مسئولیت‌ها
    - بازآرایی اسکریپت
dependencies:
  mandatory: []
  optional: [pine-functions-libraries, pine-language-core, pine-type-system,
    pine-data-structures, market-structure, regime-detection,
    research-to-code, drawing-and-visualization,
    pine-debugging-and-testing]
status: normalized
priority: 1
```

## Purpose

Modular architecture, separation of concerns, DRY, single responsibility,
dependency management, function architecture — Pine-idiomatic, adapted to
Pine's single-pass execution model.

## Triggers

Select for: any script beyond ~100 lines; every production system;
refactoring god-scripts; library/helper design; "structure my script"
requests.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Script/component to structure | description | implementation contract | yes |
| Validated research model | artifact | research-to-code | conditional |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Layered file layout plan | design artifact | Implementation |
| Function/section decomposition | code plan | Implementation |
| Dependency-direction contract | constraint | Post-Verification |

## Rules

1. Layered structure (canonical file layout): 1 declaration + limits
   params; 2 inputs (grouped by concern); 3 constants & enums (magic
   numbers eliminated); 4 data acquisition (request.* calls, guards); 5
   core calculations (pure functions); 6 state management (var state
   machine); 7 signal logic (pure predicates); 8 execution / alerts; 9
   visualization (dashboard, labels); 10 debug scaffolding (log/plot
   toggles).
2. Separation of concerns (Pine adaptation): CALCULATION ≠ SIGNAL ≠
   EXECUTION ≠ DISPLAY — each layer reads outputs of the previous; never
   let a plot call decide an entry condition. Pure functions first: same
   inputs → same outputs, no side effects — testable. State machine (trend,
   regime, zone arrays) isolated in one section with explicit transitions
   (market-structure / regime-detection patterns).
3. DRY & single responsibility: one function = one job (e.g., atrStop(),
   zoneMitigated(), inSession()); duplicate logic → extract; BUT beware
   false DRY — two ta.sma calls with different lengths are NOT duplication
   (pine-language-core instance semantics). Shared helpers → libraries
   (pine-functions-libraries); version-pinned imports.
4. Dependency management: dependency direction viz → signals → calc →
   data (never reverse). Library functions receive everything as params
   (no global closes — compile rule, pine-functions-libraries). Input
   contract: production params enter ONLY via inputs; research params
   hardcoded → promoted deliberately (research-to-code).
5. Function architecture: keep functions ≤ ~15 lines; >3 nesting levels →
   refactor; return tuples for multi-output calcs [stop, target, size]
   (pine-type-system); guard clauses at top (na/empty/budget), happy path
   below.

## Workflow

1. Map the intended script onto the 10-layer layout (rule 1).
2. Assign each responsibility to its layer; isolate state machines
   (rule 2).
3. Extract helpers; check for false-DRY traps (rule 3).
4. Verify dependency direction and the input contract (rule 4); apply
   function-architecture rules (rule 5).

## Constraints

- No god-scripts (one 400-line global blob — untestable, unreviewable).
- No logic hidden inside plotting conditionals.
- No library functions mutating passed arrays silently (side effects).
- No magic numbers repeated with different values across sections.

## Assumptions

- Layering adapted to Pine's single-pass execution model (source-declared,
  consistent with tradingview-execution-model).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| 400-line global blob | god-script | rule 1: layered layout |
| Plot decides entry | display/exec mixing | rule 2: layer separation |
| False DRY extraction | different-length SMAs merged | rule 3: instance semantics |
| Reverse dependency | calc reads viz state | rule 4: direction contract |

## Dependencies

Optional: pine-functions-libraries (shared helpers), pine-language-core
(instance semantics), pine-type-system (tuples), pine-data-structures
(state containers), market-structure / regime-detection (state machines),
research-to-code (promotion pipeline), drawing-and-visualization (viz
layer), pine-debugging-and-testing (debug scaffolding). Load only on their
own triggers.

## Examples

- "Structure my 300-line strategy" → rule 1 layout → rule 2 separation.
- "Should I merge these two SMA calls?" → rule 3 false-DRY check.
- Persian: «اسکریپتم شلوغه، چطور مرتبش کنم؟» → rule 1 layered structure.

## Verification Criteria

- 10-layer layout present; concerns separated (calc/signal/exec/display).
- Dependency direction respected (viz → signals → calc → data).
- Functions ≤ ~15 lines, guard clauses first, tuples for multi-outputs.
- Inputs cover every production parameter.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-007` import from `skills/incoming/68-pine-code-architecture.md`.
- Layer IMPLEMENTATION (directly governs production code structure);
  resolves pending optional-dependency pointers from
  optimization-and-calibration and overfitting-and-robustness (batches
  006/004). Source's illustrative identifiers (atrStop, zoneMitigated,
  inSession) preserved as prose per normalization convention (no code
  generated). Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `68-pine-code-architecture.md`
- Original source path: `skills/incoming/68-pine-code-architecture.md`
- Import batch: `batch-007`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-007)
