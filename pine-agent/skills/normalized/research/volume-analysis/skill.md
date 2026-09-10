# Skill: volume-analysis

## Metadata

```yaml
id: volume-analysis
name: Volume Analysis
version: 1.0.0
path: skills/normalized/research/volume-analysis/skill.md
layer: RESEARCH
domains: [technical-analysis, volume]
triggers:
  english:
    - OBV VWAP
    - relative volume RVOL
    - volume delta CVD approximation
    - volume profile POC value area
    - anchored VWAP
    - volume anomalies
  persian:
    - تحلیل حجم
    - حجم نسبی
    - پروفایل حجمی
    - DELTA و CVD
dependencies:
  mandatory: []
  optional: [technical-analysis-core, mtf-engineering, multi-symbol-engineering, data-integrity]
status: normalized
priority: 2
```

## Purpose

Volume, OBV, VWAP, relative volume, anomalies, and volume-profile/delta
concepts with verified built-in availability — including the intrabar CVD
approximation pattern and its honest limits (tick-direction heuristic, not
true bid/ask delta).

## Triggers

Select for: confirmation filters via volume; institutional-activity proxies;
intrabar analytics (delta/CVD, volume profile); VWAP session/anchored
semantics; volume na/anomaly handling.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Volume-logic requirement | description | formalization contract | yes |
| Symbol has volume data? | context | target symbol | yes |
| LTF intrabar budget | constraint | mtf-engineering | conditional |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Volume implementation | knowledge applied | Implementation |
| Built-in availability map | design facts | Implementation Planning |
| Delta/profile approximation limits | warnings | Pre-Verification |

## Rules

1. Verified built-ins: `volume` (na on symbols without volume data — guard);
   `ta.obv` cumulative ±volume by close direction =
   ta.cum(math.sign(ta.change(close))·volume); `ta.vwap(src)` session-anchored
   (resets each session by default, hlc3 source); Anchored VWAP
   `ta.vwap(src, anchor, stdev_mult)` — anchor (bool) RESETS accumulation when
   true, stdev_mult adds ± bands. NO built-ins for relative volume, volume
   profile, delta/CVD (manual patterns below).
2. Relative volume & anomalies: RVOL = volume/ta.sma(volume, 20) (>2 =
   anomaly candidate); session-aware RVOL compares same time-of-day buckets
   (see time-series-analysis seasonality arrays); zero-volume bars on
   illiquid symbols poison OBV/VWAP — filter (see data-integrity).
3. Delta/CVD (intrabar approximation): pull per-bar arrays of closes/volumes
   via `request.security_lower_tf` (see mtf-engineering); classify each
   intrabar step by close direction and accumulate ±volume into barDelta,
   then CVD via var accumulation. Heuristic = tick-direction classification,
   NOT true bid/ask delta (unless request.footprint — see
   multi-symbol-engineering, plan-gated).
4. Volume profile concepts (script approximation): no built-in TA function —
   price-bin arrays (e.g., bin = ATR/4), distribute intrabar volume into
   bins, POC = max bin, value area = accumulate outward from POC to ~70%
   volume; keep bins bounded (≤100k elements).
5. VWAP discipline: institutional benchmark — distance from VWAP in σ-bands
   (stdev_mult) as reversion context; trend days ride the upper band (regime
   context first — see regime-detection).

## Workflow

1. Verify volume data exists for the symbol; guard na (rule 1, 2).
2. Choose built-ins (volume/obv/vwap) vs manual (RVOL/VP/delta) per rule 1.
3. For delta/CVD, apply the security_lower_tf pattern with budget awareness
   (rule 3; mtf-engineering intrabar caps).
4. For VP, keep bins bounded and compute POC/VA per rule 4.
5. Document VWAP variant (session vs anchored) explicitly (rules 1, 5).

## Constraints

- No built-in RVOL/VP/delta — manual approximations with stated limits.
- Chart-timeframe close-direction "delta" is forbidden (loses intrabar info).
- Intrabar budget is plan-capped (mtf-engineering).

## Assumptions

- Built-in availability verified by the source against the v6 reference;
  anchored-VWAP signature consistent with the v6 reference's optional
  params.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Delta from chart closes | lost intrabar info | rule 3: security_lower_tf |
| VWAP reset surprise | session semantics | rule 1/5: document variant |
| RVOL on na-volume symbols | na propagation | rule 2: guard/filter |
| Unbounded profile bins | 100k limit | rule 4: bound bins |

## Dependencies

Optional: technical-analysis-core (pillar context), mtf-engineering (LTF
arrays/budget), multi-symbol-engineering (request.footprint for true delta),
data-integrity (na/illiquidity guards). Load only on their own triggers.

## Examples

- "Detect unusual volume bursts" → rule 2 RVOL + session-aware buckets.
- "Approximate CVD on a 15m chart" → rule 3 pattern with budget checks.
- Persian: «پروفایل حجمی داخلی نداریم؟» → rule 4: manual approximation.

## Verification Criteria

- Volume-data na guards present; VWAP variant documented.
- Delta approximations use LTF arrays (never chart-close direction) and state
  the heuristic limit.
- Profile bins bounded; POC/VA computation documented.
- Intrabar budget respected (mtf-engineering).

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-004` import from `skills/incoming/38-volume-analysis.md`.
- Layer decision: RESEARCH (consistent with the TA block). Structural
  reorganization only; no semantic changes.

## Source Reference

- Original filename: `38-volume-analysis.md`
- Original source path: `skills/incoming/38-volume-analysis.md`
- Import batch: `batch-004`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-004)
