---
name: pine-code-architecture
category: Agent & Software Engineering
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/libraries/
  - https://www.tradingview.com/pine-script-docs/language/
---

# Pine Code Architecture

## Purpose
Modular architecture, separation of concerns, DRY, single responsibility,
dependency management, function architecture — Pine-idiomatic.

## When to Use
- Any script beyond ~100 lines; every production system.

## Core Knowledge

### Layered Structure (canonical file layout)
```
1. Declaration + limits params
2. Inputs (grouped by concern)
3. Constants & enums (magic numbers eliminated)
4. Data acquisition (request.* calls, guards)
5. Core calculations (pure functions)
6. State management (var state machine)
7. Signal logic (pure predicates)
8. Execution / alerts
9. Visualization (dashboard, labels)
10. Debug scaffolding (log/plot toggles)
```

### Separation of Concerns (Pine adaptation)
- CALCULATION ≠ SIGNAL ≠ EXECUTION ≠ DISPLAY. Each layer reads outputs of the
  previous; never let a plot call decide an entry condition.
- Pure functions first: same inputs → same outputs, no side effects — testable.
- State machine (trend, regime, zone arrays) isolated in one section with
  explicit transitions (skills 40/47).

### DRY & Single Responsibility
- One function = one job (e.g., `atrStop()`, `zoneMitigated()`, `inSession()`).
- Duplicate logic → extract; BUT beware false DRY: two ta.sma calls with
  different lengths are NOT duplication (skill 01 instance semantics).
- Shared helpers → libraries (skill 04); version-pinned imports.

### Dependency Management
- Dependency direction: viz → signals → calc → data (never reverse).
- Library functions receive everything as params (no global closes — compile
  rule, skill 04).
- Input contract: production params enter ONLY via inputs; research params
  hardcoded → promoted deliberately (skill 65).

### Function Architecture
- Keep functions ≤ ~15 lines; >3 nesting levels → refactor.
- Return tuples for multi-output calcs `[stop, target, size]` (skill 02).
- Guard clauses at top (na/empty/budget), happy path below.

## Common Mistakes
- God-script: one 400-line global blob (untestable, unreviewable).
- Logic hidden inside plotting conditionals.
- Library function mutating passed arrays silently (side effects).
- Magic numbers repeated with different values across sections.

## Corrections & Updates
- [2026-09] Created; layering adapted to Pine's single-pass execution model.
