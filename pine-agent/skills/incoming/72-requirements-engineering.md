---
name: requirements-engineering
category: Agent & Software Engineering
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/
---

# Requirements Engineering

## Purpose
Extracting requirements, detecting ambiguity, constraints, acceptance
criteria, formal specification, edge cases — BEFORE coding.

## When to Use
- Every user request that ends in code ("build me an indicator/strategy…").

## Core Knowledge

### Requirement Extraction Loop
```
User story → Clarify (ambiguity table, skill 64) → Constraints →
Acceptance criteria → Formal spec → Confirm → THEN build
```
- Every Pine term in the request gets a DEFINITION: "trend", "strong move",
  "confirm", "signal" — resolve via the ambiguity table or explicit defaults.

### Ambiguity Detection (must-resolve list)
- Timeframe(s)? Symbol scope? Session filter? Costs?
- Signal semantics: intrabar or close-confirmed? (skill 07/12)
- Entry/exit logic; position sizing (skill 31); pyramiding?
- Visualization: overlay/pane? dashboard? alerts needed? (skills 10/11)
- Strategy vs indicator intent (skill 08).
- Unstated risk rules (skill 30) — always ASK.

### Constraints Capture
- Platform: plan tier (requests, bar magnifier, LTF bars, alerts count —
  skills 13/15/51/11), Pine version (v6), limits (skill 69).
- Market/microstructure: asset class specifics (skill 58).
- Operator: attention/frequency limits (skill 61).

### Acceptance Criteria (testable or it didn't happen)
- Format: `GIVEN <context> WHEN <condition> THEN <observable outcome>`.
- Examples:
  - GIVEN BTCUSDT 1D 2019–2026 WHEN signal fires THEN alert at bar close
    (no intrabar).
  - GIVEN flat 20-bar window THEN no division error, output na (not 0).
  - GIVEN replay of pinned range THEN metrics match manifest (skill 73).

### Formal Specification (per script)
```
INPUTS:      typed list w/ defaults & ranges
STATE:       vars + transitions
SIGNALS:     exact boolean formulas (skill 64 form)
ORDERS:      entry/exit/sizing/exits (skill 09/33 semantics)
OUTPUTS:     plots/tables/alerts + update cadence
NON-GOALS:   explicitly excluded (prevents scope creep)
EDGE CASES:  enumerated + intended behavior each
```

### Edge-Case Sweep (mandatory list)
- First bars/warm-up · flat series · na volume symbols · session boundaries ·
  gap bars · 0-size arrays · max-history loops · HTF unconfirmed · all four
  barstate phases (skill 07).

## Common Mistakes
- Coding the literal words without resolving ambiguity (skill 64 echo-back).
- No acceptance criteria → "done" is unfalsifiable.
- Missing NON-GOALS → feature-creep spiral.
- Risk/session defaults invented silently.

## Corrections & Updates
- [2026-09] Created; Pine-specific defaults cross-linked.
