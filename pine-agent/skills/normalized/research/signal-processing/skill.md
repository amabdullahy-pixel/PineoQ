# Skill: signal-processing

## Metadata

```yaml
id: signal-processing
name: Signal Processing
version: 1.0.0
path: skills/normalized/research/signal-processing/skill.md
layer: RESEARCH
domains: [signal-processing, indicator-design]
triggers:
  english:
    - SuperSmoother Ehlers
    - roofing filter
    - high-pass band-pass
    - dominant cycle autocorrelation
    - SNR signal to noise
    - detrending
    - smoothing ladder
  persian:
    - پردازش سیگنال
    - فیلتر سوپراسموس
    - سیکل غالب
    - نسبت سیگنال به نویز
dependencies:
  mandatory: []
  optional: [technical-analysis-core, regime-detection, adaptive-systems, numerical-methods]
status: normalized
priority: 2
```

## Purpose

Noise filtering, the smoothing ladder, low/high/band-pass filters,
detrending, SNR, and Fourier/wavelet concepts — Ehlers-standard recursive
implementations in Pine for cleaning series before logic and extracting
cycles.

## Triggers

Select for: cleaning series before indicator logic; cycle extraction;
oscillator-pinning fixes (roofing preprocessor); adaptive lookbacks from
dominant cycle; SNR-gated reliability decisions.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Filtering/cycle requirement | description | formalization contract | yes |
| Period parameters (cutoffs) | parameters | user/formalization | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Filter implementations (verified coefficients) | code patterns | Implementation |
| SNR/reliability gates | design output | regime-detection |
| Warm-up requirements | verification checks | Pre-Verification |

## Rules

1. Smoothing ladder (lag vs smoothness): SMA → EMA → WMA/HMA → SuperSmoother
   (Ehlers) → Kalman-style state filters; choose by lag budget + noise level;
   never stack smoothers blindly (lag compounds — see numerical-methods).
2. SuperSmoother (canonical 2-pole Ehlers — coefficients match the published
   canon): a1 = exp(−1.414·π/period); b1 = 2a1·cos(1.414·π/period); c2 = b1;
   c3 = −a1²; c1 = 1 − c2 − c3; recursive
   f := c1·(src + nz(src[1], src))/2 + c2·f[1] + c3·f[2] with var state and
   na-seeded init. Unity gain at DC (no bias), sharper roll-off than MA;
   3-pole variant = heavier attenuation, more lag.
3. High-pass (remove trend/drift) & roofing filter: 2-pole high-pass with
   alpha1 = (cos(0.707·2π/P) + sin(0.707·2π/P) − 1)/cos(0.707·2π/P) and the
   recursive hp form (canon-consistent); Roofing = highpass(trend cutoff)
   THEN super(smoother cutoff) — a band-pass preprocessor; oscillators
   computed on roofed data stop pinning in trends.
4. Band-pass & dominant cycle: band-pass isolates a cycle band; dominant
   cycle via autocorrelation periodogram (correlate roofed series vs lags →
   power per period → center-of-gravity DC = Σ(P·Pwr)/ΣPwr); adaptive
   lookbacks from DC (see adaptive-systems).
5. Detrending & SNR: detrend (subtract linreg/SMA, or high-pass) before
   spectral-style analysis; SNR = signal variance/total variance (dB:
   10·log10) — high SNR = cycle tools reliable; low SNR = stand down (ties to
   regime — see regime-detection).
6. Fourier/wavelet reality in Pine: NO built-in FFT/wavelets; manual DFT is
   O(n²) per bar → impractical realtime; use recursive IIR filters (above)
   and autocorrelation periodograms instead.
7. Recursion warm-up: initialize states and gate the first ~4·period bars
   (consistent with time-series-analysis warm-up discipline).

## Workflow

1. Diagnose the noise/lag budget; pick from the ladder (rule 1).
2. Implement SuperSmoother/high-pass/roofing from the verified coefficients
   (rules 2–3); seed recursion states and gate warm-up (rule 7).
3. For cycle work: roof → autocorrelation periodogram → DC → adaptive
   lookbacks (rule 4).
4. Gate cycle-tool reliability on SNR (rule 5).

## Constraints

- No built-in FFT/wavelets; no O(n²) DFT loops in realtime paths.
- No feeding non-stationary price into spectral analysis (detrend first).
- No trusting cycle outputs in low-SNR tape.

## Assumptions

- SuperSmoother/high-pass coefficients verified by the source against the
  Ehlers canon (Cycle Analytics for Traders 2013; Rocket Science for Traders
  2001) and community references; import-time review confirms consistency
  with the published forms.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Compound lag | EMA of EMA of EMA | rule 1: single-stage choice |
| Spectral garbage | non-stationary input | rule 5: detrend first |
| Warm-up garbage | early-bar recursion values | rule 7: gate ~4·period |
| Cycle signals in low SNR | unreliable outputs | rule 5: stand down |

## Dependencies

Optional: technical-analysis-core (pillar context), regime-detection (SNR/
regime tie), adaptive-systems (DC-driven lookbacks), numerical-methods
(recursion stability). Load only on their own triggers.

## Examples

- "My RSI pins in trends" → rule 3 roofing preprocessor.
- "Adapt my lookback to the dominant cycle" → rule 4 periodogram.
- Persian: «نویز سری‌ام را کم کن» → rules 1–2 with lag budget.

## Verification Criteria

- Filter coefficients match the Ehlers canon (reviewable line-by-line).
- Recursion states initialized; warm-up gated (~4·period bars).
- Spectral-style analysis operates on detrended data only.
- SNR gate present where cycle tools feed logic.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-005` import from `skills/incoming/49-signal-processing.md`.
- Import-time review: SuperSmoother and 2-pole high-pass recursion forms
  match the published Ehlers canon (consistent with the source's citations);
  the no-FFT/wavelets claim is a negative claim preserved as a
  verify-before-use gate per convention.
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `49-signal-processing.md`
- Original source path: `skills/incoming/49-signal-processing.md`
- Import batch: `batch-005`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-005)
