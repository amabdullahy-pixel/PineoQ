# Import Report — IR-batch-002-17

```yaml
report_id: IR-batch-002-17
import_batch: batch-002
original_filename: 17-linear-algebra.md
source_path: skills/incoming/17-linear-algebra.md
proposed_skill_id: linear-algebra
final_skill_id: linear-algebra
final_status: normalized
activation_status: eligible
primary_layer: QUANT
domains: [mathematics, matrices]
extracted_triggers:
  english: [covariance matrix, eigenvalues eigenvectors, PCA regime,
    matrix inverse, pseudo-inverse pinv, matrix multiply, vector dot product,
    rotation matrix]
  persian: [جبر خطی, ماتریس کوواریانس, مقدار و بردار ویژه, ضرب ماتریسی]
dependencies:
  mandatory: []
  optional: [mathematical-foundation, statistics-core, advanced-market-geometry,
    documentation-verification]
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
  - matrix namespace inventory consistent with v6 reference claims and with
    pine-data-structures limits (batch-001: 100k elements).
  - Eigen-decomposition API (eigenvalues/eigenvectors) consistent with the
    source's v6-era claims; UDT/matrix sort facts cross-checked in batch-001
    release-notes review.
  - DO-NOT-EXIST list (diff/dot/lu/chol/qr) preserved as a verify-before-use
    gate tied to documentation-verification (pending import) — an
    anti-hallucination device, not an assertion to relax.
repainting_findings: none in scope.
mtf_findings: none in scope.
runtime_performance_findings: 100k matrix cap + 500ms/bar covariance-loop budget recorded.
numerical_stability_findings: eigen ordering caveat, inv-singularity (det/pinv) guards recorded.
duplicate_findings: none.
overlap_findings:
  - pine-data-structures (batch-001): container mechanics vs algebra usage;
    relationship: complementary. recommended_action: keep_separate
  - statistics-core (pending import): covariance math depth expected there;
    relationship: expected complementary. recommended_action: no_action
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-002)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
