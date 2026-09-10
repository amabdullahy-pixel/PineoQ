# Import Report — IR-batch-003-25

```yaml
report_id: IR-batch-003-25
import_batch: batch-003
original_filename: 25-statistical-testing.md
source_path: skills/incoming/25-statistical-testing.md
proposed_skill_id: statistical-testing
final_skill_id: statistical-testing
final_status: normalized
activation_status: eligible
primary_layer: QUANT
domains: [statistics, hypothesis-testing]
extracted_triggers:
  english: [hypothesis testing, p-value, confidence interval, Wilson interval,
    t-test of mean, chi-square test, stationarity test, multiple testing,
    p-hacking]
  persian: [آزمون فرض, ارزش p, بازه اطمینان, چندآزمونی]
dependencies:
  mandatory: []
  optional: [statistical-distributions, overfitting-and-robustness,
    walk-forward-and-validation, probability]
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
  - Negative claims preserved as verify-before-use gates: no built-in
    hypothesis-test functions; formal ADF test NOT available.
  - Wilson interval and manual t/chi-square implementations preserved
    verbatim in meaning.
repainting_findings: none in scope.
mtf_findings: none in scope.
runtime_performance_findings: none in scope (small-sample table constants preferred over loops).
numerical_stability_findings: serial-correlation/overlapping-N caveat recorded as an estimation-validity guard.
duplicate_findings: none.
overlap_findings:
  - overfitting-and-robustness (pending import, 54): multiple-testing depth
    expected there; relationship: expected complementary.
    recommended_action: no_action
  - walk-forward-and-validation (pending import, 53): OOS methodology expected
    there; relationship: expected complementary. recommended_action: no_action
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-003)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
