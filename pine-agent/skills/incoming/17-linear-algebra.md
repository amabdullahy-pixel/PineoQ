---
name: linear-algebra
category: Mathematics
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/language/matrices/
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Linear Algebra

## Purpose
Vectors and matrices: operations, covariance, eigen-decomposition — in Pine.

## When to Use
- Multi-asset covariance/correlation matrices, PCA-style ideas, portfolio math,
  regression systems, geometric transforms.

## Core Knowledge

### Matrices — matrix<T> (verified v6 inventory)
- Create/inspect: `matrix.new<type>(rows, cols, init)`, `matrix.rows/cols`,
  `matrix.elements_count`.
- Access: `matrix.get/set`, `matrix.fill`, `matrix.copy`, `matrix.reshape`,
  `matrix.reverse`, `matrix.concat`, `matrix.submatrix(...)`,
  `matrix.row(m, i)` / `matrix.col(m, j)` (return arrays).
- Structure ops: `add_row/add_col`, `remove_row/remove_col`,
  `swap_rows/swap_columns`, `matrix.sort(m, order)`.
- Algebra: `matrix.mult(A, B)` (matrix×matrix AND matrix×vector-array overloads),
  `matrix.transpose`, `matrix.inv` (square), `matrix.pinv` (Moore–Penrose),
  `matrix.det`, `matrix.rank`, `matrix.trace`, `matrix.pow(A, n)`,
  `matrix.avg/min/max`.
- Eigen: `matrix.eigenvalues(m) → array<float>`,
  `matrix.eigenvectors(m) → matrix` (columns = eigenvectors).
- DO NOT EXIST (verify before using, skill 76): `matrix.diff`, `matrix.dot`,
  `matrix.lu`, `matrix.chol`, `matrix.qr`. Implement manually or approximate
  via `pinv`/eigen.
- Limits: rows×cols ≤ 100,000 elements.

### Vectors — arrays (NO native vector type)
```pine
dot(u, v) =>                 // u, v: array<float>
    float s = 0.0
    for i = 0 to array.size(u) - 1
        s += array.get(u, i) * array.get(v, i)
    s

norm(v) => math.sqrt(dot(v, v))
normalize(v) =>              // returns new array; guard norm==0
```
- Matrix × vector: `matrix.mult(A, arrV)` → array.
- Covariance matrix (N assets): loops over return arrays; `var i,j = cov(i,j)`;
  diagonal = variances (pairs with skill 24).

### Eigen Use Cases
- PCA-flavored regime detection: first eigenvalue share = dominant variance mode.
- Stability checks: |λ| of transition-like matrices.

### Geometric Transforms
- 2D rotation/scaling via 2×2 matrix.mult on point arrays; render with
  chart.point + polyline (skill 19/43).

## Common Mistakes
- Assuming eigen/eigenvector results are ordered — sort/inspect before use.
- matrix.inv on singular matrices → error/garbage; check matrix.det ≠ 0 or use pinv.
- Confusing matrix.mult(A, v) overload return types (matrix vs array).
- Building >100k-element matrices.

## Corrections & Updates
- [2026-09] Created; verified against v6 reference (matrix namespace complete;
  no lu/qr/chol built-ins).
