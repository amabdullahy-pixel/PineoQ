---
name: signal-processing
category: Quantitative Trading
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - "Ehlers, Cycle Analytics for Traders (2013); Rocket Science for Traders (2001)"
  - https://www.luxalgo.com/library/concept/roofing-filter/
  - https://docs.rs/tulip_rs/latest/tulip_rs/indicators/supersmoother/index.html
---

# Signal Processing

## Purpose
Noise filtering, smoothing ladder, low/high/band-pass, detrending, SNR,
Fourier/wavelet concepts — Ehlers-standard implementations in Pine.

## When to Use
- Cleaning series before logic; cycle extraction; indicator design.

## Core Knowledge

### Smoothing Ladder (lag vs smoothness)
- SMA → EMA → WMA/HMA → SuperSmoother (Ehlers) → Kalman-style state filters.
- Choose by lag budget + noise level; never stack smoothers blindly (lag compounds).

### SuperSmoother (canonical 2-pole, Ehlers — verified formula)
```pine
super(float src, float period) =>
    float a1 = math.exp(-1.414 * math.pi / period)
    float b1 = 2.0 * a1 * math.cos(1.414 * math.pi / period)
    float c2 = b1
    float c3 = -a1 * a1
    float c1 = 1.0 - c2 - c3
    var float f = na
    f := na(f) ? src :
         c1 * (src + nz(src[1], src)) / 2.0 + c2 * f[1] + c3 * f[2]
    f
```
- Unity gain at DC (no bias), sharper roll-off than MA. 3-pole variant =
  heavier attenuation, more lag.

### High-Pass (remove trend/drift) & Roofing Filter
```pine
highpass(float src, float hpPeriod) =>
    float alpha1 = (math.cos(0.707 * 2 * math.pi / hpPeriod)
         + math.sin(0.707 * 2 * math.pi / hpPeriod) - 1.0)
         / math.cos(0.707 * 2 * math.pi / hpPeriod)
    var float h = 0.0
    h := math.pow(1.0 - alpha1 / 2.0, 2) * (src - 2.0 * nz(src[1], src) + nz(src[2], src))
         + 2.0 * (1.0 - alpha1) * h[1] - math.pow(1.0 - alpha1, 2) * h[2]
    h
// Roofing = highpass(trend cutoff) THEN super(smoother cutoff) — band-pass
// preprocessor; oscillators computed on roofed data stop pinning in trends.
```

### Band-Pass & Dominant Cycle
- Band-pass isolates a cycle band; dominant cycle via autocorrelation
  periodogram (correlate roofed series vs lags → power per period →
  center-of-gravity DC = Σ(P·Pwr)/ΣPwr) — adaptive lookbacks from DC (skill 48).

### Detrending & SNR
- Detrend: subtract linreg/SMA, or high-pass, before spectral-style analysis.
- SNR = signal variance / total variance (dB: 10·log10) — high SNR = cycle
  tools reliable; low SNR = stand down (ties to regime, skill 47).

### Fourier/Wavelet Reality in Pine
- NO built-in FFT/wavelets. Manual DFT = O(n²) per bar → impractical realtime;
  use recursive IIR filters (above) and autocorrelation periodograms instead.

## Common Mistakes
- Double-smoothing compound lag (EMA of EMA of EMA).
- Feeding non-stationary price directly into spectral analysis (detrend first).
- Recursion warm-up: initialize states and gate first ~4·period bars.
- Trusting "cycle" outputs in low-SNR tape.

## Corrections & Updates
- [2026-09] Created; SuperSmoother/high-pass coefficients verified against
  Ehlers canon and community references.
