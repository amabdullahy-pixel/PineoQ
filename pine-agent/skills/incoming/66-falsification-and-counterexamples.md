---
name: falsification-and-counterexamples
category: Research & Modeling
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://robotwealth.com/back-basics-part-3-backtesting-algorithmic-trading/
---

# Falsification & Counterexamples

## Purpose
The agent must DELIBERATELY try to destroy the idea before trusting it:
counterexamples, failure conditions, regime/symbol/parameter failures,
simplification tests.

## When to Use
- Between "backtest looks good" and "this is valid". Never optional.

## Core Knowledge

### Falsification Battery (run all; log each attempt + result)
1. **Counterexample hunt** — construct the bar sequence that breaks the rule:
   the gap-through-stop, the sweep that fakes the signal (skill 41), the na
   window, the zero-volume bar (skill 14). If you can't name the killer
   scenario, you haven't understood the rule.
2. **Failure conditions** — enumerate explicit kill criteria PRE-trade:
   "refuted if OOS expectancy ≤ costs", "refuted if DD > X% in MC 95th"
   (skill 28), "refuted if correlation of votes > 0.8" (skill 22).
3. **Regime failures** — run per regime bucket (skill 47): a rule that wins
   only in one regime is a regime rule — gate it or reject it.
4. **Symbol failures** — 5+ symbols; document WHERE it dies; symbols where it
   dies define the allowed universe (hard input, skill 58).
5. **Parameter failures** — neighbors collapse? (skill 52/54 plateau test).
6. **Simplification tests** — strip components one by one:
   - Remove the filter → still works? The filter may be the whole edge (or noise).
   - Randomize the signal (same frequency, random direction) → if random
     matches the real rule's net result, the EDGE IS THE COST MODEL, not logic.
   - Shuffle entry timing ±k bars → degradation curve tells how timing-sensitive.
7. **Cost stress** — double commission+slippage: still positive? (skill 51).
8. **Trial-ledger audit** — count K variants tried so far; adjust skepticism
   (multiple testing, skill 25/54).

### Verdict Rules
- Any preregistered kill criterion hit → REFUTED (log, do not patch silently).
- "It still works after X" claims require the X-test to exist in the ledger.
- Surviving ALL battery items → PROMOTE to skill-65 stage 5.

### Micro-Red-Team (code-level, pairs skill 71)
- Feed degenerate inputs (0-length arrays, constant series, extreme values).
- Repaint-probe: reload chart, compare signals before/after (skill 12).
- Budget-probe: longest history × heaviest loop (skill 69).

## Common Mistakes
- Testing only refutations you expect to win.
- Patching the rule after each failure until it fits (that's fitting the noise).
- Skipping the random-signal control (the cheapest, most revealing test).
- No ledger → survivorship of unlogged failures.

## Corrections & Updates
- [2026-09] Created; battery formalized; random-control made mandatory.
