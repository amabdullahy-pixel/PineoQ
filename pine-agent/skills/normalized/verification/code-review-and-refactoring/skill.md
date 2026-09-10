# Skill: code-review-and-refactoring

## Metadata

```yaml
id: code-review-and-refactoring
name: Code Review & Refactoring
version: 1.0.0
path: skills/normalized/verification/code-review-and-refactoring/skill.md
layer: VERIFICATION
domains: [verification, code-quality]
triggers:
  english:
    - structured code review
    - repaint audit checklist
    - behavior preserving refactoring
    - third party script audit
    - review verdict format
    - duplicate computation detection
  persian:
    - بازبینی کد
    - بازآرایی ایمن
    - ممیزی ریپینت
dependencies:
  mandatory: []
  optional: [pine-version-intelligence, trend-indicators,
    momentum-indicators, volatility-indicators, natural-language-to-math,
    repainting-and-lookahead, pine-performance-engineering,
    drawing-and-visualization, data-integrity, pine-code-architecture,
    project-knowledge-management, pine-project-documentation,
    research-to-code, pine-debugging-and-testing, backtesting-science,
    multi-symbol-engineering, pine-functions-libraries]
status: normalized
priority: 1
```

## Purpose

Structured audits: mathematical correctness, logical correctness, repaint
audit, performance audit, refactoring, duplicate detection — before
publishing/deploying or touching any existing script (own or third-party).

## Triggers

Select for: pre-publication/pre-deployment review; reviewing any change to
an existing script; auditing third-party code; refactoring planning.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Script/change to review | artifact | implementation | yes |
| Golden set (for refactors) | pinned scenarios | pine-debugging-and-testing | conditional |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Review verdict (fixed format) | verification record | Post-Verification |
| Numbered findings list | records | Implementation |
| Refactor plan (one intent per change) | work plan | Implementation |

## Rules

1. Review checklist (fixed order — data up, cosmetics down): 1 API/version
   check — every built-in verified vs reference (documentation-verification);
   2 math correctness — formulas vs canon (RSI/ATR/ADX semantics —
   trend/momentum/volatility-indicators), units consistent (ticks vs price
   vs % — strategy-engine), precision hazards (numerical-methods); 3
   logical correctness — truth table of gates, De Morgan violations,
   and/or precedence, XOR confusion (natural-language-to-math), state
   machine transitions exhaustive; 4 repaint audit — run the
   repainting-and-lookahead checklist VERBATIM; report findings as
   repaint-by-design / repaint-bug / clean; 5 performance audit — profiler
   flames addressed, unbounded arrays, request budget, per-tick costs
   (pine-performance-engineering); 6 limits & guards — drawings, plots,
   requests, na guards, warm-ups (drawing-and-visualization /
   data-integrity); 7 duplicate detection — same computation twice
   (including two ta.* calls doing the same thing at different call sites
   with drifted params); 8 architecture — layering respected
   (pine-code-architecture), magic numbers → inputs; 9 docs —
   manifest/changelog updated (project-knowledge-management /
   pine-project-documentation).
2. Refactoring rules (behavior-preserving): one intent per change —
   extract-function, rename, or restructure, NEVER mixed with logic edits;
   golden-set regression before/after every refactor
   (pine-debugging-and-testing); signal-path changes = NOT refactoring —
   that's new research (research-to-code gate); prefer deleting dead code
   over commenting it out.
3. Third-party code review extras: check the publication for lookahead
   tricks (repainting-and-lookahead — publications with lookahead leaks
   violate TradingView rules, per the official repainting documentation the
   source cites); verify claimed backtest stats can even exist — N, period,
   costs (backtesting-science); imported libraries — pin versions, note
   plan-gated features used (pine-functions-libraries /
   multi-symbol-engineering).
4. Verdict format: REVIEW: {pass | pass-with-notes | fail} — findings:
   [numbered] — repaint: {clean | by-design | bug} — perf: {ok | budgeted |
   over}.

## Workflow

1. Run the checklist in its fixed order (rule 1); never review style
   before correctness.
2. Record findings numbered; classify repaint status explicitly (rule 1
   step 4).
3. If refactoring: one intent per change with golden-set regression
   (rule 2).
4. Emit the verdict in the fixed format (rule 4).

## Constraints

- "It compiles" is not a review.
- No mixing refactor with behavior change.
- No accepting third-party stats without audit.
- Cosmetics last.

## Assumptions

- Checklist order + verdict format formalized by the source; TradingView
  publication-rule claim source-cited to the official repainting docs.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Style-first review | cosmetics before math | rule 1: fixed order |
| Mixed refactor + logic edit | two intents in one change | rule 2: split changes |
| Repaint unclassified | vague findings | rule 1 step 4: three-way verdict |
| Third-party stats trusted | no N/period/cost audit | rule 3: audit first |

## Dependencies

Optional: pine-version-intelligence (API checks), TA pillars (formula
canon), natural-language-to-math (logic checks),
repainting-and-lookahead (audit checklist), pine-performance-engineering
(perf audit), pine-code-architecture (architecture audit),
pine-debugging-and-testing (golden sets), project-knowledge-management +
pine-project-documentation (docs audit), research-to-code (signal-path
gate), backtesting-science (stats audit). Load only on their own triggers.

## Examples

- "Review my strategy before I publish" → rule 1 checklist → rule 4
  verdict.
- "Rename and extract safely" → rule 2 one-intent refactoring.
- Persian: «قبل از انتشار چک کن» → rule 1 checklist.

## Verification Criteria

- Checklist executed in fixed order; findings numbered.
- Repaint status explicitly classified (clean/by-design/bug).
- Refactors behavior-preserving with golden-set evidence.
- Verdict emitted in the fixed format.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-008` import from `skills/incoming/71-code-review-and-refactoring.md`.
- Layer VERIFICATION (function = structured post-implementation audit;
  same layer-from-function precedent as repainting-and-lookahead and
  pine-debugging-and-testing). The source's verdict-format fence preserved
  as rule prose per normalization convention (no code generated).
  Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `71-code-review-and-refactoring.md`
- Original source path: `skills/incoming/71-code-review-and-refactoring.md`
- Import batch: `batch-008`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-008)
