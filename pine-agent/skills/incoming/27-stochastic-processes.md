---
name: stochastic-processes
category: Statistics & Probability
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Stochastic Processes

## Purpose
Random walks, Markov chains, martingales, mean reversion, Brownian-motion
concepts — as market-modeling and simulation foundations.

## When to Use
- Modeling price evolution for MC (skill 28), regime classification
  (trend vs mean-reversion), option-style projections, risk scenarios.

## Core Knowledge

### Random Walk & Brownian Motion (discrete: GBM)
- Random walk: Xₜ = Xₜ₋₁ + εₜ, εᵢ i.i.d.
- Geometric Brownian Motion (per-bar simulation in Pine):
```pine
// r̄, σ = per-bar log-return stats; Z ~ N(0,1) via Box–Muller
boxMuller() =>
    float u1 = math.random(0.0, 1.0, seed), float u2 = math.random(0.0, 1.0, seed + 1)
    math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)
dLogP = (mu - 0.5 * sigma * sigma) + sigma * boxMuller()
```
- Drift vs diffusion: over N bars, signal ≈ μ·N vs noise ≈ σ·√N — why edges
  must scale with N to overcome √N noise.

### Markov Chains (regime models)
- States (e.g., 0=down, 1=flat, 2=up); estimate transition matrix P from
  history: count transitions with var matrix or 3×3 array; P[i][j] = count(i→j)/rowSum(i).
- Use: expected regime persistence, regime-switch forecasts, filter design.
- Markov property assumption: next state depends only on current — test
  residual dependence (lagged transitions) before trusting higher-order claims.

### Martingale vs Mean Reversion
- Martingale: E[Xₜ₊₁ | history] = Xₜ (no exploitable drift; fair game).
- Sub/super-martingales frame downside drift vs growth.
- Mean reversion: OU-process flavor — `xₜ₊₁ = xₜ + κ(θ − xₜ) + σεₜ`
  (κ=speed, θ=long-run mean): simulate or fit by regressing Δx on x (skill 24):
  slope≈−κ·dt, intercept≈κθ·dt; R² low is normal.
- Half-life of reversion ≈ ln(2)/κ (in bars) — key for pair-trade horizons (skill 50).

### Trading Applications
- Hurst exponent (rescaled-range or variance-ratio method, manual loop) —
  H>0.5 trending, H<0.5 mean-reverting, H≈0.5 random walk; estimate on
  returns per regime window.
- Z-score spread models assume OU dynamics — validate half-life before trading.

## Common Mistakes
- Applying mean-reversion logic to trending (H>0.5, non-stationary) series.
- Estimating transition matrices from few observations (rows summing from tiny N).
- Simulating GBM with arithmetic (not log) steps → lognormal drift wrong.
- Forgetting √N noise scaling when projecting "expected" profits.

## Corrections & Updates
- [2026-09] Created; simulation idioms use verified math.random/seed semantics.
