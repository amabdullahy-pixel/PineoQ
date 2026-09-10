---
name: statistical-testing
category: Statistics & Probability
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/pine-script-docs/faq/functions/
---

# Statistical Testing

## Purpose
Hypothesis testing, CIs, p-values, significance, stationarity — as practical
in-Pine approximations (no built-in test functions).

## When to Use
- Deciding whether an edge is real or noise; validating filters/parameters.

## Core Knowledge

### Framework (applied to trading)
- H0: "edge = 0 (results are noise)" vs H1: "edge > 0".
- Test statistic from trade sample: mean profit, `t = mean/(σ/√N)`.
- p-value = P(result at least this extreme | H0) — implement normal CDF
  (skill 23) for large N; use t-tables for small N.
- α (significance) = pre-declared false-positive budget (0.05 typical).
- NEVER tune until p < α post hoc — that's p-hacking (multiple testing, skill 54).

### Confidence Intervals
- Mean CI (large N): `x̄ ± z·σ/√N` (z = 1.96 for 95%).
- Small N: use t critical values (df = N−1); precompute table constants.
- Proportion (win rate) CI (Wilson, more robust than naive):
```pine
wilson(int wins, int n, float z) =>
    float p = wins / float(n)
    float d = 1 + z*z/float(n)
    float c = (p + z*z/(2.0*n)) / d
    float h = z * math.sqrt(p*(1-p)/n + z*z/(4.0*n*n)) / d
    [c - h, c + h]
```
- Interpretation: if CI for mean profit includes 0 → edge unproven.

### Practical Tests in Pine
- t-test of mean trade ≠ 0 (manual; needs trade σ from array of profits).
- Chi-square: compare observed vs expected counts (e.g., distribution of
  weekday wins); statistic = Σ(O−E)²/E; compare to critical values table.
- Stationarity (informal, in-Pine): rolling mean/variance drift tests — e.g.,
  ratio of stdev(first half)/stdev(second half) far from 1 → non-stationary;
  ADF formal test NOT available — approximate via variance-ratio or
  Hurst-style checks (skill 26).

### Multiple Testing Discipline
- Testing K parameters → chance of false positive ≈ 1−(1−α)^K.
- Countermeasures: out-of-sample split (skill 53), Bonferroni (α/K), report
  the number of trials honestly.

## Common Mistakes
- Quoting win-rate CIs from 15 trades as "proven".
- Ignoring serial correlation of trades (overlapping positions inflate N).
- Treating p-value as "probability the hypothesis is true".
- Running 100 backtests and presenting the best without adjustment.

## Corrections & Updates
- [2026-09] Created; manual-test approach verified (Pine lacks built-in tests).
