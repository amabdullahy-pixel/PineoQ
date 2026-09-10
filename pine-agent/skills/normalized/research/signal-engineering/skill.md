# Skill: signal-engineering

## Metadata

```yaml
id: signal-engineering
name: Signal Engineering
version: 1.0.0
path: skills/normalized/research/signal-engineering/skill.md
layer: RESEARCH
domains: [quant-methods, signal-design]
triggers:
  english:
    - signal lifecycle
    - noise filter cooldown
    - signal scoring threshold
    - multi-bar confirmation
    - confidence scoring
    - signal decay half-life
  persian:
    - مهندسی سیگنال
    - فیلتر نویز
    - تایید چند کندله
    - افت اعتبار سیگنال
dependencies:
  mandatory: []
  optional: [signal-fusion, tradingview-execution-model, mtf-engineering, adaptive-systems]
status: normalized
priority: 1
```

## Purpose

The full signal lifecycle — generation → filtering → weighting → scoring →
confirmation → confidence → decay — converting raw indicator events into
robust, execution-ready signals.

## Triggers

Select for: converting raw indicator events into exec-ready signals;
cooldown/storm prevention; confirmation design (bar-close, multi-bar, MTF);
confidence gating; stale-signal handling.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Signal requirement | description | formalization contract | yes |
| Factor set + weights | design facts | quantitative-analysis | yes |
| Half-life policy | parameter | user/formalization | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Pipeline design | implementation pattern | Implementation |
| Confirmation/decay code patterns | code patterns | Implementation |
| Confidence-gate requirements | verification checks | Pre/Post-Verification |

## Rules

1. Pipeline: Raw event → Noise filter → Normalize → Weight/Score → Confirm →
   Confidence → Decay → Output.
2. Generation & filtering: raw events = crossovers, structure breaks, zone
   touches (see TA/geometry skills); noise filters — min displacement
   (body > k·avgBody), session gates (see data-integrity), volatility floor
   (ATR percentile > p), event-rate limiter (≥N bars between same-direction
   events via `bar_index - lastEventBar > cooldown`).
3. Weighting & scoring: score = Σ wᵢ·normFactorᵢ (see
   quantitative-analysis); threshold on SCORE, not raw events; weights fixed
   per version — dynamic weights are adaptivity (see adaptive-systems) with
   an overfitting tax (see overfitting-and-robustness).
4. Confirmation: bar close via `event and barstate.isconfirmed` (see
   tradingview-execution-model) or evaluate on `[1]`; multi-bar confirmation —
   condition holds for K consecutive bars (ta.barssince pattern or counter
   var); MTF confirmation — HTF context agrees via the non-repaint pattern
   (see mtf-engineering).
5. Confidence scoring: confidence = normalized confluence count (see
   signal-fusion) + regime agreement (see regime-detection) + sample-verified
   stats (see statistical-testing) — NOT vibes; gate execution
   `if score > th and confidence > 0.6`.
6. Signal decay: stale signals lose edge — weight = exp(−λ·barsSinceTrigger),
   half-life = ln(2)/λ; drop signals entirely after 3× half-life; track decay
   sensitivity in testing.

## Workflow

1. Map the event source through the pipeline stages (rule 1) and pick filters
   (rule 2).
2. Score with fixed weights and explicit thresholds (rule 3).
3. Choose confirmation depth per repaint tolerance (rule 4).
4. Gate execution on score AND confidence (rule 5); wire decay (rule 6).

## Constraints

- No intrabar firing without close confirmation (repaint).
- No cooldown → signal storms; no binary confidence; staleness must be
  handled.

## Assumptions

- Pine idioms verified by the source vs reference.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Intrabar signal flips | no confirmation | rule 4: isconfirmed/[1] |
| Signal storms in chop | no cooldown | rule 2: rate limiter |
| Confidence as binary | all-or-nothing gating | rule 5: normalized confidence |
| Stale signals executed | no decay | rule 6: half-life + 3× drop |

## Dependencies

Optional: signal-fusion (confluence/confidence inputs),
tradingview-execution-model (confirmation semantics), mtf-engineering (HTF
confirmation), adaptive-systems (dynamic-threshold caveats). Load only on
their own triggers.

## Examples

- "Only fire on confirmed closes with 2-bar persistence" → rule 4.
- "My signal fires 30 times a session" → rule 2 cooldown.
- Persian: «سیگنال‌های قدیمی‌ام هنوز فعال‌اند» → rule 6 decay.

## Verification Criteria

- Every signal path passes through confirmation (close/multi-bar/MTF).
- Cooldown and displacement filters present.
- Execution gated on score AND normalized confidence.
- Decay policy documented (half-life, 3× drop).

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-005` import from `skills/incoming/45-signal-engineering.md`.
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `45-signal-engineering.md`
- Original source path: `skills/incoming/45-signal-engineering.md`
- Import batch: `batch-005`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-005)
