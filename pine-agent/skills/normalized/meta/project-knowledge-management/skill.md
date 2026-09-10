# Skill: project-knowledge-management

## Metadata

```yaml
id: project-knowledge-management
name: Project Knowledge Management
version: 1.0.0
path: skills/normalized/meta/project-knowledge-management/skill.md
layer: META
domains: [knowledge-management, documentation]
triggers:
  english:
    - project manifest single source of truth
    - formula registry variable dictionary
    - decisions log ADR
    - trial ledger
    - session start consistency check
    - write before code
  persian:
    - مدیریت دانش پروژه
    - ثبت تصمیم‌ها
    - دفترچه آزمایش‌ها
dependencies:
  mandatory: []
  optional: [pine-code-architecture, hypothesis-and-formula-engineering,
    research-methodology, overfitting-and-robustness, backtesting-science,
    asset-class-specialization, risk-management, intermarket-analysis,
    context-compression, research-to-code]
status: normalized
priority: 1
```

## Purpose

The project's single source of truth: manifest, registries
(architecture/modules/formulas/variables), known bugs, decisions,
dependencies, constraints, version history — the agent's memory across
sessions.

## Triggers

Select for: start of EVERY session on an existing project; after every
decision/change; citing backtest claims; reconstructing context without
re-reading all code.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Project state (code, decisions, results) | artifacts | project | yes |
| Session-start consistency data | registries | this skill's manifest | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| PROJECT-MANIFEST (12 canonical sections) | single source of truth | all stages |
| Consistency-check results | drift report | code-review-and-refactoring |
| Ledger citations for claims | evidence | research-methodology, Post-Verification |

## Rules

1. PROJECT-MANIFEST (one file, canonical sections): 1 Identity (project,
   pine_version 6, created/updated); 2 Architecture Registry (layers &
   responsibilities, data-flow, entry points); 3 Module Registry (module/
   role/inputs/outputs/deps/status); 4 Formula Registry (id, exact formula,
   version, formulations tested ≥2, validated/OOS, used-by); 5 Variable
   Dictionary (var, type, scope, meaning, unit, persistence, where
   set/read); 6 Signal Definitions (id, exact condition, close-confirmed
   semantics, consumer); 7 Decisions Log (ADR-style: date, decision,
   alternatives, why, consequence); 8 Known Bugs/Limitations (symptom,
   workaround, fixed-in); 9 Dependencies (library/symbol/data,
   version/ID, plan-gated, fallback); 10 Constraints (platform limits,
   cost model, sessions, risk policy); 11 Version History (version, date,
   change, validated-by); 12 Research Ledger (trial log: trial, hypothesis,
   verdict, data window, metrics).
2. Operating rules: WRITE-BEFORE-CODE — spec updates precede
   implementation changes; decisions are APPEND-ONLY (never rewrite
   history — record reversals as new rows); registries are the agent's
   memory across sessions — reconstruct context from the manifest, not
   from re-reading all code (pairs context-compression); every backtest
   claim in chat/docs must cite a ledger row (id + window + metrics).
3. Consistency checks (run on session start): formula registry ↔ code
   diff (drift = research-to-code violation or doc lag); constraints still
   true on the current plan (re-verify flags — mtf/multi-symbol/
   backtesting skills); open bugs still open; fixed-in rows reference real
   versions; trial-ledger K counted → adjust skepticism
   (overfitting-and-robustness).

## Workflow

1. Create/maintain the manifest with all 12 sections (rule 1).
2. Update the manifest BEFORE code changes (rule 2).
3. On session start, run the consistency checks (rule 3).
4. Cite ledger rows for every result claim (rule 2).

## Constraints

- No manifest drift (docs lag code → trust collapses; prefer code-as-truth
  and diff-fix docs immediately).
- No decisions recorded without consequences.
- No missing trial ledger (K unknowable → overfitting invisible).
- No stale dependency IDs (symbols/plans change — intermarket-analysis
  notes).

## Assumptions

- Manifest schema v1 — evolve via the Decisions Log (source-declared).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Docs lag code | registry ↔ code diff | rule 3: consistency check |
| Rewritten decisions | history altered | rule 2: append-only |
| Uncited backtest claim | no ledger row | rule 2: citation required |
| Unknowable K | no trial ledger | rule 1 §12: ledger mandatory |

## Dependencies

Optional: pine-code-architecture (architecture registry),
hypothesis-and-formula-engineering (formulation columns),
research-methodology (verdict vocabulary), overfitting-and-robustness
(trial ledger), backtesting-science / asset-class-specialization /
risk-management / intermarket-analysis (constraint sections),
context-compression (memory pairing), research-to-code (drift discipline).
Load only on their own triggers.

## Examples

- "Rebuild context for this project" → rule 1 manifest, not code re-read.
- "Log why we chose ATR-mult 2.5" → rule 1 §7 decisions row.
- Persian: «اطلاعات پروژه کجاست؟» → rule 1: the manifest.

## Verification Criteria

- Manifest exists with all 12 sections, updated before code.
- Decisions append-only with consequences.
- Session-start consistency checks recorded.
- All result claims cite ledger rows.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-008` import from
  `skills/incoming/73-project-knowledge-management.md`.
- Layer META (function = project memory / single-source-of-truth
  governance — mirrors the architecture's meta/project_memory.md
  component). The source's markdown manifest template preserved as rule
  prose (structure description, not code). Structural reorganization only;
  no semantic changes.

## Source Reference

- Original filename: `73-project-knowledge-management.md`
- Original source path: `skills/incoming/73-project-knowledge-management.md`
- Import batch: `batch-008`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-008)
