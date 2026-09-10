# Skill: causal-reasoning

## Metadata

```yaml
id: causal-reasoning
name: Causal Reasoning
version: 1.0.0
path: skills/normalized/research/causal-reasoning/skill.md
layer: RESEARCH
domains: [research-methods, epistemics]
triggers:
  english:
    - correlation vs causation markets
    - granger causality
    - confounder spurious correlation
    - bradford hill criteria
    - reflexivity edge decay
    - causal claim discipline
  persian:
    - استدلال علّی
    - همبستگی و علیت
    - شبه‌همبستگی
dependencies:
  mandatory: []
  optional: [statistical-testing, overfitting-and-robustness,
    regime-detection, repainting-and-lookahead, intermarket-analysis,
    market-microstructure, research-methodology, market-psychology,
    backtesting-science]
status: normalized
priority: 2
```

## Purpose

Correlation vs causation, confounding, spurious correlation, causal
hypotheses, and the limits of causal claims in market data.

## Triggers

Select for: every "X causes Y" claim in research notes; every intermarket
filter design; Granger-style lead-lag studies; plausibility grading of
hypotheses.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Causal claim to examine | statement | research notes | yes |
| Data for lead-lag tests | series | intermarket/market data | conditional |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Evidence-graded hypothesis assessment | analysis | hypothesis-and-formula-engineering |
| Causal-language-corrected claims | documentation | research-methodology, pine-project-documentation |
| Confounder/conditioning design | method | regime-detection |

## Rules

1. Core distinctions: correlation = co-movement; causation = intervention
   would change the outcome. Spurious-correlation base rate: test N random
   series at α → P(≥1 false find) = 1−(1−α)^N → ~1 as N grows (data mining
   — statistical-testing / overfitting-and-robustness). Confounder Z
   drives both X and Y (e.g., BTC–Nasdaq correlation via global liquidity
   Z); when Z flips, the X→Y "link" vanishes — trade the Z-state, not the
   pair (regime conditioning — regime-detection).
2. Granger causality (predictive precedence, NOT causation): X
   Granger-causes Y if past X improves forecasts of Y beyond Y's own lags.
   Implementable sketch: nested rolling OLS — restricted (y on y-lags) vs
   unrestricted (+ x-lags); compare via F-test approximation or SSE
   reduction with preregistered thresholds (small-sample caution —
   statistical-testing). Limits: common drivers with different lags
   produce Granger "causation" with no structural link; nonlinearity
   breaks it; reflexive systems violate its assumptions.
3. Evidence grading (Bradford Hill, adapted to trading): strength (effect
   size) · consistency (across regimes/symbols — overfitting-and-robustness)
   · specificity (predicts what it claims, not everything) · temporality
   (signal at t from data ≤t, outcome t+h — the repaint law,
   repainting-and-lookahead) · dose–response (stronger signal → larger
   effect; test via signal buckets) · plausibility (a mechanism: flow,
   inventory, funding, liquidation mechanics) · coherence (fits known
   market structure — market-microstructure) · analogy (known relatives).
   Score hypotheses on these axes BEFORE backtesting; low-plausibility +
   high-backtest = data mining until proven otherwise.
4. Market-specific causal limits (assume always): no controlled
   experiments — observational only, everything conditional;
   non-stationarity — "causal" links decay with regimes (regime-detection);
   reflexivity — participants adapt; crowded signals alter the dynamics
   they exploit (edges self-destruct — monitor live vs backtest drift,
   backtesting-science; funding/positioning proxies — market-psychology);
   post-hoc narrative risk — story-after-data is storytelling
   (research-methodology preregistration is the antidote).
5. Language discipline: say "X predicts Y in-sample on Z universe,
   mechanism hypothesized: M" — NEVER "X causes Y" from backtests alone.

## Workflow

1. Restate the claim without causal language (rule 5).
2. Hunt confounders; condition on the Z-state (rule 1).
3. If lead-lag is claimed, run the Granger sketch with preregistered
   thresholds and respect its limits (rule 2).
4. Grade evidence on the Bradford Hill axes BEFORE backtesting (rule 3);
   respect the causal limits (rule 4).

## Constraints

- No intermarket filters built on raw correlation across regimes.
- No Granger results read as structural causation.
- No plausibility stories invented AFTER the backtest (preregister).
- No ignoring reflexivity in crowded signals.

## Assumptions

- Definitions verified vs encyclopedic/reference sources (Granger,
  Bradford Hill — source-declared provenance).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| "Causes" from backtest | causal language | rule 5: predictive phrasing |
| Confounder ignored | link flips with Z | rule 1: trade the Z-state |
| Story after data | HARKing | rule 4: preregister mechanism |
| Crowded edge decayed | live/backtest drift | rule 4: reflexivity monitor |

## Dependencies

Optional: statistical-testing (false-find math), overfitting-and-robustness
(consistency), regime-detection (conditioning), repainting-and-lookahead
(temporality), intermarket-analysis (pair designs), market-microstructure
(coherence), research-methodology (preregistration), market-psychology
(reflexivity proxies), backtesting-science (drift monitoring). Load only
on their own triggers.

## Examples

- "Does DXY cause gold moves?" → rules 1, 5: predictive phrasing + Z-state.
- "My lead-lag result looks causal" → rule 2 Granger limits.
- Persian: «آیا دلار علت رشد طلاست؟» → rule 5 language discipline.

## Verification Criteria

- No causal claims from observational backtests.
- Confounder analysis or conditioning present.
- Granger results labeled as predictive precedence only.
- Bradford Hill scoring recorded pre-backtest.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-007` import from `skills/incoming/67-causal-reasoning.md`.
- Granger/Bradford Hill recorded as academic provenance (encyclopedic
  sources); Pine sketch preserved as method description (no code
  generated). Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `67-causal-reasoning.md`
- Original source path: `skills/incoming/67-causal-reasoning.md`
- Import batch: `batch-007`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-007)
