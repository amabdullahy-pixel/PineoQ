# Skill: pine-project-documentation

## Metadata

```yaml
id: pine-project-documentation
name: Pine Project Documentation
version: 1.0.0
path: skills/normalized/meta/pine-project-documentation/skill.md
layer: META
domains: [documentation, delivery]
triggers:
  english:
    - deliverable documentation set
    - system spec formulas variables signals docs
    - publication checklist tradingview
    - changelog validated rows
    - doc drift control
    - in-code documentation standards
  persian:
    - مستندسازی پروژه پاین
    - چک‌لیست انتشار
    - مستندات تحویلی
dependencies:
  mandatory: []
  optional: [requirements-engineering, hypothesis-and-formula-engineering,
    research-methodology, project-knowledge-management,
    pine-code-architecture, repainting-and-lookahead, mtf-engineering,
    backtesting-science, walk-forward-and-validation,
    pine-debugging-and-testing]
status: normalized
priority: 1
```

## Purpose

Deliverable-grade documentation: system specification, formula
documentation, variable dictionary, signal definitions, architecture,
changelog, version history — for every project handoff, publication, or
archive point.

## Triggers

Select for: every project handoff, publication, or archive point;
publication-checklist audits; doc-drift complaints; "document my script"
requests.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Completed/validated project | artifacts | project | yes |
| Manifest registries | rows | project-knowledge-management | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| 8-piece documentation set | deliverables | user/publication |
| In-code documentation block | header standard | Implementation |
| Publication checklist verdict | gate record | Post-Verification |

## Rules

1. Documentation set (per project): SYSTEM-SPEC.md — what it does,
   non-goals, requirements trace (requirements-engineering formal spec
   promoted), plan/constraints envelope; FORMULAS.md — every formula:
   exact math, Pine line refs, alternative formulations tested, validation
   status (hypothesis-and-formula-engineering / research-methodology);
   VARIABLES.md — variable dictionary: name/type/units/persistence/
   lifecycle (generated skeleton from project-knowledge-management
   registry); SIGNALS.md — each signal: exact condition, confirmation
   semantics (close-confirmed?), consumers (alerts/orders), known failure
   modes; ARCHITECTURE.md — layers, module map, data flow, state-machine
   diagram (text), dependency graph; CHANGELOG.md — user-facing changes
   per version; VERSIONS.md — technical version history + validation
   evidence per row; README.md — 10-line quickstart: install, inputs,
   alerts, caveats.
2. In-code documentation standards: header block — project/version,
   MANIFEST pointer, purpose, SIGNALS with confirmation semantics, CAVEATS
   (plan-gated requests list, repaint policy none/by-design); section
   banners per the layered layout (pine-code-architecture); every magic
   number → input or constant with a comment stating UNITS; every function
   header: purpose + params + return + side effects (none expected — if
   any, shout).
3. Changelog rules: format `## [1.2.0] — 2026-09-15 ·
   ADDED/CHANGED/FIXED/VALIDATED` rows; VALIDATED rows cite ledger trials
   (project-knowledge-management §12) — no claim without evidence; breaking
   signal-semantics changes require a major bump + migration note.
4. Publication checklist (TradingView script page): repaint policy stated
   explicitly (repainting-and-lookahead verdict); plan requirements stated
   (requests/magnifier — mtf-engineering / backtesting-science); default
   inputs = validated configuration (walk-forward-and-validation); no
   lookahead tricks (publication rules — repainting-and-lookahead); formula
   doc matches code (documentation-verification tier-check on each formula
   line).
5. Doc-drift control: docs updated in the SAME change-set as code
   (project-knowledge-management write-before-code + consistency check);
   golden-set regression rerun documented in VERSIONS on every release
   (pine-debugging-and-testing).

## Workflow

1. Generate the 8-piece set from manifest registries (rule 1).
2. Apply the in-code header/banner/units standards (rule 2).
3. Write changelog rows with VALIDATED evidence citations (rule 3).
4. Run the publication checklist before publishing (rule 4); enforce
   drift control (rule 5).

## Constraints

- No docs describing an older signal version (drift).
- No changelog without VALIDATED rows (claims without evidence).
- No past-tense or unit-less in-code comments.
- No missing caveats section (free-plan users hit silent limits).

## Assumptions

- Doc set + publication checklist formalized by the source; this skill
  completes the 77-skill library (v1.0.0) — recorded as the library's own
  closure note.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Docs describe old signals | drift check | rule 5: same-change-set updates |
| Claims without evidence | no VALIDATED rows | rule 3: ledger citations |
| Unit-less comments | missing UNITS | rule 2: units mandatory |
| Free-plan users blocked | no caveats | rule 4: plan requirements stated |

## Dependencies

Optional: requirements-engineering (SYSTEM-SPEC trace),
hypothesis-and-formula-engineering + research-methodology (FORMULAS),
project-knowledge-management (registry skeleton), pine-code-architecture
(ARCHITECTURE), repainting-and-lookahead (publication policy),
mtf-engineering + backtesting-science (plan caveats),
walk-forward-and-validation (validated defaults),
pine-debugging-and-testing (regression evidence). Load only on their own
triggers.

## Examples

- "Prepare my indicator for publication" → rule 4 checklist.
- "Generate the docs for handoff" → rule 1 eight-piece set.
- Persian: «مستندات تحویلی بساز» → rule 1 documentation set.

## Verification Criteria

- All eight docs present and manifest-consistent.
- Changelog VALIDATED rows cite ledger trials.
- Publication checklist passed with repaint/plan statements.
- Doc-drift control demonstrated (same-change-set updates).

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-008` import from
  `skills/incoming/77-pine-project-documentation.md`.
- Layer META (function = deliverable-documentation governance; completes
  the library per the source's own closure note). The source's in-code
  header illustration is preserved as prose describing the standard (no
  code generated). Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `77-pine-project-documentation.md`
- Original source path: `skills/incoming/77-pine-project-documentation.md`
- Import batch: `batch-008`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-008)
