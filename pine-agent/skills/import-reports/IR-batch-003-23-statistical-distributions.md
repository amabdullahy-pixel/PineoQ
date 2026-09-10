# Import Report — IR-batch-003-23

```yaml
report_id: IR-batch-003-23
import_batch: batch-003
original_filename: 23-statistical-distributions.md
source_path: skills/incoming/23-statistical-distributions.md
proposed_skill_id: statistical-distributions
final_skill_id: statistical-distributions
final_status: normalized
activation_status: eligible
primary_layer: QUANT
domains: [statistics, distribution-modeling]
extracted_triggers:
  english: [normal distribution, log-normal, student-t fat tails,
    skewness kurtosis, normal CDF erf, probit inverse normal, tail risk]
  persian: [توزیع نرمال, دنباله‌های کلفت, چولگی و کشیدگی, توزیع‌های آماری]
dependencies:
  mandatory: []
  optional: [statistics-core, monte-carlo-and-resampling, statistical-testing,
    numerical-methods]
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
  - Negative claim preserved as verify-before-use gate: Pine has NO built-in
    erf/erfc/normal-CDF/quantile functions (same convention as the
    do-not-exist lists in skills 17/18).
  - Abramowitz–Stegun erf and Acklam probit constants preserved verbatim in
    meaning; implementation-integrity rule (Horner nesting verification)
    recorded.
repainting_findings: none in scope.
mtf_findings: none in scope.
runtime_performance_findings: manual-loop moments (skew/kurtosis) and approximation calls are O(window) — budget noted for large windows.
numerical_stability_findings: approximation error bounds (|ε|<1.5e-7 for A–S erf) recorded; silent-nesting-corruption failure case registered.
duplicate_findings: none.
overlap_findings:
  - statistics-core (same batch): robust stats consumption; relationship:
    complementary. recommended_action: dependency_relationship
  - monte-carlo-and-resampling (same batch): VaR simulation consumers;
    relationship: complementary. recommended_action: keep_separate
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
