---
name: research-methodology
category: Research & Modeling
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://robotwealth.com/back-basics-part-3-backtesting-algorithmic-trading/
  - https://www.quantstart.com/articles/Successful-Backtesting-of-Algorithmic-Trading-Strategies-Part-I/
---

# Research Methodology

## Purpose
The scientific loop: Hypothesis → Experiment → Measurement → Validation →
Falsification → Reproducibility — as the agent's standard operating procedure.

## When to Use
- EVERY new strategy/idea before coding; every "does this work?" question.

## Core Knowledge

### The Pipeline (mandatory order)
```
1. HYPOTHESIS   — falsifiable claim with metric + threshold + universe + period
2. PREREGISTER  — lock metrics/windows/thresholds BEFORE running (anti-HARKing)
3. EXPERIMENT   — minimal implementation (research version, not production)
4. MEASUREMENT  — ONLY the predeclared metrics (no metric shopping)
5. VALIDATION   — OOS/walk-forward (skill 53); robustness battery (skill 54)
6. FALSIFICATION— deliberate kill attempts (skill 66)
7. REPRODUCE    — fixed seeds, pinned dates/params, rerun == same result
8. LOG          — verdict + data + code version into project manifest (skill 73)
```

### Preregistration Discipline (Pine-adapted)
Before any backtest run, write in the manifest (skill 73):
- Exact entry/exit conditions and the formula version.
- Symbol(s), timeframe, pinned date range, and plan-dependent caveats (bar
  magnifier availability changes fills, skill 51).
- Primary metric + pass threshold (e.g., OOS expectancy > 2× costs, N ≥ 100).
- One OOS peek allowed. Re-running with tweaks after peeking = refuted-or-restart.

### Reproducibility Standards
- Any randomness → const seed (math.random seed, skill 28).
- Pin: dates, parameter set, symbol IDs, plan assumptions (requests/magnifier).
- Record script version (v1.0.0-style, frontmatter) with the result.
- Same input → same output, every reload. If not, find the nondeterminism
  (unseeded random, timenow, varip) before trusting anything.

### Verdict Vocabulary (no fuzzy claims)
- PASS (all preregistered criteria met OOS) · FAIL (any failed) ·
  INCONCLUSIVE (insufficient N/data quality — state what's missing).
- Refuted ≠ deleted: refuted hypotheses are logged and become constraints
  ("do not retry without a NEW mechanism").

## Common Mistakes
- Metric shopping after seeing results (p-hacking, skill 25).
- "Promising" as a verdict — it isn't one; run the loop to completion.
- Reproducing only the winner; reproduce at least one refutation too.
- Research code shipped as production code (research → production = skill 65).

## Corrections & Updates
- [2026-09] Created; pipeline formalized; TV-specific caveats cross-linked.
