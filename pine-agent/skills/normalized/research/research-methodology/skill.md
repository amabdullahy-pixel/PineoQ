# Skill: research-methodology

## Metadata

```yaml
id: research-methodology
name: Research Methodology
version: 1.0.0
path: skills/normalized/research/research-methodology/skill.md
layer: RESEARCH
domains: [research-methods, validation]
triggers:
  english:
    - scientific method trading
    - preregistration hypothesis
    - reproducibility seed pinning
    - HARKing metric shopping
    - verdict PASS FAIL INCONCLUSIVE
    - research loop
  persian:
    - روش‌شناسی پژوهش
    - فرضیه آزمون‌پذیر
    - تکرارپذیری
dependencies:
  mandatory: []
  optional: [walk-forward-and-validation, overfitting-and-robustness,
    falsification-and-counterexamples, monte-carlo-and-resampling,
    statistical-testing, pine-project-documentation]
status: normalized
priority: 1
```

## Purpose

The scientific loop — Hypothesis → Experiment → Measurement → Validation →
Falsification → Reproducibility — as the standard operating procedure for
every strategy idea.

## Triggers

Select for: EVERY new strategy/idea before coding; every "does this work?"
question; metric-shopping/preregistration audits; reproducibility disputes.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Idea to test | description | user/research | yes |
| Preregistration record | manifest entry | pine-project-documentation | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Preregistration block | manifest artifact | pine-project-documentation |
| Verdict (PASS/FAIL/INCONCLUSIVE) | contract field | Feasibility, Post-Verification |
| Refuted-hypothesis ledger entries | constraints | project memory |

## Rules

1. The pipeline (mandatory order): 1 HYPOTHESIS — falsifiable claim with
   metric + threshold + universe + period; 2 PREREGISTER — lock
   metrics/windows/thresholds BEFORE running (anti-HARKing); 3 EXPERIMENT —
   minimal implementation (research version, not production); 4 MEASUREMENT
   — ONLY the predeclared metrics (no metric shopping); 5 VALIDATION —
   OOS/walk-forward (walk-forward-and-validation), robustness battery
   (overfitting-and-robustness); 6 FALSIFICATION — deliberate kill attempts
   (falsification-and-counterexamples); 7 REPRODUCE — fixed seeds, pinned
   dates/params, rerun == same result; 8 LOG — verdict + data + code
   version into the project manifest (pine-project-documentation).
2. Preregistration discipline (Pine-adapted): before any backtest run,
   write in the manifest — exact entry/exit conditions and formula version;
   symbol(s), timeframe, pinned date range, plan-dependent caveats (Bar
   Magnifier availability changes fills — backtesting-science); primary
   metric + pass threshold (e.g., OOS expectancy > 2× costs, N ≥ 100). One
   OOS peek allowed; re-running with tweaks after peeking = refuted-or-
   restart.
3. Reproducibility standards: any randomness → const seed
   (monte-carlo-and-resampling); pin dates, parameter set, symbol IDs, plan
   assumptions (requests/magnifier); record script version with the result;
   same input → same output every reload — if not, find the nondeterminism
   (unseeded random, `timenow`, `varip`) before trusting anything.
4. Verdict vocabulary (no fuzzy claims): PASS (all preregistered criteria
   met OOS) · FAIL (any failed) · INCONCLUSIVE (insufficient N/data quality
   — state what's missing). Refuted ≠ deleted: refuted hypotheses are
   logged and become constraints ("do not retry without a NEW mechanism").

## Workflow

1. Write the falsifiable hypothesis and preregister it (rule 1–2).
2. Run the minimal experiment; measure ONLY predeclared metrics (rule 1).
3. Validate (rule 1 step 5) and falsify (rule 1 step 6).
4. Reproduce with pinned seeds/params (rule 3); log the verdict (rule 4).

## Constraints

- No metric shopping after seeing results (p-hacking —
  statistical-testing).
- "Promising" is not a verdict — run the loop to completion.
- Reproduce at least one refutation, not only the winner.
- Research code never ships as production code (research-to-code gates).

## Assumptions

- Pipeline formalized by the source; TradingView-specific caveats
  cross-linked to verified skills.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Metric changed post-hoc | no preregistration | rule 2: lock first |
| Vague verdict claimed | "promising" | rule 4: PASS/FAIL/INCONCLUSIVE |
| Result not reproducible | nondeterminism | rule 3: seed/pin hunt |
| Refuted idea silently retried | no ledger | rule 4: log as constraint |

## Dependencies

Optional: walk-forward-and-validation (OOS), overfitting-and-robustness
(robustness battery), falsification-and-counterexamples (kill attempts),
monte-carlo-and-resampling (seeding), statistical-testing (p-hacking),
pine-project-documentation (manifest/ledger). Load only on their own
triggers.

## Examples

- "Test whether my momentum idea works" → rule 1 full loop.
- "Why do I get different numbers on reload?" → rule 3 nondeterminism hunt.
- Persian: «چطور بفهمم ایده‌ام واقعا کار می‌کنه؟» → rule 1 loop.

## Verification Criteria

- Preregistration exists and predates the run.
- Only preregistered metrics reported.
- Reproduction (including one refutation) logged.
- Verdict uses the controlled vocabulary.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-007` import from `skills/incoming/62-research-methodology.md`.
- HARKing/preregistration concepts recorded as methodological provenance
  (open-science practice adapted to trading); Pine-specific caveats
  consistent with verified inventories. Structural reorganization only; no
  semantic changes.

## Source Reference

- Original filename: `62-research-methodology.md`
- Original source path: `skills/incoming/62-research-methodology.md`
- Import batch: `batch-007`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-007)
