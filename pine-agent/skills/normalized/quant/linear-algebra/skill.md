# Skill: linear-algebra

## Metadata

```yaml
id: linear-algebra
name: Linear Algebra
version: 1.0.0
path: skills/normalized/quant/linear-algebra/skill.md
layer: QUANT
domains: [mathematics, matrices]
triggers:
  english:
    - covariance matrix
    - eigenvalues eigenvectors
    - PCA regime
    - matrix inverse
    - pseudo-inverse pinv
    - matrix multiply
    - vector dot product
    - rotation matrix
  persian:
    - جبر خطی
    - ماتریس کوواریانس
    - مقدار و بردار ویژه
    - ضرب ماتریسی
dependencies:
  mandatory: []
  optional: [mathematical-foundation, statistics-core, advanced-market-geometry, documentation-verification]
status: normalized
priority: 2
```

## Purpose

Vectors and matrices in Pine: the verified `matrix` namespace inventory,
vector operations over arrays, covariance construction, and
eigen-decomposition use cases (PCA-style regime detection, stability checks,
geometric transforms) — with an explicit do-not-exist list to prevent
hallucinated APIs.

## Triggers

Select for: multi-asset covariance/correlation matrices; PCA-style ideas;
portfolio math; regression systems; geometric transforms; any `matrix.*`
API question.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Linear-algebra requirement | description | formalization contract | yes |
| Asset/series count (matrix sizing) | design fact | formalization contract | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Matrix/vector design + API mapping | knowledge applied | Implementation |
| Size/budget constraints | constraint notes | Feasibility |
| Eigen-stability caveats | verification checks | Pre/Post-Verification |

## Rules

1. Matrices (verified v6 inventory per source): create/inspect
   `matrix.new<type>(rows, cols, init)`, `matrix.rows/cols`,
   `matrix.elements_count`; access `matrix.get/set`, `matrix.fill`,
   `matrix.copy`, `matrix.reshape`, `matrix.reverse`, `matrix.concat`,
   `matrix.submatrix(...)`, `matrix.row(m, i)` / `matrix.col(m, j)`
   (return arrays); structure ops `add_row/add_col`, `remove_row/remove_col`,
   `swap_rows/swap_columns`, `matrix.sort(m, order)`; algebra
   `matrix.mult(A, B)` (matrix×matrix AND matrix×vector-array overloads),
   `matrix.transpose`, `matrix.inv` (square), `matrix.pinv`
   (Moore–Penrose), `matrix.det`, `matrix.rank`, `matrix.trace`,
   `matrix.pow(A, n)`, `matrix.avg/min/max`; eigen
   `matrix.eigenvalues(m) → array<float>`,
   `matrix.eigenvectors(m) → matrix` (columns = eigenvectors).
2. DO NOT EXIST (verify before using via documentation-verification):
   `matrix.diff`, `matrix.dot`, `matrix.lu`, `matrix.chol`, `matrix.qr` —
   implement manually or approximate via `pinv`/eigen.
3. Limits: rows × cols ≤ 100,000 elements (consistent with
   pine-data-structures).
4. Vectors: NO native vector type — use arrays; dot/norm/normalize are
   user-defined (guard norm == 0); `matrix.mult(A, arrV)` → array.
5. Covariance matrix (N assets): loop over return arrays; diagonal =
   variances (pairs with statistics-core).
6. Eigen use cases: PCA-flavored regime detection (first eigenvalue share =
   dominant variance mode); stability checks via |λ| of transition-like
   matrices; eigen/eigenvector results are NOT guaranteed ordered —
   sort/inspect before use; `matrix.inv` on singular matrices errors — check
   `matrix.det ≠ 0` or use `pinv`.
7. Geometric transforms: 2D rotation/scaling via 2×2 `matrix.mult` on point
   arrays; render with `chart.point` + polyline (see analytical-geometry).

## Workflow

1. Map the required algebra to the verified inventory (rule 1); reject
   non-existent APIs (rule 2) before planning.
2. Size the matrix against the 100k limit (rule 3) for the asset/window count.
3. Build vectors as arrays with guarded helpers (rule 4).
4. For eigen work, apply the ordering/singularity caveats (rule 6).
5. Record size and runtime budget in Feasibility.

## Constraints

- Do-not-exist list (rule 2) binds unless documentation-verification
  confirms an addition.
- 100,000-element matrix cap; 500 ms/bar loop budget for hand-built ops
  (covariance loops).

## Assumptions

- Matrix namespace inventory per v6 reference as claimed by the source.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Eigen results misinterpreted | order assumptions | rule 6: sort/inspect first |
| inv on singular matrix | error/garbage | rule 6: det check or pinv |
| matrix.mult return-type confusion | matrix vs array | rule 1/4: overload semantics |
| >100k elements | runtime error | rule 3: resize/restructure |

## Dependencies

Optional: mathematical-foundation (precision/precedence), statistics-core
(covariance/correlation math), advanced-market-geometry (geometry depth),
documentation-verification (verify-before-use gate). Load only on their own
triggers.

## Examples

- "Build a 5-asset covariance matrix" → rules 4–5 loop construction.
- "PCA-style regime score from sector returns" → rule 6 eigenvalue share.
- Persian: «تابع معکوس ماتریس هست؟» → rule 1 inventory + rule 6 singularity.

## Verification Criteria

- Only verified `matrix.*` APIs used; do-not-exist list respected.
- Matrix sizes within the 100k cap; loops within the 500 ms/bar budget.
- Eigen usage includes ordering/singularity handling.
- Norm/division guards present in vector helpers.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-002` import from `skills/incoming/17-linear-algebra.md`.
- Structural reorganization only; no semantic changes. The do-not-exist list
  is preserved verbatim as a verify-before-use gate tied to
  documentation-verification (pending import) — a deliberate anti-hallucination
  device, not an assertion to relax.

## Source Reference

- Original filename: `17-linear-algebra.md`
- Original source path: `skills/incoming/17-linear-algebra.md`
- Import batch: `batch-002`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-002)
