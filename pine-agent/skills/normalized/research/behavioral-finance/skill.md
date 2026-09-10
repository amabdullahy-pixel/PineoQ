# Skill: behavioral-finance

## Metadata

```yaml
id: behavioral-finance
name: Behavioral Finance
version: 1.0.0
path: skills/normalized/research/behavioral-finance/skill.md
layer: RESEARCH
domains: [behavioral, market-context]
triggers:
  english:
    - loss aversion disposition effect
    - herding anchoring recency bias
    - behavioral market signature
    - contrarian filter design
    - funding rate sentiment
  persian:
    - رفتارشناسی بازار
    - سوگیری‌های رفتاری
    - اثر واگذاری
dependencies:
  mandatory: []
  optional: [market-psychology, liquidity-and-price-structure,
    quantitative-analysis, walk-forward-and-validation, trade-management,
    performance-metrics, volume-analysis]
status: normalized
priority: 2
```

## Purpose

Loss aversion, herding, anchoring, recency/confirmation bias, disposition
effect — definitions AND their measurable market-behavior consequences.

## Triggers

Select for: explaining price behavior via crowd bias; designing contrarian
filters; auditing one's own trade data for bias contamination; sentiment
proxy validation.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Bias/behavior question | description | formalization contract | yes |
| Own trade history (for audits) | data | strategy trades | conditional |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Bias → signature → proxy mapping | analysis | Implementation |
| Disposition-effect audit result | verification data | Post-Verification |
| Contrarian filter requirements | design input | signal-engineering |

## Rules

1. Bias → market signature map (contextual, evidence-required — never
   mechanical rules): loss aversion (loss pain ≈ 2× gain pleasure,
   Kahneman–Tversky) → stops just beyond obvious levels → liquidity sweeps
   (liquidity-and-price-structure); herding → trends overshoot, bubbles →
   momentum percentile extremes (quantitative-analysis); anchoring → round
   numbers, ATH magnet → round-level + ATH distance; recency → late-cycle
   overconfidence → long-streak + rising RVOL; confirmation bias →
   one-sided flows → funding/PCR extremes; disposition effect (sell winners
   early, hold losers) → winners clipped, losers drift → short avg win vs
   avg loss ratio (performance-metrics); FOMO → late-chase volume spikes →
   RVOL > 2–3 on extension (volume-analysis); capitulation → volume flush +
   huge wick + reversal → capitulation proxy (market-psychology).
2. Design implications: expect systematic early-exit bias in manually
   judged systems → mechanize exits (trade-management); run a
   disposition-effect audit on YOUR trades — compare avgWin vs avgLoss and
   holding-time asymmetry from `strategy.closedtrades` (performance-metrics
   / monte-carlo-and-resampling) — asymmetry beyond design intent = bias
   contamination; contrarian filters fade EXTREME one-sidedness only
   (funding/PCR/vol percentile extremes), never mild readings — mid-range
   "sentiment" is noise.
3. Measurement discipline: sentiment proxies are regime-dependent/noisy —
   validate predictive value before use: IC-style test
   (quantitative-analysis) on the proxy vs forward returns, OOS
   (walk-forward-and-validation).

## Workflow

1. Map the behavioral question to a signature and a measurable proxy
   (rule 1).
2. If auditing own trades: run the disposition audit (rule 2).
3. Design contrarian context as a FILTER (rule 2), validated (rule 3).

## Constraints

- No bias narratives as mechanical rules ("everyone's fearful = buy").
- No sentiment extremes as timing signals — context filters only.
- No ignoring disposition contamination in one's own trade data.

## Assumptions

- Definitions verified vs CFA Institute / Decision Lab (source-declared);
  proxy table vs TradingView support article (funding rate).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| "Fearful = buy" rule | narrative as logic | rule 1: evidence-required |
| Mid-range sentiment traded | noise | rule 2: extremes only |
| Own bias unnoticed | no audit | rule 2: disposition audit |
| Unvalidated proxy | no IC test | rule 3: validate first |

## Dependencies

Optional: market-psychology (proxies), liquidity-and-price-structure
(sweep signatures), quantitative-analysis (IC validation),
walk-forward-and-validation (OOS), trade-management (mechanized exits),
performance-metrics (avgWin/avgLoss), volume-analysis (RVOL). Load only on
their own triggers.

## Examples

- "Why do my stops keep getting run?" → rule 1 loss-aversion signature.
- "Am I cutting winners early?" → rule 2 disposition audit.
- Persian: «چرا زود می‌فروشم و دیر می‌خرم؟» → rule 2 disposition audit.

## Verification Criteria

- Proxies validated (IC/OOS) before strategy use.
- Contrarian logic acts on extremes only.
- Own-trade disposition audit recorded.
- No mechanical bias narratives in logic.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-006` import from `skills/incoming/59-behavioral-finance.md`.
- Definitions recorded as academic-source provenance (CFA Institute /
  Decision Lab), proxy table vs TradingView support article — preserved as
  source-declared provenance, not TradingView documentation authority.
- Note: a mojibake artifact in the normalized file's Persian trigger list
  was corrected at write time («رفتارشناسی بازار»); original source
  untouched. Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `59-behavioral-finance.md`
- Original source path: `skills/incoming/59-behavioral-finance.md`
- Import batch: `batch-006`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-006)
