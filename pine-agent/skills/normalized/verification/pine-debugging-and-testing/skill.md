# Skill: pine-debugging-and-testing

## Metadata

```yaml
id: pine-debugging-and-testing
name: Pine Debugging & Testing
version: 1.0.0
path: skills/normalized/verification/pine-debugging-and-testing/skill.md
layer: VERIFICATION
domains: [verification, debugging]
triggers:
  english:
    - pine logs log.info
    - error codes CE RE CW
    - systematic debugging procedure
    - unit testing pure functions
    - regression golden set
    - data window plot debugging
  persian:
    - دیباگ و تست پاین
    - لاگ‌های پاین
    - خطاهای کامپایل و اجرا
dependencies:
  mandatory: []
  optional: [pine-language-core, pine-type-system, data-integrity,
    repainting-and-lookahead, tradingview-execution-model,
    mathematical-foundation, pine-performance-engineering,
    monte-carlo-and-resampling, asset-class-specialization,
    pine-project-documentation]
status: normalized
priority: 1
```

## Purpose

Error taxonomy (compile/runtime/logical), native debugging tools, and
Pine-adapted testing practices.

## Triggers

Select for: any error (compile/runtime/logical); any unexpected value; any
pre-release check; flaky value discrepancies; log-based diagnostics.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Symptom (error/wrong value) | description | user/verification | yes |
| Reproduction context (symbol/TF/range) | parameters | pinned scenario | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Error classification + fix path | diagnosis | Implementation |
| Debug findings log | records | pine-project-documentation |
| Test/golden-set results | verification data | Post-Verification |

## Rules

1. Error taxonomy (official codes): Compile (CE) — e.g., CE10101
   (condition not bool), CE10117 (token limit), undeclared identifier →
   read the message literally; fix types/syntax (pine-language-core /
   pine-type-system). Warning (CW) — e.g., "function called in different
   scopes" (conditional ta.*) → NEVER ignore; usually real bugs. Runtime
   (RE) — e.g., RE10143 (max_bars_back), RE10139 (memory), loop timeout,
   request limit, array out-of-bounds → guard data/layers
   (data-integrity / pine-performance-engineering). Logical — no error,
   wrong values → systematic debugging (rule 3).
2. Native debugging tools (verified): Pine Logs — `log.info/warning/error`
   (or format-string overloads); Pine Logs pane (Editor "More" menu);
   works historical + realtime; ~10k recent historical entries; logs
   reflect per-tick executions (mind volume). Profiler — flame-icons
   top-3 bottlenecks, runtime % per line (pine-performance-engineering).
   Plot debugging — `display = display.data_window` plots + conditional
   bgcolor markers; label.new on suspect bars. Strategy trades list as
   behavioral assertion output.
3. Systematic logical-debug procedure: 1 reproduce deterministically
   (fixed symbol/TF/range; seed randomness —
   monte-carlo-and-resampling); 2 localize — plot suspect series vs
   expectation in the Data Window; 3 verify each pipeline stage separately
   (data → calc → signal → exec); 4 check the known silent killers — na
   propagation (data-integrity), repaint (repainting-and-lookahead),
   conditional ta.* history (pine-language-core), var rollback
   (tradingview-execution-model), float equality
   (mathematical-foundation); 5 binary-search the bar of first divergence
   (barstate/log gating).
4. Pine-adapted testing: unit-style — pure functions tested on known
   inputs at bar 0 (`if bar_index == 0` + log assertions); edge functions:
   KAMA on flat series, OLS on 1-bar window. Boundary testing — array size
   0/1/cap; length-1 indicators; session edges; symbol with volume=na
   (asset-class-specialization). Regression testing — keep a mini "golden
   set" of pinned scenarios (symbol+TF+range+expected values) rerun after
   every change (ledger — pine-project-documentation). Cross-check —
   reimplement one indicator manually (e.g., an RSI loop) and diff against
   ta.rsi — validates understanding, not TradingView.

## Workflow

1. Classify the symptom via the taxonomy (rule 1); fix or escalate.
2. For logical errors: run the 5-step systematic procedure (rule 3).
3. Add unit/boundary tests for the fixed defect (rule 4).
4. Add the scenario to the golden set; rerun regressions (rule 4).

## Constraints

- No fixing symptoms by adding `[1]` everywhere instead of finding the
  leak.
- No logs spamming per-tick in production (perf + noise).
- No testing only on the happy symbol/TF.
- No ignoring CW warnings "because it compiles".

## Assumptions

- log.*/profiler/error taxonomy verified vs official debugging/errors docs
  (import re-verified 2026-09: 10,000-historical-entry cap + log.info/
  warning/error confirmed via official debugging docs and blog).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Wrong values, no error | logical bug | rule 3: systematic procedure |
| CW warning ignored | conditional ta.* | rule 1: treat as bug |
| Flaky reproduction | nondeterminism | rule 3: seed + pin context |
| Regression reappears | no golden set | rule 4: regression testing |

## Dependencies

Optional: pine-language-core (semantics/history), pine-type-system
(compile errors), data-integrity (na), repainting-and-lookahead (repaint
killer), tradingview-execution-model (var rollback),
mathematical-foundation (float equality),
pine-performance-engineering (RE guards), monte-carlo-and-resampling
(seeding), asset-class-specialization (boundary contexts),
pine-project-documentation (ledger). Load only on their own triggers.

## Examples

- "Why is my value na on bar 500?" → rule 3 stages + na killer.
- "CE10101 on compile" → rule 1 read literally.
- Persian: «اسکریپتم عدد عجیب میده» → rule 3 systematic debugging.

## Verification Criteria

- Errors classified via taxonomy; CW warnings addressed.
- Logical bugs located via the staged procedure with divergence bar.
- Unit/boundary tests added for fixed defects.
- Golden-set regressions rerun and recorded.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-007` import from `skills/incoming/70-pine-debugging-and-testing.md`.
- Layer VERIFICATION (its function is post-implementation diagnosis and
  testing, despite the source's "Agent & Software Engineering" category —
  same layer-from-function precedent as repainting-and-lookahead).
- **Pine Logs claim independently RE-VERIFIED at import** (official
  debugging docs + blog: `log.info/warning/error`, 10,000-historical-entry
  cap, historical+realtime operation). Source's illustrative inline
  identifiers preserved as prose per normalization convention (no code
  generated). Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `70-pine-debugging-and-testing.md`
- Original source path: `skills/incoming/70-pine-debugging-and-testing.md`
- Import batch: `batch-007`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-007)
