# Skill: statistical-testing

## Metadata

```yaml
id: statistical-testing
name: Statistical Testing
version: 1.0.0
path: skills/normalized/quant/statistical-testing/skill.md
layer: QUANT
domains: [statistics, hypothesis-testing]
triggers:
  english:
    - hypothesis testing
    - p-value
    - confidence interval
    - Wilson interval
    - t-test of mean
    - chi-square test
    - stationarity test
    - multiple testing
    - p-hacking
  persian:
    - آزمون فرض
    - ارزش p
    - بازه اطمینان
    - چندآزمونی
dependencies:
  mandatory: []
  optional: [statistical-distributions, overfitting-and-robustness, walk-forward-and-validation, probability]
status: normalized
priority: 2
```

## Purpose

Hypothesis testing, confidence intervals, p-values, significance, and
stationarity as practical in-Pine approximations (Pine has no built-in test
functions) — the discipline layer for deciding whether an edge is real or
noise, and for honest reporting of trial counts.

## Triggers

Select for: "is this edge real?" decisions; validating filters/parameters;
win-rate CI construction; multiple-backtest comparisons; stationarity
questions; any p-value/significance claim about results.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Claim to test | description | formalization contract | yes |
| Trade/observation sample | data | strategy results or series | yes |
| Pre-declared α | decision | user/agent policy | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Test design + statistic implementation | implementation pattern | Implementation |
| CI/p-value interpretation | verification output | Post-Verification |
| Multiple-testing discipline | reporting requirement | overfitting-and-robustness |

## Rules

1. Framework: H0 = "edge = 0 (results are noise)" vs H1 = "edge > 0";
   test statistic from the trade sample — mean profit, t = mean/(σ/√N);
   p-value = P(result at least this extreme | H0) — implement normal CDF (see
   statistical-distributions) for large N, t-tables for small N; α is a
   PRE-DECLARED false-positive budget (0.05 typical); never tune until
   p < α post hoc — that is p-hacking (multiple testing, see
   overfitting-and-robustness).
2. Confidence intervals: mean CI (large N) x̄ ± z·σ/√N (z = 1.96 for 95%);
   small N uses t critical values (df = N−1, precomputed table constants);
   win-rate proportion CI via the Wilson interval (more robust than naive) —
   implement with the standard formula; interpretation: if the CI for mean
   profit includes 0 → edge unproven.
3. Practical tests in Pine: t-test of mean trade ≠ 0 (manual; needs trade σ
   from an array of profits); chi-square comparing observed vs expected counts
   (statistic = Σ(O−E)²/E; compare to critical-value tables); informal
   stationarity — rolling mean/variance drift tests, e.g., ratio
   stdev(first half)/stdev(second half) far from 1 → non-stationary; the
   formal ADF test is NOT available — approximate via variance-ratio or
   Hurst-style checks (see time-series-analysis / stochastic-processes).
4. Multiple-testing discipline: testing K parameters → false-positive chance
   ≈ 1−(1−α)^K; countermeasures — out-of-sample split (see
   walk-forward-and-validation), Bonferroni (α/K), and honest reporting of
   the number of trials.

## Workflow

1. Declare H0/H1 and α BEFORE looking at results (rule 1).
2. Build the sample correctly (trade array, wins/n counts); choose test/CI
   form by N (rules 1–3).
3. Interpret: CI containing 0 or p ≥ α → not proven (rule 2).
4. Report trial counts and apply corrections (rule 4).

## Constraints

- No built-in hypothesis-test functions in Pine — all tests are manual
  approximations.
- p-values are never "the probability the hypothesis is true".

## Assumptions

- Large-N approximations (normal CDF) hold where used; serial correlation of
  trades must be considered (overlapping positions inflate effective N).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Win-rate CI from 15 trades quoted as proof | tiny N | rule 2: t/Wilson with honest width |
| Serial correlation ignored | overlapping positions | inflate-N guard; block methods |
| Post-hoc p<α tuning | parameter fishing | rule 1/4: pre-declared α, corrections |
| 100 backtests, best shown | selection bias | rule 4: Bonferroni / honest trials |

## Dependencies

Optional: statistical-distributions (CDF implementations),
overfitting-and-robustness (multiple-testing depth),
walk-forward-and-validation (OOS splits), probability (estimation basics).
Load only on their own triggers.

## Examples

- "Give me a 95% CI on my win rate" → rule 2 Wilson interval.
- "Is the strategy's mean trade significantly > 0?" → rules 1, 3 t-test.
- Persian: «چند بار بک‌تست گرفتم و بهترینش را برداشتم» → rule 4: multiple-testing
  discipline.

## Verification Criteria

- α declared before testing; trial counts reported honestly.
- CI method matches N (z vs t vs Wilson).
- Serial-correlation caveat present where positions overlap.
- No post-hoc p-value tuning anywhere in the workflow.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-003` import from `skills/incoming/25-statistical-testing.md`.
- Structural reorganization only; no semantic changes. The "no built-in test
  functions" and "ADF NOT available" negative claims preserved as
  verify-before-use gates per established convention.

## Source Reference

- Original filename: `25-statistical-testing.md`
- Original source path: `skills/incoming/25-statistical-testing.md`
- Import batch: `batch-003`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-003)
