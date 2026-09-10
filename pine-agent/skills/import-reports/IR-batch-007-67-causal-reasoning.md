# Import Report — IR-batch-007-67

```yaml
report_id: IR-batch-007-67
import_batch: batch-007
original_filename: 67-causal-reasoning.md
source_path: skills/incoming/67-causal-reasoning.md
proposed_skill_id: causal-reasoning
final_skill_id: causal-reasoning
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [research-methods, epistemics]
extracted_triggers:
  english: [correlation vs causation markets, granger causality,
    confounder spurious correlation, bradford hill criteria,
    reflexivity edge decay, causal claim discipline]
  persian: [استدلال علّی, همبستگی و علیت, شبه‌همبستگی]
dependencies:
  mandatory: []
  optional: [statistical-testing, overfitting-and-robustness,
    regime-detection, repainting-and-lookahead, intermarket-analysis,
    market-microstructure, research-methodology, market-psychology,
    backtesting-science]
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
  - Granger sketch = nested rolling OLS — consistent with
    regression-correlation (batch-003) verified patterns; no invented
    built-ins.
repainting_findings: temporality (Bradford Hill axis) restates the repaint law — signal at t from data ≤ t, outcome t+h (repainting-and-lookahead).
mtf_findings: none in scope.
runtime_performance_findings: none in scope.
numerical_stability_findings: F-test/SSE comparisons flagged for small-sample caution (statistical-testing discipline).
duplicate_findings: none.
overlap_findings:
  - intermarket-analysis (batch-006): relationship map is contextual
    filters; causal-reasoning supplies the epistemic discipline — 56's
    common-mistake note ("correlation across regimes") directly consumed.
    relationship: complementary. recommended_action: dependency_relationship
  - regime-detection (batch-005): confounder conditioning via regime state.
    relationship: complementary. recommended_action: dependency_relationship
provenance_note:
  - Granger causality / Bradford Hill criteria recorded as academic
    provenance (encyclopedic sources, source-declared); adapted-to-trading
    axes preserved verbatim.
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-007)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
