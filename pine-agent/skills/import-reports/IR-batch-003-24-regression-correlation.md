# Import Report — IR-batch-003-24

```yaml
report_id: IR-batch-003-24
import_batch: batch-003
original_filename: 24-regression-correlation.md
source_path: skills/incoming/24-regression-correlation.md
proposed_skill_id: regression-correlation
final_skill_id: regression-correlation
final_status: normalized
activation_status: eligible
primary_layer: QUANT
domains: [statistics, trend-fitting]
extracted_triggers:
  english: [correlation Pearson, covariance, least squares regression,
    R squared, residuals, autocorrelation, regression channel, linreg offset]
  persian: [همبستگی, کوواریانس, رگرسیون خطی, خودهمبستگی, کانال رگرسیون]
dependencies:
  mandatory: []
  optional: [statistics-core, time-series-analysis, statistical-arbitrage,
    analytical-geometry]
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
  - ta.correlation/ta.linreg offset semantics verified against v6 reference by
    the source; manual OLS guards (den≠0) consistent with numerical-methods.
  - linreg-offset-is-window-internal (not history) recorded as a constraint.
repainting_findings: none in scope.
mtf_findings: none in scope.
runtime_performance_findings: manual OLS is O(len) per bar via loop — within 500ms budget for typical len; noted.
numerical_stability_findings: den≠0 guard, R² computation stability, spurious-regression guard recorded.
duplicate_findings: none.
overlap_findings:
  - analytical-geometry (batch-002): channel drawing vs fit math;
    relationship: complementary. recommended_action: keep_separate
  - statistical-arbitrage (pending import, 50): cointegration/spread depth
    expected there; relationship: expected related_but_distinct.
    recommended_action: no_action
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
