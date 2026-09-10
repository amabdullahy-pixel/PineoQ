---
name: pine-performance-engineering
category: Agent & Software Engineering
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/writing/profiling-and-optimization/
  - https://www.tradingview.com/pine-script-docs/writing/limitations/
---

# Pine Performance Engineering

## Purpose
Complexity analysis, loop/array optimization, memory & object/request limits,
runtime budgets — with the native Profiler.

## When to Use
- Any loop, any array growth, any request-heavy design, any timeout error.

## Core Knowledge

### Hard Budgets (verified)
- Loop ≤ 500ms/bar; total ≤ 20s (Basic) / 40s (paid) — skill 01.
- 64 plot counts; drawings 500/500/500/100 polylines/9 tables (skill 10).
- 40 unique requests (64 Ultimate); tuple elements ≤ 127 (skill 13).
- Arrays/matrices/maps ≤ 100k elements (skill 03); scopes ≤ 1000 vars.
- Compiled size ≤ ~100k tokens (skill 01).
- Realtime: script re-executes PER TICK — global-scope cost multiplies (skill 07).

### Complexity Discipline
- Per-bar cost × bars = total. O(1)/bar target; O(n)/bar only for bounded n;
  O(n²)/bar = timeout at scale.
- The classic O(n²): nested loops over growing arrays, or recomputing a full
  sum every bar instead of incremental state:
```pine
// BAD: O(n) per bar over history
// GOOD: incremental
var float rollingSum = 0.0
rollingSum += x - nz(x[len])            // O(1)
```

### Array Growth
- Cap + ring-buffer (push + shift when > cap) — never unbounded push (skill 03).

### Loop Optimization
- Early exit: break on condition met; guard continue placement.
- Loop bounds: precompute array.size(a) - 1 ONCE per loop, not per iteration.
- Heavy transforms inside loops → consider array.sort, binary search (v6 UDT
  sort_field, skill 03) instead of nested scans.
- barstate.islast gating for one-time heavy work (MC, dashboards, skill 28/10).

### Memory & Objects
- UDT/array copies: .copy() = shallow — deep-copy loops cost O(n) (skill 03).
- Drawing churn: conditional creation + reuse (set_*) over delete/recreate.
- Request discipline: dedupe identical requests (free), cache results in var,
  never loop-call request.* with varying series args beyond budget (skill 15).

### Profiler Workflow (verified native tool)
- Pine Editor → "More" → Profiler mode → reload chart → flame icons mark the
  top-3 bottlenecks with runtime %/time/counts per line.
- Optimize what the profiler flames, IN THAT ORDER — not intuition.

## Common Mistakes
- request.security inside per-bar loops with dynamic args (budget blowup).
- Recomputing rolling stats from scratch per bar (skill 20 accumulation rule).
- Building dashboards/tables on every historical bar.
- Treating timeouts as "TradingView being slow" instead of O(n²) on our side.

## Corrections & Updates
- [2026-09] Created; budgets verified vs limitations docs; profiler workflow
  verified vs profiling docs.
