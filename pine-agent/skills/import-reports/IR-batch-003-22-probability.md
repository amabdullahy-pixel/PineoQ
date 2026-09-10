# Import Report — IR-batch-003-22

```yaml
report_id: IR-batch-003-22
import_batch: batch-003
original_filename: 22-probability.md
source_path: skills/incoming/22-probability.md
proposed_skill_id: probability
final_skill_id: probability
final_status: normalized
activation_status: eligible
primary_layer: QUANT
domains: [statistics, decision-theory]
extracted_triggers:
  english: [conditional probability, expected value EV,
    joint probability independence, Bayes updating, likelihood ratio,
    base rate, signal confidence]
  persian: [احتمال شرطی, ارزش مورد انتظار, به‌روزرسانی بیزی, نرخ پایه]
dependencies:
  mandatory: []
  optional: [statistical-testing, signal-fusion, performance-metrics, statistics-core]
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
  - var counting accumulators, integer→float casting in ratios, guarded
    division — consistent with pine-language-core (batch-001) semantics.
repainting_findings: none in scope (empirical estimators use committed historical data).
mtf_findings: none in scope.
runtime_performance_findings: lifetime/rolling counters are O(1) incremental state — consistent with numerical-methods guidance.
numerical_stability_findings: P(B)=0 and tiny-sample guards recorded.
duplicate_findings: none.
overlap_findings:
  - signal-fusion (pending import, 46): fusion architectures vs probability
    foundations; relationship: expected complementary.
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
