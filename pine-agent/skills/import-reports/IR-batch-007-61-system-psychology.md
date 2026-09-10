# Import Report — IR-batch-007-61

```yaml
report_id: IR-batch-007-61
import_batch: batch-007
original_filename: 61-system-psychology.md
source_path: skills/incoming/61-system-psychology.md
proposed_skill_id: system-psychology
final_skill_id: system-psychology
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [behavioral, system-design]
extracted_triggers:
  english: [drawdown tolerance operator, overtrading circuit breaker,
    signal frequency fit, alert fatigue, automation ladder,
    deployment readiness human]
  persian: [روانشناسی سیستم معاملاتی, تحمل افت سرمایه, معامله‌گری بیش از حد]
dependencies:
  mandatory: []
  optional: [position-sizing, monte-carlo-and-resampling,
    signal-engineering, risk-management, alerts-and-webhooks,
    tradingview-execution-model, strategy-engine, backtesting-science]
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
  - strategy.risk.max_cons_loss_days / strategy.risk.max_intraday_filled_orders
    — both within the six-function strategy.risk.* inventory VERIFIED in
    batch-003 (official Strategies page); circuit-breaker usage preserved.
  - ta.change(time("D")) daily-reset idiom and freq_once_per_bar_close alert
    discipline consistent with alerts-and-webhooks (batch-002) and
    execution-model (batch-001) verified facts.
repainting_findings: intrabar alerts for human-executed systems forbidden — close-confirmed signals mandatory (divergence prevention).
mtf_findings: none in scope.
runtime_performance_findings: none in scope.
numerical_stability_findings: none in scope (streak probability 1−W^L is design math).
duplicate_findings: none.
overlap_findings:
  - financial-mathematics (batch-003): resolves the batch-006 parked
    candidate {29↔61} — math of finance vs operator-system interface.
    relationship: related_but_distinct. recommended_action: no_action
  - position-sizing / risk-management (batches 003/004): tolerance-first
    sizing consumers. relationship: complementary.
    recommended_action: dependency_relationship
provenance_note:
  - Operator-tolerance/fatigue design recorded as practice methodology;
    Pine circuit-breaker facts cross-referenced from verified skills.
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - Source's illustrative Pine snippet preserved as prose + inline
    identifiers per normalization convention (no code generated).
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-007)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
