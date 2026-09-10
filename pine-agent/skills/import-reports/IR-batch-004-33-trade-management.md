# Import Report — IR-batch-004-33

```yaml
report_id: IR-batch-004-33
import_batch: batch-004
original_filename: 33-trade-management.md
source_path: skills/incoming/33-trade-management.md
proposed_skill_id: trade-management
final_skill_id: trade-management
final_status: normalized
activation_status: eligible
primary_layer: IMPLEMENTATION
domains: [strategies, exits]
extracted_triggers:
  english: [stop loss target, trailing stop, break-even move, R multiple targets,
    chandelier stop, structure stop, time stop, partial exit]
  persian: [حد ضرر و حد سود, حد ضرر متحرک, سیو سود پله‌ای, خروج بر اساس ساختار]
dependencies:
  mandatory: []
  optional: [strategy-engine, tradingview-execution-model,
    repainting-and-lookahead, regime-detection]
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
  - strategy.exit parameter-unit semantics (profit/loss ticks; limit/stop
    price; trail_*) consistent with batch-001 strategy-engine verified facts;
    ta.pivotlag confirmation semantics consistent with repainting-and-lookahead
    (batch-002).
repainting_findings: structure stops restricted to confirmed pivots; bar-close trailing updates for backtest consistency recorded.
mtf_findings: none in scope.
runtime_performance_findings: none in scope.
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - strategy-engine (batch-001): exit mechanics summary vs management design;
    relationship: complementary. recommended_action: keep_separate,
    resolved: true (batch-001 pending pointer resolved)
  - regime-detection (pending, 47): regime-responsive exits expected there;
    relationship: expected complementary. recommended_action: no_action
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-004)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
