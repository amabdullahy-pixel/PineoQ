# Skill: context-compression

## Metadata

```yaml
id: context-compression
name: Context Compression
version: 1.0.0
path: skills/normalized/meta/context-compression/skill.md
layer: META
domains: [knowledge-management, agent-operations]
triggers:
  english:
    - context compression ladder
    - change only reasoning
    - diff based context budget
    - state tuple compression
    - re-anchor golden set
    - handoff between sessions
  persian:
    - فشرده‌سازی زمینه
    - استدلال تغییرمحور
    - خلاصه‌سازی وضعیت
dependencies:
  mandatory: []
  optional: [project-knowledge-management, pine-code-architecture,
    pine-debugging-and-testing, requirements-engineering,
    backtesting-science, asset-class-specialization]
status: normalized
priority: 2
```

## Purpose

Summarizing context, compressing state, change-only reasoning, diff-based
context, module-level context, requirement compression — so the agent stays
effective on long projects and across session handoffs.

## Triggers

Select for: long sessions; handing work between sessions/agents; before big
analyses; context budget pressure.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Current task + its context need | task spec | user/planning | yes |
| Manifest sections | references | project-knowledge-management | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Compressed context (ladder level chosen) | working context | all stages |
| State tuple / summaries | compact state | Implementation |
| Open-questions list | surviving ambiguities | requirements-engineering |

## Rules

1. Compression ladder (lossy → lossless): FULL HISTORY → summary + manifest
   refs → diffs + registries → current state only. Prefer REFERENCES over
   copies — point to manifest sections (project-knowledge-management)
   instead of restating them. Lossless keeps: decisions log, trial ledger,
   active bug list, current acceptance criteria. Lossy drops: superseded
   drafts, rejected alternatives (their summary lives in Decisions).
2. State compression (stateful Pine work): express strategy state as a
   compact tuple — {trend, regime, position, openZoneIds, cooldownLeft} —
   not prose; zone/array state as counts + last-N summaries, not full
   dumps; note invariants ("zones always sorted; mitigated removed").
3. Change-only reasoning: on subsequent edits, reason over the DIFF, not
   the whole file — context = changed hunks + their dependencies; before
   editing, list the affected registry rows (variables/formulas the diff
   touches — project-knowledge-management) and re-verify only those; GUARD:
   after a diff-session, re-run the golden-set regression
   (pine-debugging-and-testing) — compressed reasoning must be RE-ANCHORED
   periodically.
4. Diff-based context (code): per-task context budget — 1 manifest:
   Identity + relevant registry rows ONLY; 2 target file: current version;
   3 diff: last change to target; 4 task spec: acceptance criteria +
   NON-GOALS.
5. Module-level context: work through module interfaces
   (pine-code-architecture) — given a module's role/inputs/outputs, its
   internals compress to a behavior contract; NEVER compress ACROSS the
   signal path while validating behavior — expand the full signal path,
   compress everything else.
6. Requirement compression: compress a user conversation into the formal
   spec (requirements-engineering) + open-questions list — the chat is
   disposable, the spec is not.

## Workflow

1. Choose the ladder level for the task (rule 1); keep lossless items.
2. Compress state to tuples/summaries with invariants (rule 2).
3. Reason over diffs; list affected registry rows first (rule 3).
4. Respect the context budget and signal-path expansion rules (rules 4–5);
   compress requirements into the spec (rule 6).

## Constraints

- Never compress away the Constraints section (plan/cost assumptions
  silently violated later — backtesting-science /
  asset-class-specialization).
- No summaries without dates/versions (staleness unverifiable).
- No change-only reasoning on repaint-critical paths without re-anchor.
- Never lose the OPEN-QUESTIONS list (ambiguities resurface as bugs).

## Assumptions

- Ladder + budget schema formalized for agent workflows (source-declared);
  consistent with the architecture's context-loading and token policies.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Constraints lost in compression | plan assumptions violated | constraint: keep Constraints |
| Undated summary | staleness unknown | rule 1: dates/versions mandatory |
| Drift after diff-work | golden-set mismatch | rule 3: re-anchor |
| Lost open questions | ambiguities resurface | rule 6: list survives |

## Dependencies

Optional: project-knowledge-management (references/registries),
pine-code-architecture (module interfaces),
pine-debugging-and-testing (re-anchor regressions),
requirements-engineering (spec compression), backtesting-science /
asset-class-specialization (constraint content). Load only on their own
triggers.

## Examples

- "Summarize where we are" → rule 1 ladder level 2 with manifest refs.
- "Apply this small fix" → rules 3–4 diff-based context budget.
- Persian: «جمع‌بندی کن برای جلسه بعد» → rules 1–6 handoff compression.

## Verification Criteria

- Lossless items retained (decisions, ledger, bugs, acceptance criteria).
- State expressed as tuples/summaries with invariants.
- Golden-set re-anchor performed after diff-sessions.
- Open-questions list survives every compression.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-008` import from `skills/incoming/74-context-compression.md`.
- Layer META (function = agent context economy — mirrors the
  architecture's meta/context_loading_policy.md and
  config/token_policy.yaml concerns; the skill aligns with the documented
  token-minimization policy without altering it). Structural
  reorganization only; no semantic changes.

## Source Reference

- Original filename: `74-context-compression.md`
- Original source path: `skills/incoming/74-context-compression.md`
- Import batch: `batch-008`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-008)
