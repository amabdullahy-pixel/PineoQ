# Project Memory — Pine Agent

Project Memory is the **durable, structured record of everything the agent
learns while working on a Pine project**, so that any session (or a future
agent run after interruption) can answer: *what is this project, what exists,
what was decided, what changed, what is broken, and what happens next* —
without reconstructing anything from conversation history.

This document defines the purpose and responsibilities only. The future
implementation (a versioned memory store updated at stage boundaries) is a
later-phase component; nothing Pine-specific is recorded here.

---

## Purpose

1. **Continuity** — work survives restarts, token exhaustion, and context loss
   (pair with the token policy's compression rule: memory is updated *before*
   any context reduction).
2. **Grounding** — routing, formalization, and verification consult recorded
   facts (existing modules, variables, formulas, known bugs) instead of
   re-deriving them or guessing.
3. **Audit** — decisions and validation results are traceable to a version
   and a date.

## Responsibilities — what Project Memory tracks

| Category | Tracked content |
|---|---|
| **Project goals** | Objective, scope, acceptance criteria of the Pine project being built |
| **Current version** | Active code version per artifact; last known-good version; promotion state |
| **Architecture** | Pipeline stage map, module layout, data-flow between modules |
| **Modules** | Engine/filter/output modules: id, purpose, status, owning artifacts |
| **Indicators** | Every indicator/script in the project: id, overlay flag, target TFs |
| **Formulas** | Canonical formula registry: id, expression, meaning, consumers |
| **Variables** | Significant variables/inputs: name, type, semantics, where defined |
| **Signals** | Signal definitions: direction, condition references, priority, consumers |
| **Filters** | Veto/filter logic: id, condition, effect on signals, tunables |
| **Dependencies** | Data sources (symbols, request.* targets), TF relationships, module deps |
| **Known bugs** | Open issues: id, symptom, suspected cause, status, workaround |
| **Constraints** | Binding project constraints (platform budgets, style rules, user requirements) |
| **Architectural decisions** | Decision log: id, decision, rationale, date (mirrors CHANGELOG) |
| **Validation results** | Per-artifact verification outcomes with honest labels (statically reviewed vs user-verified compile) |
| **Change history** | Versioned timeline of what changed and why (mirrors CHANGELOG, summarized) |

## Maintenance rules

- Updated at **stage boundaries** (after each contract is finalized) and
  **before any context compression** — never only at session end.
- Append-oriented: corrections are new entries referencing the old fact, not
  silent rewrites; history is preserved.
- Project Memory holds *facts and pointers* (contract ids, file paths,
  decision ids) — it does not duplicate full contract bodies or code.
- Root files (`PROJECT_MANIFEST.yaml`, `CHANGELOG.md`) remain the authority
  for manifest-level state and chronological history; Project Memory cross-
  references them rather than replacing them.
