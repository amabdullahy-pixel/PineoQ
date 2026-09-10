# Skill: market-psychology

## Metadata

```yaml
id: market-psychology
name: Market Psychology
version: 1.0.0
path: skills/normalized/research/market-psychology/skill.md
layer: RESEARCH
domains: [behavioral, market-context]
triggers:
  english:
    - fear greed proxy VIX
    - put call ratio PCR
    - capitulation bar
    - FOMO detection
    - crowd state euphoria panic
    - funding rate extremes
  persian:
    - روانشناسی بازار
    - ترس و طمع
    - کندل کاپیتولیشن
dependencies:
  mandatory: []
  optional: [behavioral-finance, intermarket-analysis, regime-detection,
    signal-fusion, volume-analysis, market-structure,
    multi-symbol-engineering]
status: normalized
priority: 2
```

## Purpose

Fear, greed, panic, euphoria, capitulation, FOMO, crowd behavior — with
quantifiable proxies available in Pine.

## Triggers

Select for: contrarian context; regime overlays; exhaustion/capitulation
detection; "is the crowd euphoric?" questions.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Crowd-state question | description | formalization contract | yes |
| Proxy symbols (VIX/PCR feeds) | symbol IDs | user (verify per plan) | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Crowd-state proxy implementation | code pattern | Implementation |
| Capitulation/FOMO detection patterns | code patterns | Implementation |
| Context-layer gates | contract fields | signal-fusion |

## Rules

1. Fear/greed proxies (verified on TradingView): volatility structure —
   `vix = request.security("CBOE:VIX", "1D", close)`,
   `vix3m = request.security("CBOE:VIX3M", "1D", close)`; `backwardation =
   vix > vix3m` (stress), `contango = vix3m > vix` (calm). Options
   positioning — `pcr = request.security("CBOE:PC", "1D", close)` (put/call
   ratio — VERIFY ID per plan). Crypto positioning: funding-rate data
   exists as TradingView metrics (per support article); proxy via premium
   index or community scripts if no direct series. CNN Fear & Greed: NO
   native symbol — community-script approximation only (aggregate VIX
   trend, momentum, PCR, safe-haven demand); label as approximate.
2. Crowd-state ladder (proxy thresholds — calibrate per asset):
   complacency (low vol, contango, low RVOL — VIX percentile <20);
   anxiety (VIX 40–70th pct); fear (backwardation onset, PCR skew —
   VIX > VIX3M); panic (VIX pct >90 + correlation →1 — intermarket-analysis);
   capitulation (volume flush + wick reversal — rule 3); euphoria/FOMO
   (RVOL surge on extension, funding extremes — RVOL >2.5 at run highs).
3. Capitulation proxy (computable): `rvol = volume / ta.sma(volume, 50)`;
   `bigWick = math.min(close, open) - low > 1.5 * (ta.atr(14) * 0.5)`
   (lower wick dominant); `wideRange = ta.tr(true) > 2.0 * ta.atr(14)`;
   `capitulationBar = rvol > 3 and wideRange and bigWick and close > open *
   0.99`. Capitulation marks CANDIDATE bottoms (sell-side exhaustion) —
   require confirmation structure (market-structure) before trading it.
4. FOMO proxy: RVOL > 2.5 + consecutive-body extension +
   distance-from-VWAP extreme (volume-analysis) → crowd chasing; expect
   mean-reversion risk (regime-dependent — regime-detection).
5. Usage discipline: proxies = context LAYERS (hierarchical fusion —
   signal-fusion), NOT triggers; extremes persist longer than expected in
   trends — pair with a regime gate (regime-detection) before fading.

## Workflow

1. Verify proxy symbol IDs per plan (rule 1).
2. Compute the crowd-state ladder with calibrated percentiles (rule 2).
3. Detect capitulation/FOMO candidates (rules 3–4); demand confirmation
   before acting (rule 3).
4. Wire proxies as context layers with regime gating (rule 5).

## Constraints

- No fading euphoria in strong trends without regime confirmation.
- No PCR/funding mid-range values treated as information (noise).
- No Fear&Greed-style composites trusted as precise signals
  (approximations only).
- No symbol IDs assumed without per-plan verification.

## Assumptions

- VIX/VIX3M semantics verified vs reference (source-verified); PCR symbol
  IDs flagged verify-per-plan; funding-rate access per support article.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Fading euphoria mid-trend | no regime gate | rule 5: pair with regime |
| Mid-range PCR traded | noise | constraint: extremes only |
| Capitulation traded raw | no confirmation | rule 3: structure confirm |
| Wrong plan's PCR symbol | na feed | rule 1: verify per plan |

## Dependencies

Optional: behavioral-finance (bias map), intermarket-analysis
(correlation/panic), regime-detection (regime gate), signal-fusion (context
layering), volume-analysis (RVOL/VWAP distance), market-structure
(confirmation), multi-symbol-engineering (request budget). Load only on
their own triggers.

## Examples

- "Detect capitulation candles" → rule 3 proxy.
- "Is the market euphoric?" → rule 2 ladder.
- Persian: «چه زمانی جمعیت وحشت‌زده شده؟» → rule 2 panic state.

## Verification Criteria

- Proxy symbol IDs verified per plan.
- Capitulation signals require structural confirmation.
- Proxies wired as context layers, not triggers.
- Regime gate precedes any contrarian action.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope (funding-rate direct-series availability varies
  — proxy guidance preserved).

## Import Notes

- Batch `batch-006` import from `skills/incoming/60-market-psychology.md`.
- PCR symbol-ID claim preserved as verify-per-plan (not independently
  verifiable across account plans — handled by mandatory live checks);
  VIX/VIX3M contango/backwardation semantics source-verified vs reference.
  Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `60-market-psychology.md`
- Original source path: `skills/incoming/60-market-psychology.md`
- Import batch: `batch-006`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-006)
