# Skill: requirements-engineering

## Metadata

```yaml
id: requirements-engineering
name: Requirements Engineering
version: 1.0.0
path: skills/normalized/formalization/requirements-engineering/skill.md
layer: FORMALIZATION
domains: [formalization, requirements]
triggers:
  english:
    - requirements extraction
    - acceptance criteria GIVEN WHEN THEN
    - formal specification inputs state signals
    - edge case sweep
    - non-goals scope control
    - must-resolve ambiguity list
  persian:
    - مهندسی نیازمندی‌ها
    - معیار پذیرش
    - مشخصات رسمی
dependencies:
  mandatory: []
  optional: [natural-language-to-math, tradingview-execution-model,
    repainting-and-lookahead, position-sizing, drawing-and-visualization,
    alerts-and-webhooks, indicator-strategy-library-architecture,
    risk-management, multi-symbol-engineering, mtf-engineering,
    backtesting-science, system-psychology, asset-class-specialization,
    pine-performance-engineering, strategy-engine, trade-management]
status: normalized
priority: 1
```

## Purpose

Extracting requirements, detecting ambiguity, capturing constraints,
acceptance criteria, formal specification, and edge cases — BEFORE coding.
Applies to every user request that ends in code.

## Triggers

Select for: every "build me an indicator/strategy…" request; converting a
user story into a buildable spec; defining acceptance criteria; scoping
non-goals.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| User story / request | natural language | user | yes |
| Answers to must-resolve questions | decisions | user | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Formal specification (per script) | contract artifact | formalization/contract_schema, Implementation |
| Acceptance criteria (testable) | verification fields | Post-Verification |
| Edge-case list with intended behavior | constraints | Implementation, Pre-Verification |

## Rules

1. Requirement extraction loop: user story → clarify (ambiguity table —
   natural-language-to-math) → constraints → acceptance criteria → formal
   spec → confirm → THEN build. Every Pine term in the request gets a
   DEFINITION: "trend", "strong move", "confirm", "signal" — resolve via
   the ambiguity table or explicit defaults.
2. Ambiguity detection (must-resolve list): timeframe(s)? symbol scope?
   session filter? costs? signal semantics — intrabar or close-confirmed?
   (tradingview-execution-model / repainting-and-lookahead); entry/exit
   logic; position sizing (position-sizing); pyramiding; visualization —
   overlay/pane, dashboard, alerts needed? (drawing-and-visualization /
   alerts-and-webhooks); strategy vs indicator intent
   (indicator-strategy-library-architecture); unstated risk rules
   (risk-management) — ALWAYS ASK.
3. Constraints capture: platform — plan tier (requests, bar magnifier, LTF
   bars, alerts count — mtf-engineering / multi-symbol-engineering /
   backtesting-science / alerts-and-webhooks), Pine version (v6), limits
   (pine-performance-engineering); market/microstructure — asset-class
   specifics (asset-class-specialization); operator — attention/frequency
   limits (system-psychology).
4. Acceptance criteria (testable or it didn't happen): format `GIVEN
   <context> WHEN <condition> THEN <observable outcome>` — e.g., GIVEN
   BTCUSDT 1D 2019–2026 WHEN signal fires THEN alert at bar close (no
   intrabar); GIVEN flat 20-bar window THEN no division error, output na
   (not 0); GIVEN replay of pinned range THEN metrics match the manifest.
5. Formal specification (per script): INPUTS (typed list with defaults &
   ranges); STATE (vars + transitions); SIGNALS (exact boolean formulas —
   natural-language-to-math form); ORDERS (entry/exit/sizing/exits —
   strategy-engine / trade-management semantics); OUTPUTS (plots/tables/
   alerts + update cadence); NON-GOALS (explicitly excluded — prevents
   scope creep); EDGE CASES (enumerated + intended behavior each).
6. Edge-case sweep (mandatory list): first bars/warm-up · flat series ·
   na-volume symbols · session boundaries · gap bars · 0-size arrays ·
   max-history loops · HTF unconfirmed · all four barstate phases
   (tradingview-execution-model).

## Workflow

1. Run the extraction loop; define every Pine term (rule 1).
2. Resolve every must-resolve ambiguity WITH the requester — never
   silently (rule 2).
3. Capture constraints (platform/market/operator) explicitly (rule 3).
4. Write GIVEN/WHEN/THEN acceptance criteria and the formal spec with
   NON-GOALS (rules 4–5); sweep edge cases (rule 6).

## Constraints

- No coding the literal words without resolving ambiguity (echo-back —
  natural-language-to-math).
- No missing acceptance criteria ("done" must be falsifiable).
- No missing NON-GOALS (feature-creep spiral).
- No silent risk/session defaults.

## Assumptions

- Pine-specific defaults cross-linked to verified skills (source-declared,
  consistent with the verified inventory).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Literal-words coding | no ambiguity resolution | rule 1/2: table + confirm |
| Unfalsifiable "done" | no acceptance criteria | rule 4: GIVEN/WHEN/THEN |
| Feature creep | no NON-GOALS | rule 5: exclusions explicit |
| Invented risk defaults | unstated rules | rule 2: always ask |

## Dependencies

Optional: natural-language-to-math (ambiguity table), execution/repaint
skills (signal semantics), position-sizing / risk-management (risk rules),
viz/alert skills (outputs), architecture skill (strategy vs indicator),
plan-limit skills (constraints), system-psychology (operator constraints).
Load only on their own triggers.

## Examples

- "Build me a scalping indicator" → rules 1–2 must-resolve list first.
- "Write the spec for my strategy" → rule 5 formal spec.
- Persian: «اول دقیق کن می‌خوام چیکار کنه» → rules 1–2 extraction loop.

## Verification Criteria

- Every Pine term defined; all must-resolve items answered or recorded as
  ambiguities.
- Acceptance criteria testable (GIVEN/WHEN/THEN).
- Formal spec complete with NON-GOALS and edge-case behaviors.
- Constraints (plan/market/operator) documented.

## Ambiguities

- None from the source (the skill's function IS ambiguity management).

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-008` import from `skills/incoming/72-requirements-engineering.md`.
- Layer FORMALIZATION (function = pre-coding requirements/specification —
  matches the Formalization pipeline stage; resolves the pending
  optional-dependency pointer from natural-language-to-math, batch-007).
  Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `72-requirements-engineering.md`
- Original source path: `skills/incoming/72-requirements-engineering.md`
- Import batch: `batch-008`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-008)
