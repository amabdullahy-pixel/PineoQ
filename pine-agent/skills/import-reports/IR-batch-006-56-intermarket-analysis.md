# Import Report — IR-batch-006-56

```yaml
report_id: IR-batch-006-56
import_batch: batch-006
original_filename: 56-intermarket-analysis.md
source_path: skills/incoming/56-intermarket-analysis.md
proposed_skill_id: intermarket-analysis
final_skill_id: intermarket-analysis
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [market-context, correlations]
extracted_triggers:
  english: [DXY dollar index filter, yields equities relationship,
    VIX stress regime, correlation regime gating, risk on risk off,
    gold oil proxy]
  persian: [تحلیل بین‌بازاری, رابطه دلار و طلا, رژیم همبستگی]
dependencies:
  mandatory: []
  optional: [multi-symbol-engineering, data-integrity,
    repainting-and-lookahead, regime-detection, macro-economics]
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
  - request.security legs + ta.correlation rolling windows — consistent
    with multi-symbol-engineering (batch-002) and statistics-core
    (batch-003) verified inventories.
  - Symbol-ID table preserved as needs-verify-per-plan (not independently
    verifiable across account plans; handled by mandatory live checks —
    same discipline as PCR IDs in market-psychology, same batch).
repainting_findings: HTF legs must use the non-repaint request.security pattern (mtf-engineering / repainting-and-lookahead).
mtf_findings: every intermarket leg = 1 unique request (budget 40, multi-symbol-engineering); "1D" alignment to dodge session mismatch (data-integrity).
runtime_performance_findings: request-budget accounting per leg.
numerical_stability_findings: correlation thresholds recalibrated per window (regime drift documented).
duplicate_findings: none.
overlap_findings:
  - macro-economics (same batch): rates/CPI context feeds the same regime
    gating. relationship: complementary.
    recommended_action: dependency_relationship
  - regime-detection (batch-005): stress regimes as one axis of the
    composite regime engine. relationship: complementary.
    recommended_action: dependency_relationship
provenance_note:
  - Relationship map recorded as contextual heuristics to falsify
    (source-declared, not mechanical laws); symbol table needs-verify.
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-006)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
