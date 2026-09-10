# Import Report — IR-batch-004-31

```yaml
report_id: IR-batch-004-31
import_batch: batch-004
original_filename: 31-position-sizing.md
source_path: skills/incoming/31-position-sizing.md
proposed_skill_id: position-sizing
final_skill_id: position-sizing
final_status: normalized
activation_status: eligible
primary_layer: IMPLEMENTATION
domains: [risk-control, strategies]
extracted_triggers:
  english: [fixed fractional sizing, ATR volatility sizing, Kelly criterion,
    anti-martingale, position size from stop, qty calculation]
  persian: [سایز پوزیشن, ریسک ثابت درصدی, کریتری کلی, آنتی مارتینگل]
dependencies:
  mandatory: []
  optional: [risk-management, strategy-engine, statistical-testing, regime-detection]
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
  - strategy.equity / strategy.entry qty semantics consistent with
    strategy-engine (batch-001) and performance-metrics (same batch) verified
    names; floor-rounding guards consistent with numerical-methods.
repainting_findings: none in scope.
mtf_findings: none in scope.
runtime_performance_findings: none in scope.
numerical_stability_findings: stopDist>0 guard and floor rounding recorded as mandatory guards.
duplicate_findings: none.
overlap_findings:
  - risk-management (batch-003): sizing math vs risk-control design —
    deliberate division of labor; relationship: complementary.
    recommended_action: dependency_relationship, resolved: true
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Layer decision (IMPLEMENTATION vs source category "Financial Math & Risk")
    recorded per import rules — consistent with risk-management.
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-004)
recommended_action: no_action
next_action: eligible for Router discovery; resolves the batch-003
  pending-dependency pointer from risk-management.
```
