# Skill: hypothesis-and-formula-engineering

## Metadata

```yaml
id: hypothesis-and-formula-engineering
name: Hypothesis & Formula Engineering
version: 1.0.0
path: skills/normalized/research/hypothesis-and-formula-engineering/skill.md
layer: RESEARCH
domains: [research-methods, signal-design]
triggers:
  english:
    - falsifiable trading hypothesis
    - formula derivation
    - alternative formulations artifact guard
    - assumption failure mapping
    - mechanism class
    - dimension check ATR scaled
  persian:
    - مهندسی فرضیه
    - فرمول‌سازی
    - فرمول‌های جایگزین
dependencies:
  mandatory: []
  optional: [statistics-core, adaptive-systems, time-series-analysis,
    regime-detection, probability, backtesting-science,
    market-microstructure]
status: normalized
priority: 1
```

## Purpose

Generating testable hypotheses, deriving formulas, producing alternative
formulations, and analyzing assumptions — converting an intuition into a
formal, testable model.

## Triggers

Select for: converting an intuition/observation into a testable model;
designing falsifiable hypotheses; formula derivation and dimension checks;
anti-artifact (alternative formulation) analysis.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Intuition/observation | description | user/research | yes |
| Cost model | parameters | backtesting-science | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Hypothesis sheet (all slots filled) | formalization artifact | research-methodology, formalization contract |
| Formula + ≥2 alternative formulations | math spec | research-to-code |
| Assumption → failure mapping table | risk record | Pre-Verification |

## Rules

1. Hypothesis template (fill ALL slots or it's not a hypothesis):
   HYPOTHESIS (mechanism sentence: WHY should this predict returns?);
   SIGNAL (exact formula(s)); UNIVERSE (symbol(s)/class); TIMEFRAME;
   PERIOD (pinned dates); COSTS (commission+slippage model); METRIC
   (primary); THRESHOLD (pass value); NEGATION (the observation that
   refutes it); MECHANISM CLASS (microstructure / behavioral / flow /
   carry / momentum...). Weak: "momentum works". Strong: "20-bar ROC
   z-score > 1 predicts h-bar forward return on BTCUSDT 1D 2019–2026, net
   5bps+2bps; threshold: OOS expectancy > 2× costs, N ≥ 100; refuted if
   OOS ≤ 0."
2. Formula generation: from mechanism → math — define state (x),
   normalization (statistics-core), threshold family (fixed / percentile /
   regime-conditional — adaptive-systems), horizon h. Dimension check:
   every term unitless or ATR-scaled; no raw-price additions across
   regimes (stationarity — time-series-analysis). Cost-aware by
   construction: expected gross edge must plausibly exceed round-trip
   costs BEFORE testing (killing ideas cheaply).
3. Alternative formulations (anti-artifact guard — mandatory ≥3): test the
   SAME concept in structurally different math — momentum: (a) ROC
   (b) z-scored ROC (c) percentrank of ROC; reversion: (a) z of
   price-to-VWAP (b) ATR distance (c) BB %B. Verdict rule: only if ≥2
   formulations survive OOS → real phenomenon; one survivor = likely
   formula artifact.
4. Assumption analysis (each → failure mapping): fills at assumed price →
   gaps/illiquidity → inflated P&L (strategy-engine / backtesting-science);
   costs constant → spread widens in stress → regime losses; stationarity
   → regime shift → param decay (regime-detection); independence of
   signals → correlation spikes → fused confidence fake (probability);
   liquidity capacity → size grows → impact costs (market-microstructure).

## Workflow

1. Fill every template slot; name the mechanism BEFORE any formula (rule 1).
2. Derive the formula with dimension + cost checks (rule 2).
3. Build ≥3 alternative formulations (rule 3).
4. Map each assumption to its failure mode (rule 4); preregister per
   research-methodology.

## Constraints

- No formula-first/mechanism-never designs (cannot falsify meaningfully).
- No single-formulation testing (artifact risk).
- No thresholds chosen after seeing the distribution (preregister).

## Assumptions

- Template + formulation rule formalized by the source (method provenance).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| No WHY | mechanism missing | rule 1: template refuses |
| One formulation | artifact risk | rule 3: ≥3 mandatory |
| Post-hoc threshold | preregistration absent | rule 1/2: lock first |
| Implicit assumptions | no failure map | rule 4: table required |

## Dependencies

Optional: statistics-core (normalization), adaptive-systems (threshold
families), time-series-analysis (stationarity), regime-detection (regime
conditioning), probability (independence), backtesting-science (cost
model), market-microstructure (capacity). Load only on their own triggers.

## Examples

- "I think volume precedes moves in crypto" → rule 1 template → rule 3
  formulations.
- "Is my threshold arbitrary?" → rule 2 dimension/family check.
- Persian: «حدس‌وگمانم رو چطور تست‌پذیر کنم؟» → rule 1 template.

## Verification Criteria

- All template slots filled; mechanism class named.
- ≥3 alternative formulations documented with OOS survival counts.
- Assumption-to-failure table present.
- Cost-awareness demonstrated before testing.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-007` import from
  `skills/incoming/63-hypothesis-and-formula-engineering.md`.
- Resolves the batch-006 parked candidate {57↔63} (market-microstructure ↔
  hypothesis-and-formula-engineering: complementary — cost/capacity
  assumptions consumed here, action dependency_relationship). Structural
  reorganization only; no semantic changes.

## Source Reference

- Original filename: `63-hypothesis-and-formula-engineering.md`
- Original source path: `skills/incoming/63-hypothesis-and-formula-engineering.md`
- Import batch: `batch-007`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-007)
