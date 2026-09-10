---
name: context-compression
category: Agent & Software Engineering
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/
---

# Context Compression

## Purpose
Summarizing context, compressing state, change-only reasoning, diff-based
context, module-level context, requirement compression — so the agent stays
effective on long projects.

## When to Use
- Long sessions; handing work between sessions/agents; before big analysis.

## Core Knowledge

### Compression Ladder (lossy → lossless)
```
FULL HISTORY → summary + manifest refs → diffs + registries → current state only
```
- Prefer REFERENCES over copies: point to manifest sections (skill 73) instead
  of restating them.
- Lossless keeps: decisions log, trial ledger, active bug list, current
  acceptance criteria. Lossy drops: superseded drafts, rejected alternatives
  (their summary lives in Decisions).

### State Compression (for stateful Pine work)
- Express strategy state as a compact tuple: {trend, regime, position,
  openZoneIds, cooldownLeft} — not prose.
- Zone/array state: counts + last-N summaries, not full dumps; note
  invariants ("zones always sorted; mitigated removed").

### Change-Only Reasoning
- On subsequent edits, reason over the DIFF, not the whole file: context =
  changed hunks + their dependencies.
- Before editing: list affected registry rows (skill 73) — variables/formulas
  the diff touches; re-verify only those.
- Guard: after a diff-session, re-run the golden-set regression (skill 70) —
  compressed reasoning must be RE-ANCHORED periodically.

### Diff-Based Context (code)
```
CONTEXT BUDGET PER TASK:
1. manifest: Identity + relevant registry rows ONLY
2. target file: current version
3. diff: last change to target
4. task spec: acceptance criteria + NON-GOALS
```

### Module-Level Context
- Work through module interfaces (skill 68): given module role/inputs/outputs,
  its internals can be summarized to behavior contract.
- Never compress ACROSS the signal path while validating behavior — expand
  the full signal path, compress everything else.

### Requirement Compression
- Compress a user conversation into the formal spec (skill 72) + open
  questions list; the chat is disposable, the spec is not.

## Common Mistakes
- Compressing away the Constraints section (plan/cost assumptions silently
  violated later — skills 51/58).
- Summaries without dates/versions (can't re-verify staleness).
- Change-only reasoning applied to repaint-critical paths without re-anchor.
- Losing the OPEN-QUESTIONS list (ambiguities resurface as bugs).

## Corrections & Updates
- [2026-09] Created; ladder + budget schema formalized for agent workflows.
