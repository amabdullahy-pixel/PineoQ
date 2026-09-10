---
name: code-review-and-refactoring
category: Agent & Software Engineering
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/repainting/
  - https://www.tradingview.com/pine-script-docs/writing/profiling-and-optimization/
---

# Code Review & Refactoring

## Purpose
Structured audits: mathematical correctness, logical correctness, repaint
audit, performance audit, refactoring, duplicate detection.

## When to Use
- Before publishing/deploying; when touching any existing script (yours or
  third-party).

## Core Knowledge

### Review Checklist (fixed order — data up, cosmetics down)
1. **API/version check** — every built-in verified vs reference (skill 76)?
2. **Math correctness** — formulas vs canon (RSI/ATR/ADX semantics,
   skill 35–37); units consistent (ticks vs price vs %, skill 09); precision
   hazards (skill 20).
3. **Logical correctness** — truth table of gates; De Morgan violations;
   and/or precedence; XOR confusion (skill 64); state machine transitions
   exhaustive?
4. **Repaint audit** — run the skill-12 checklist verbatim; report findings
   as: repaint-by-design / repaint-bug / clean.
5. **Performance audit** — profiler flames addressed? unbounded arrays?
   request budget? per-tick costs? (skill 69).
6. **Limits & guards** — drawings, plots, requests, na guards, warm-ups
   (skills 10/14).
7. **Duplicate detection** — same computation twice (incl. two ta.* calls
   doing the same thing at different call sites with drifted params).
8. **Architecture** — layering respected (skill 68)? magic numbers → inputs?
9. **Docs** — manifest/changelog updated (skills 73/77)?

### Refactoring Rules (behavior-preserving)
- One intent per change: extract-function, rename, or restructure — never mix
  with logic edits.
- Golden-set regression before/after every refactor (skill 70 testing).
- Signal-path changes = NOT refactoring — that's new research (skill 65 gate).
- Prefer deleting dead code over commenting it out.

### Third-Party Code Review Extras
- Check publication for lookahead tricks (skill 12) — publications with
  lookahead leaks violate TradingView rules.
- Verify claimed backtest stats can even exist: N, period, costs (skill 51).
- Imported libraries: pin versions; note plan-gated features used (skills 04/15).

### Verdict Format
```
REVIEW: {pass | pass-with-notes | fail} — findings: [numbered] — repaint: {clean|by-design|bug} — perf: {ok|budgeted|over}
```

## Common Mistakes
- Reviewing style before correctness (cosmetics last).
- "It compiles" as a review.
- Mixing refactor with behavior change.
- Accepting third-party stats without audit.

## Corrections & Updates
- [2026-09] Created; checklist order + verdict format formalized.
