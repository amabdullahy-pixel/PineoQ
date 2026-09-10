# Import Report — IR-batch-004-35

```yaml
report_id: IR-batch-004-35
import_batch: batch-004
original_filename: 35-trend-indicators.md
source_path: skills/incoming/35-trend-indicators.md
proposed_skill_id: trend-indicators
final_skill_id: trend-indicators
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [technical-analysis, trend]
extracted_triggers:
  english: [moving average family, EMA vs RMA Wilder, HMA formula,
    ALMA parameters, supertrend direction sign, ADX DMI,
    KAMA manual implementation, MA crossover lag]
  persian: [اندیکاتورهای روند, میانگین متحرک, سوپرترند, شاخص جهت‌دار ADX]
dependencies:
  mandatory: []
  optional: [technical-analysis-core, repainting-and-lookahead,
    regime-detection, optimization-and-calibration]
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
  - MA-family signatures verified by source against v6 reference; ta.kama
    DOES-NOT-EXIST preserved as verify-before-use gate (manual implementation
    provided).
  - IMPORT-TIME CORROBORATION (a): supertrend direction = −1 uptrend / +1
    downtrend confirmed by multiple independent sources, including one
    explicitly quoting the Pine v5/v6 reference statement and TradingView
    script descriptions using the same convention — the source's
    "counterintuitive sign" warning stands verified.
  - IMPORT-TIME CORROBORATION (b): ta.alma 5-parameter signature
    (series, length, offset, sigma, floor) — floor optional simple bool,
    default false — confirmed via a detailed v6-labeled reference listing;
    4-argument calls remain valid. Source's 5-param claim corroborated, not
    merely asserted.
repainting_findings: crossover-on-unconfirmed-bar repaint risk recorded with isconfirmed/[1] gating.
mtf_findings: none in scope.
runtime_performance_findings: HMA int-division behavior (odd lengths) recorded.
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - technical-analysis-core (same batch): classification vs implementation
    inventory; relationship: complementary. recommended_action: keep_separate
  - regime-detection (pending, 47): ADX/supertrend consumers expected there;
    relationship: expected complementary. recommended_action: no_action
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - Corroboration results documented in the skill's Import Notes; no rule
    altered.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-004)
recommended_action: no_action
next_action: eligible for Router discovery; resolves the batch-002/003
  pending pointer from numerical-methods.
```
