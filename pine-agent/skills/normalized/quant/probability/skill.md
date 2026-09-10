# Skill: probability

## Metadata

```yaml
id: probability
name: Probability
version: 1.0.0
path: skills/normalized/quant/probability/skill.md
layer: QUANT
domains: [statistics, decision-theory]
triggers:
  english:
    - conditional probability
    - expected value EV
    - joint probability independence
    - Bayes updating
    - likelihood ratio
    - base rate
    - signal confidence
  persian:
    - احتمال شرطی
    - ارزش مورد انتظار
    - به‌روزرسانی بیزی
    - نرخ پایه
dependencies:
  mandatory: []
  optional: [statistical-testing, signal-fusion, performance-metrics, statistics-core]
status: normalized
priority: 2
```

## Purpose

Probability theory applied to trading logic — conditional probability,
expected value, joint events, and Bayes updating as empirically estimable
in-Pine patterns (counting with `var` accumulators, odds-form updating).

## Triggers

Select for: signal-confidence scoring; win-rate reasoning; multi-condition
filtering; belief updating from new evidence; "multiply the probabilities"
reasoning that needs an independence check.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Probability question / scoring design | description | formalization contract | yes |
| Event definitions (A, B, evidence) | design facts | formalization contract | yes |
| Sample size available | context | data characteristics | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Estimator design (counts, EV, Bayes) | implementation pattern | Implementation |
| Independence/sample-size warnings | warnings | Pre-Verification |
| EV decision rule | design decision | Implementation Planning |

## Rules

1. Conditional probability: P(A|B) = P(A∩B)/P(B), P(B) > 0 — estimate
   empirically from history by tracking joint event counts with `var int`
   accumulators over a rolling or lifetime window; guard P(B)=0 → na.
2. Expected value: EV = Σ pᵢ·xᵢ; trade EV = winRate·avgWin −
   (1−winRate)·avgLoss; conditional expectation = average of x where
   condition held (accumulate sum & count inside `if cond`); decision rule —
   take setups only when EV > costs (commission+slippage share).
3. Joint probability & independence: P(A∩B) = P(A)·P(B) ONLY if independent —
   correlated indicators do NOT give multiplicative confidence; overlapping
   conditions inflate naive scores; P(A∪B) = P(A)+P(B)−P(A∩B); for signal
   fusion prefer empirical joint frequencies over independence assumptions.
4. Bayes theorem (belief updating): P(H|E) = P(E|H)·P(H)/P(E); odds form —
   posteriorOdds = priorOdds × likelihoodRatio (lr = p(E|win)/p(E|loss)
   estimated from trade history), posterior = odds/(1+odds); multiple
   independent evidence pieces multiply their likelihood ratios — VERIFY
   independence first.
5. Distributions link: discrete trade outcomes → empirical distribution in
   arrays; theoretical fits (normal/lognormal/t) only as approximations.

## Workflow

1. Define events precisely; estimate via counting accumulators (rule 1).
2. Apply the EV decision rule with explicit costs (rule 2).
3. Check independence before any multiplicative confidence or multi-evidence
   Bayes (rules 3–4).
4. Enforce minimum sample size — report na below it (see Failure Cases).

## Constraints

- No probability estimates from tiny samples; no silent independence
  assumptions.
- Theoretical distributions are approximations only — validate against the
  empirical distribution first.

## Assumptions

- Counting-based estimators converge toward true probabilities as samples
  grow; stationarity of the estimated process is assumed per window.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Correlated indicators multiplied | fake confidence boost | rule 3: empirical joint frequencies |
| <30 events sample | unstable estimate | report na instead |
| Base rate ignored | rare-condition filter mostly wrong | rule 4: priors mandatory |
| Correlated evidence double-counted | overconfident posterior | rule 4: verify independence |

## Dependencies

Optional: statistical-testing (CIs on estimates), signal-fusion (fusion
architectures), performance-metrics (win/loss inputs), statistics-core
(empirical distribution summaries). Load only on their own triggers.

## Examples

- "How often does my long signal work when the trend filter is on?" → rule 1
  conditional counting.
- "Combine three indicator votes" → rule 3: no naive multiplication; empirical
  joint frequencies (see signal-fusion).
- Persian: «اعتماد به سیگنالم را چطور حساب کنم؟» → rules 1–4 with base rates.

## Verification Criteria

- All probability estimates have sample-size guards.
- Independence is verified or empirical joint frequencies used.
- EV thresholds include explicit cost terms.
- Priors (base rates) present in any Bayesian update.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-003` import from `skills/incoming/22-probability.md`.
- Structural reorganization only; no semantic changes. Source's Pine counting
  patterns are consistent with pine-language-core (batch-001) var semantics.

## Source Reference

- Original filename: `22-probability.md`
- Original source path: `skills/incoming/22-probability.md`
- Import batch: `batch-003`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-003)
