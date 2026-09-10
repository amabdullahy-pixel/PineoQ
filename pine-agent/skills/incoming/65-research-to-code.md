---
name: research-to-code
category: Research & Modeling
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/language/
---

# Research to Code

## Purpose
The full bridge: Research → Concept → Formula → Algorithm → Pine-compatible
Model → Implementation → Validation.

## When to Use
- Moving any validated research idea into a production Pine artifact.

## Core Knowledge

### Stage Gates (each has an artifact + a test)
```
1. RESEARCH       artifact: hypothesis sheet (skill 63) — gate: mechanism named
2. CONCEPT        artifact: 5-line spec (what/when/where/why/risk)
3. FORMULA        artifact: math spec + ≥2 alternative formulations (skill 63)
4. ALGORITHM      artifact: pseudocode incl. state, warm-up, budget analysis
5. PINE MODEL     artifact: research-version script (hardcoded params, prints)
6. IMPLEMENTATION artifact: production script (inputs, architecture, skill 68)
7. VALIDATION     artifact: skill-62 loop results + repaint audit (skill 12)
```

### Algorithm Stage (before any Pine)
- State inventory: what persists across bars? (var/varip choice, skill 07).
- Complexity: per-bar cost O(?) — loops bounded? arrays trimmed? (skill 69).
- Warm-up: first valid bar index per series; gate logic on it (skill 26).
- Edge cases list: first bars, flat series, empty arrays, session edges (skill 20).

### Pine-Compatible Model (the translation step — where ideas die silently)
- Replace math ops with exact Pine semantics (float precision, skill 20).
- Conditional ta.* calls restructured to global computation (skill 01).
- HTF terms through the non-repaint pattern (skill 12/13) or marked as
  research-only-repainting.
- Window functions mapped to verified ta.* (skill 21) or manual loops with caps.

### Implementation Requirements
- Inputs for every preregistered parameter, defaults = preregistered values.
- No logic changes vs the validated model — diff the signal path line by line.
- Dashboard/labels optional; performance budget respected (skill 10/69).

### Validation Gate (production = research, provably)
- [ ] Signal path diff: zero unintended changes vs model.
- [ ] Repaint checklist clean (skill 12).
- [ ] Costs/caps/limits configured (skill 51).
- [ ] Same pinned period reproduces model metrics within tolerance.

## Common Mistakes
- Rewriting the signal during "productionization" (silent divergence).
- Skipping the algorithm stage → architecture bugs + timeouts (skill 69).
- Shipping research code with hardcoded params as final.
- Validating only visually on chart instead of metrics (skill 32).

## Corrections & Updates
- [2026-09] Created; stage gates formalized with cross-linked checks.
