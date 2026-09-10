# Import Report — IR-batch-006-51

```yaml
report_id: IR-batch-006-51
import_batch: batch-006
original_filename: 51-backtesting-science.md
source_path: skills/incoming/51-backtesting-science.md
proposed_skill_id: backtesting-science
final_skill_id: backtesting-science
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [backtesting, validation]
extracted_triggers:
  english: [backtest interpretation, bar magnifier, deep backtesting,
    slippage commission costs, lookahead survivorship selection bias,
    backtest validation gate]
  persian: [بک‌تست, سوگیری‌های بک‌تست, ذره‌بین کندل, هزینه و اسلیپیج]
dependencies:
  mandatory: []
  optional: [strategy-engine, repainting-and-lookahead,
    walk-forward-and-validation, overfitting-and-robustness,
    statistical-testing]
validation_results:
  unique_skill_id: pass
  clear_purpose: pass
  justified_primary_layer: pass
  valid_triggers: pass
  documented_inputs: pass
  documented_outputs: pass
  rules_documented: pass
  constraints_documented: pass
  assumptions_documented: pass
  dependencies_documented: pass
  ambiguities_recorded: pass
  missing_information_recorded: pass
  template_structure_followed: pass
  source_preserved: pass
pine_v6_findings:
  - Bar Magnifier `use_bar_magnifier = true` semantics + 200,000-LTF-bar
    budget INDEPENDENTLY RE-VERIFIED at import (official support article
    43000669285 + community corroboration of the exact 200k cap; coverage
    cutoff formula `last_bar_index − (200000 / LTFbarsPerChartBar)`
    preserved from source).
  - Deep Backtesting ~2M bars / 1M trades RE-VERIFIED (official blog
    "Deep Backtesting is out of beta" + 2026 guide); Premium+ gating and
    report-only results preserved.
  - v6 9,000-order historic cap with silent trimming — consistent with
    strategy-engine (batch-001, release-notes-verified).
  - Backtest ≠ realtime by default (bar-close execution unless
    calc_on_every_tick) — consistent with tradingview-execution-model
    (batch-001).
repainting_findings: lookahead bias routed to repainting-and-lookahead checklist as a mandatory validation-gate item.
mtf_findings: none in scope (magnifier LTF inspection is internal).
runtime_performance_findings: 200k LTF-bar magnifier budget + 9,000-order cap registered as hard platform budgets.
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - strategy-engine (batch-001): resolves the batch-001 parked candidate
    {09↔51} — execution mechanics vs interpretation methodology.
    relationship: related_but_distinct (complementary).
    recommended_action: keep_separate
  - walk-forward-and-validation / overfitting-and-robustness (same batch):
    downstream gates. relationship: complementary.
    recommended_action: dependency_relationship
provenance_note:
  - Execution-assumption defaults verified against official support
    articles (Bar Magnifier, Deep Backtesting) — import re-verified 2026-09.
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-006)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
