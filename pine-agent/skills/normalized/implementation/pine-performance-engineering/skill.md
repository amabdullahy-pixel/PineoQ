# Skill: pine-performance-engineering

## Metadata

```yaml
id: pine-performance-engineering
name: Pine Performance Engineering
version: 1.0.0
path: skills/normalized/implementation/pine-performance-engineering/skill.md
layer: IMPLEMENTATION
domains: [performance, budgets]
triggers:
  english:
    - pine profiler flame icons
    - loop timeout optimization
    - array ring buffer cap
    - request budget dedupe
    - incremental rolling sum
    - 500ms loop limit
  persian:
    - بهینه‌سازی کارایی پاین
    - خطای تایم‌اوت حلقه
    - پروفایلر
dependencies:
  mandatory: []
  optional: [pine-language-core, drawing-and-visualization,
    pine-data-structures, multi-symbol-engineering, mtf-engineering,
    monte-carlo-and-resampling, numerical-methods,
    pine-debugging-and-testing, time-series-analysis]
status: normalized
priority: 1
```

## Purpose

Complexity analysis, loop/array optimization, memory & object/request
limits, runtime budgets — with the native Pine Profiler.

## Triggers

Select for: any loop, any array growth, any request-heavy design, any
timeout error; profiling a slow script; memory/object limit questions.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Slow/timeout-prone script | code plan | implementation | yes |
| Profiler results | runtime data | Pine Profiler | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Budget compliance plan | constraints | Implementation, Feasibility |
| Optimization order (profiler-ranked) | work plan | Implementation |
| Complexity analysis | verification data | Post-Verification |

## Rules

1. Hard budgets (verified): loop ≤ 500 ms/bar; total ≤ 20 s (Basic) / 40 s
   (paid) — pine-language-core; 64 plot counts; drawings 500/500/500/100
   polylines/9 tables — drawing-and-visualization; 40 unique requests (64
   Ultimate); tuple elements ≤ 127 — mtf-engineering; arrays/matrices/maps
   ≤ 100k elements — pine-data-structures; scopes ≤ 1000 vars; compiled
   size ≤ ~100k tokens — pine-language-core; realtime: script re-executes
   PER TICK — global-scope cost multiplies (tradingview-execution-model).
2. Complexity discipline: per-bar cost × bars = total. O(1)/bar target;
   O(n)/bar only for bounded n; O(n²)/bar = timeout at scale. The classic
   O(n²): nested loops over growing arrays, or recomputing a full sum
   every bar instead of incremental state — incremental rolling sum via
   `rollingSum += x - nz(x[len])` is O(1) per bar (accumulation pattern —
   numerical-methods).
3. Array growth: cap + ring-buffer (push + shift when > cap) — never
   unbounded push (pine-data-structures).
4. Loop optimization: early exit (break on condition met; guard continue
   placement); precompute `array.size(a) - 1` ONCE per loop, not per
   iteration; heavy transforms inside loops → array.sort / binary search
   (v6 UDT sort_field — pine-data-structures) instead of nested scans;
   `barstate.islast` gating for one-time heavy work (MC, dashboards —
   monte-carlo-and-resampling / drawing-and-visualization).
5. Memory & objects: UDT/array `.copy()` = shallow — deep-copy loops cost
   O(n) (pine-data-structures); drawing churn — conditional creation +
   reuse (set_*) over delete/recreate (drawing-and-visualization); request
   discipline — dedupe identical requests (free), cache results in var,
   never loop-call request.* with varying series args beyond budget
   (multi-symbol-engineering).
6. Profiler workflow (verified native tool): Pine Editor → "More" →
   Profiler mode → reload chart → flame icons mark the top-3 bottlenecks
   with runtime %/time/counts per line. Optimize what the profiler flames,
   IN THAT ORDER — not intuition.

## Workflow

1. Verify the design against hard budgets BEFORE writing loops (rule 1).
2. Profile the real script (rule 6); identify the flamed bottlenecks.
3. Apply the matching discipline (rules 2–5) in profiler-ranked order.
4. Re-profile after each change; stop when within budget.

## Constraints

- No request.security inside per-bar loops with dynamic args (budget
  blowup).
- No recomputing rolling stats from scratch per bar (accumulation rule).
- No building dashboards/tables on every historical bar.
- No treating timeouts as "TradingView being slow" instead of O(n²) on our
  side.

## Assumptions

- Budgets verified vs limitations docs; profiler workflow verified vs
  profiling docs (import re-verified 2026-09: flame-icons top-3 detail
  confirmed by the official support article).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Loop timeout | 500 ms/bar exceeded | rules 2/4: complexity + early exit |
| Request budget blown | >40 unique requests | rules 1/5: dedupe + cache |
| Dashboard lag | per-bar table rebuilds | rule 4: islast gating |
| Unbounded array | memory growth | rule 3: cap + ring buffer |

## Dependencies

Optional: pine-language-core (runtime limits), drawing-and-visualization
(drawing budgets), pine-data-structures (array/UDT semantics),
multi-symbol-engineering (request budget), mtf-engineering (tuple limits),
monte-carlo-and-resampling (islast heavy work), numerical-methods
(accumulation), pine-debugging-and-testing (logs/perf interplay),
time-series-analysis (warm-up gating). Load only on their own triggers.

## Examples

- "My script times out on long histories" → rules 2, 4 + profiler.
- "Am I out of drawing room?" → rule 1 budgets.
- Persian: «اسکریپتم کنده» → rule 6: profiler first.

## Verification Criteria

- All hard budgets accounted in the design.
- Profiler run documented with optimization order.
- O(1)/bar (or bounded) complexity demonstrated for hot paths.
- Request/drawing/array usage within caps.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-007` import from
  `skills/incoming/69-pine-performance-engineering.md`.
- **Native Profiler claim independently RE-VERIFIED at import** (official
  profiling-and-optimization docs + support article 43000725216 with the
  exact flame-icons top-3 detail). Budget numbers consistent with
  batch-001/002 verified inventories. Resolves the batch-001 parked
  candidate {10↔69} (drawing-and-visualization ↔ performance:
  complementary, dependency_relationship). Source's illustrative two-line
  increment pattern preserved as rule prose per normalization convention
  (no code generated). Structural reorganization only; no semantic
  changes.

## Source Reference

- Original filename: `69-pine-performance-engineering.md`
- Original source path: `skills/incoming/69-pine-performance-engineering.md`
- Import batch: `batch-007`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-007)
