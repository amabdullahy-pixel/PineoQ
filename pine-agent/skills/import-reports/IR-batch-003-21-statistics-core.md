# Import Report — IR-batch-003-21

```yaml
report_id: IR-batch-003-21
import_batch: batch-003
original_filename: 21-statistics-core.md
source_path: skills/incoming/21-statistics-core.md
proposed_skill_id: statistics-core
final_skill_id: statistics-core
final_status: normalized
activation_status: eligible
primary_layer: QUANT
domains: [statistics, pine-mapping]
extracted_triggers:
  english: [descriptive statistics, stdev biased or sample,
    mean absolute deviation ta.dev, percentile vs percentrank, z-score,
    MAD robust, IQR outlier fences]
  persian: [آمار توصیفی, انحراف معیار, صدک و رتبه صدکی, نمره استاندارد z]
dependencies:
  mandatory: []
  optional: [mathematical-foundation, numerical-methods,
    statistical-distributions, time-series-analysis]
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
  - All ta.* signatures (sma/median/mode/cog/stdev/variance/dev/range/tr/
    percentile_linear_interpolation/percentile_nearest_rank/percentrank)
    consistent with v6 reference claims of the source and with previously
    registered skills (e.g., ta.dev semantics, biased flag).
repainting_findings: none in scope.
mtf_findings: none in scope.
runtime_performance_findings: none in scope.
numerical_stability_findings: flat-window z-score division risk cross-referenced to numerical-methods (batch-002).
duplicate_findings: none.
overlap_findings:
  - linear-algebra (batch-002): covariance construction pointer resolved —
    depth here. relationship: complementary. recommended_action: keep_separate
  - statistical-distributions (same batch): robust-stats vs distribution
    shapes; relationship: complementary. recommended_action: dependency_relationship
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
next_action: eligible for Router discovery; resolves the batch-002
  pending-dependency pointer from linear-algebra.
```
