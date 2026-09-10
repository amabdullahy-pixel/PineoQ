# Skill: falsification-and-counterexamples

## Metadata

```yaml
id: falsification-and-counterexamples
name: Falsification & Counterexamples
version: 1.0.0
path: skills/normalized/research/falsification-and-counterexamples/skill.md
layer: RESEARCH
domains: [research-methods, validation]
triggers:
  english:
    - counterexample hunt
    - kill criteria refuted
    - random signal control
    - simplification test
    - cost stress test
    - red team strategy
  persian:
    - ابطال فرضیه
    - مثال نقض
    - تست تخریب استراتژی
dependencies:
  mandatory: []
  optional: [liquidity-and-price-structure, data-integrity,
    monte-carlo-and-resampling, probability, regime-detection,
    asset-class-specialization, optimization-and-calibration,
    overfitting-and-robustness, backtesting-science, statistical-testing,
    pine-debugging-and-testing, repainting-and-lookahead,
    pine-performance-engineering]
status: normalized
priority: 1
```

## Purpose

The agent must DELIBERATELY try to destroy the idea before trusting it:
counterexamples, failure conditions, regime/symbol/parameter failures,
simplification tests — never optional, run between "backtest looks good"
and "this is valid".

## Triggers

Select for: between a good backtest and a validity claim; designing kill
criteria; pre-promotion stress testing; "prove my edge is real" demands.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Claim to falsify | hypothesis sheet | hypothesis-and-formula-engineering | yes |
| Trial ledger (K so far) | record | research-methodology | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Falsification battery results | verification data | Post-Verification |
| Kill-criteria list | preregistration fields | research-methodology |
| Refuted/verdict entries | ledger records | project memory |

## Rules

1. Falsification battery (run ALL; log each attempt + result):
   counterexample hunt — construct the bar sequence that breaks the rule:
   the gap-through-stop, the sweep that fakes the signal
   (liquidity-and-price-structure), the na window (data-integrity), the
   zero-volume bar; if you can't name the killer scenario, you haven't
   understood the rule. Failure conditions — enumerate explicit kill
   criteria PRE-trade: "refuted if OOS expectancy ≤ costs", "refuted if DD
   > X% in MC 95th" (monte-carlo-and-resampling), "refuted if correlation
   of votes > 0.8" (probability). Regime failures — run per regime bucket
   (regime-detection): a rule that wins only in one regime is a regime
   rule — gate it or reject it. Symbol failures — 5+ symbols; document
   WHERE it dies; symbols where it dies define the allowed universe (hard
   input — asset-class-specialization). Parameter failures — neighbors
   collapse? (optimization-and-calibration / overfitting-and-robustness
   plateau test). Simplification tests — strip components one by one:
   remove the filter → still works? (the filter may be the whole edge or
   noise); randomize the signal (same frequency, random direction) → if
   random matches the real rule's net result, THE EDGE IS THE COST MODEL,
   not logic; shuffle entry timing ±k bars → degradation curve tells how
   timing-sensitive. Cost stress — double commission+slippage: still
   positive? (backtesting-science). Trial-ledger audit — count K variants
   tried; adjust skepticism (multiple testing — statistical-testing /
   overfitting-and-robustness).
2. Verdict rules: any preregistered kill criterion hit → REFUTED (log; do
   not patch silently). "It still works after X" claims require the X-test
   to exist in the ledger. Surviving ALL battery items → PROMOTE to
   research-to-code stage 5.
3. Micro-red-team (code-level, pairs pine-code-review skill): feed
   degenerate inputs (0-length arrays, constant series, extreme values);
   repaint-probe: reload chart, compare signals before/after
   (repainting-and-lookahead); budget-probe: longest history × heaviest
   loop (pine-performance-engineering).

## Workflow

1. Preregister kill criteria before the battery (rule 1).
2. Run all battery items, logging every attempt (rule 1).
3. Apply verdict rules strictly (rule 2) — no silent patching.
4. Run the micro-red-team before promotion (rule 3).

## Constraints

- No testing only refutations you expect to win.
- No patching the rule after each failure until it fits (that's fitting
  the noise).
- No skipping the random-signal control (the cheapest, most revealing
  test).
- No missing ledger (survivorship of unlogged failures).

## Assumptions

- Battery formalized by the source (method provenance); random-control
  made mandatory by design.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Killer scenario unnameable | rule not understood | rule 1: counterexample hunt |
| Post-failure patching | rule drift | rule 2: REFUTED, restart |
| Random control skipped | untested cost edge | rule 1: mandatory control |
| Unlogged attempts | unknown K | rule 1: ledger audit |

## Dependencies

Optional: liquidity-and-price-structure (sweep counterexamples),
data-integrity (na/zero-volume), monte-carlo-and-resampling (DD criteria),
probability (vote correlation), regime-detection (regime buckets),
asset-class-specialization (symbol universe), optimization-and-calibration
+ overfitting-and-robustness (plateau), backtesting-science (cost stress),
statistical-testing (multiple testing), pine-debugging-and-testing
(degenerate inputs), repainting-and-lookahead (repaint-probe),
pine-performance-engineering (budget-probe). Load only on their own
triggers.

## Examples

- "Break my signal on purpose" → rule 1 full battery.
- "Is the edge just costs?" → rule 1 random-signal control.
- Persian: «چطور مطمئن شم لبه‌ام واقعیه؟» → rule 1 battery + rule 2
  verdict.

## Verification Criteria

- Kill criteria preregistered and all battery items attempted + logged.
- Random-signal control executed.
- Refuted items logged as constraints, not patched.
- Micro-red-team passed before promotion.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-007` import from
  `skills/incoming/66-falsification-and-counterexamples.md`.
- **The most cross-referenced pending skill in the registry** — its import
  resolves pending optional-dependency pointers from
  liquidity-and-price-structure, fibonacci-and-harmonic,
  advanced-market-geometry, macro-economics, regime-detection,
  asset-class-specialization (batches 005–006). Structural reorganization
  only; no semantic changes.

## Source Reference

- Original filename: `66-falsification-and-counterexamples.md`
- Original source path: `skills/incoming/66-falsification-and-counterexamples.md`
- Import batch: `batch-007`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-007)
