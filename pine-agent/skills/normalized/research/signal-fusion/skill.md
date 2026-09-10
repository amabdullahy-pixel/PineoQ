# Skill: signal-fusion

## Metadata

```yaml
id: signal-fusion
name: Signal Fusion
version: 1.0.0
path: skills/normalized/research/signal-fusion/skill.md
layer: RESEARCH
domains: [quant-methods, signal-design]
triggers:
  english:
    - weighted voting signals
    - ensemble confluence
    - contradiction detection
    - hierarchical fusion veto
    - Bayesian fusion likelihood ratio
    - combine indicators signals
  persian:
    - تلفیق سیگنال‌ها
    - رأی‌گیری وزنی
    - تشخیص تناقض
    - تلفیق بیزی
dependencies:
  mandatory: []
  optional: [probability, quantitative-analysis, regime-detection, monte-carlo-and-resampling]
status: normalized
priority: 1
```

## Purpose

Combining multiple signals correctly: weighted voting, ensembles, confluence,
contradiction detection, hierarchical and Bayesian fusion — for any
multi-indicator/multi-condition decision point.

## Triggers

Select for: any multi-indicator decision point; "combine my 5 indicators"
requests; contradiction policy design; hierarchical veto architectures;
Bayesian confidence from trade history.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Signals to fuse | list | formalization contract | yes |
| Labeled outcomes (for Bayesian LRs) | data | trade history | conditional |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Fusion architecture design | design decision | Implementation |
| Contradiction table | design artifact | Implementation Planning |
| Confidence output | contract field | signal-engineering |

## Rules

1. Weighted voting: vote = Σ wᵢ·voteᵢ with ∈ {−1, 0, +1} family votes
   (trend/momentum/volume examples); `longVote = vote >= longThreshold`;
   votes must be INDEPENDENT-ish (distinct families — see probability);
   correlated voters = hidden double-weighting; cap total voters (3–6).
2. Confluence (zone-based, not event-based): confluence = independent
   evidence pointing at the same PRICE AREA (fib level + structure zone +
   VWAP band within tolerance — see fibonacci-and-harmonic); score by
   DISTINCT families; require spatial AND temporal alignment.
3. Contradiction detection: explicit conflict rules — momentum long while
   structure bear → NEUTRAL, not "average"; conflict = information (widen
   stop assumption or stand down); the contradiction table {trend, momentum,
   volume, regime} is enumerated at DESIGN TIME, not discovered live.
4. Hierarchical fusion: Layer 1 regime gate (hard filter — see
   regime-detection; no trade if wrong regime); Layer 2 strategy/structure
   bias; Layer 3 trigger/timing; higher layers VETO; lower layers never
   override higher layers.
5. Bayesian fusion (probability space — see probability): posterior odds =
   prior odds × Π likelihood ratios (ONLY independent evidence);
   lr = p(cond|win)/p(cond|loss) estimated from trade history; confidence =
   odds/(1+odds); estimate LRs from ≥100 labeled historical events (outcome
   arrays — see monte-carlo-and-resampling); correlated evidence breaks the
   multiplication.

## Workflow

1. Enumerate voters; verify family independence (rule 1).
2. Decide event-voting vs zone-confluence per signal type (rules 1–2).
3. Write the contradiction table at design time (rule 3).
4. Layer the architecture with veto direction (rule 4); Bayesian confidence
   only with sufficient labeled history (rule 5).

## Constraints

- No OR-ing weak conditions ("any of 5 triggers").
- No correlated votes; no Bayesian math on tiny samples.
- Contradiction policy is mandatory — mixed signals never executed by default.

## Assumptions

- Fusion patterns verified by the source vs quant sources/reference; Bayes
  independence requirements as per probability.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| RSI+Stoch+CCI votes | momentum³ | rule 1: distinct families |
| OR-chain triggers | weak conditions pass | constraint: structured fusion |
| Contradictory signals executed | no policy | rule 3: design-time table |
| Bayesian on tiny samples | overconfident LRs | rule 5: ≥100 events |

## Dependencies

Optional: probability (independence/Bayes foundations),
quantitative-analysis (normalized factors), regime-detection (Layer-1 gate),
monte-carlo-and-resampling (outcome arrays). Load only on their own triggers.

## Examples

- "Fuse trend + momentum + volume into one gate" → rules 1, 3.
- "Regime must veto everything" → rule 4 hierarchy.
- Persian: «پنج اندیکاتورم همدیگر را نقض می‌کنند» → rule 3 contradiction table.

## Verification Criteria

- Voter independence verified; voter count ≤ 6.
- Contradiction table exists and is enforced in code.
- Hierarchy vetoes implemented top-down.
- Bayesian confidence only from ≥100 labeled events with independence check.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-005` import from `skills/incoming/46-signal-fusion.md`.
- Resolves the pending optional-dependency pointers from probability
  (batch-003) and quantitative-analysis (same batch). Structural
  reorganization only; no semantic changes.

## Source Reference

- Original filename: `46-signal-fusion.md`
- Original source path: `skills/incoming/46-signal-fusion.md`
- Import batch: `batch-005`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-005)
