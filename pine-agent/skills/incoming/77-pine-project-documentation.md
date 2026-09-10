---
name: pine-project-documentation
category: Agent & Software Engineering
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/
---

# Pine Project Documentation

## Purpose
Deliverable-grade docs: system specification, formula documentation, variable
dictionary, signal definitions, architecture, changelog, version history.

## When to Use
- Every project handoff, publication, or archive point.

## Core Knowledge

### Documentation Set (per project)
1. **SYSTEM-SPEC.md** — what it does, non-goals, requirements trace (skill 72
   formal spec promoted), plan/constraints envelope.
2. **FORMULAS.md** — every formula: exact math, Pine line refs, alternative
   formulations tested, validation status (skills 63/62).
3. **VARIABLES.md** — variable dictionary: name/type/units/persistence/
   lifecycle (generated skeleton from skill 73 registry).
4. **SIGNALS.md** — each signal: exact condition, confirmation semantics
   (close-confirmed?), consumers (alerts/orders), known failure modes.
5. **ARCHITECTURE.md** — layers, module map, data flow, state machine diagram
   (text), dependency graph.
6. **CHANGELOG.md** — user-facing changes per version.
7. **VERSIONS.md** — technical version history + validation evidence per row.
8. **README.md** — 10-line quickstart: install, inputs, alerts, caveats.

### In-Code Documentation Standards
```pine
//@version=6
// ============================================================================
// PROJECT: <name> v<major.minor.patch> · MANIFEST: PROJECT-MANIFEST.md
// PURPOSE: <one line>
// SIGNALS: S1 <id> (close-confirmed) → entries; S2 …
// CAVEATS: plan-gated requests (list), repaint policy (none | by-design)
// ============================================================================
```
- Section banners (skill 68 layout); every magic number → input or constant
  with a comment stating UNITS.
- Every function header: purpose + params + return + side effects (none
  expected — if any, shout).

### Changelog Rules
- Format: `## [1.2.0] — 2026-09-15 · ADDED/CHANGED/FIXED/VALIDATED` rows.
- VALIDATED rows cite ledger trials (skill 73 §12) — no claim without evidence.
- Breaking signal-semantics changes require a major bump + migration note.

### Publication Checklist (TradingView script page)
- [ ] Repaint policy stated explicitly (skill 12 verdict).
- [ ] Plan requirements stated (requests/magnifier, skills 13/51).
- [ ] Default inputs = validated configuration (skill 53).
- [ ] No lookahead tricks (publication rules, skill 12).
- [ ] Formula doc matches code (skill 76 tier-check on each formula line).

### Doc Drift Control
- Docs updated in the SAME change-set as code (skill 73 write-before-code +
  consistency check).
- Golden-set regression rerun documented in VERSIONS on every release (skill 70).

## Common Mistakes
- Docs describing an older signal version (drift).
- Changelog without VALIDATED rows (claims without evidence).
- In-code comments in past tense or without units.
- Missing caveats section → users on free plans hit silent limits.

## Corrections & Updates
- [2026-09] Created; doc set + publication checklist formalized. This skill
  completes the 77-skill library (v1.0.0) — see PROJECT-MANIFEST pattern in
  skill 73 to register the library itself.
