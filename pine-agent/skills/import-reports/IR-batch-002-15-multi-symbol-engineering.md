# Import Report — IR-batch-002-15

```yaml
report_id: IR-batch-002-15
import_batch: batch-002
original_filename: 15-multi-symbol-engineering.md
source_path: skills/incoming/15-multi-symbol-engineering.md
proposed_skill_id: multi-symbol-engineering
final_skill_id: multi-symbol-engineering
final_status: normalized
activation_status: eligible
primary_layer: IMPLEMENTATION
domains: [multi-symbol, data-acquisition]
extracted_triggers:
  english: [request another symbol, benchmark request, relative strength,
    correlation with index, ticker.new ticker.modify, request.financial,
    request.economic, request.quandl removed, cross-exchange alignment]
  persian: [دیتای نماد دیگر, قدرت نسبی, همبستگی با شاخص, فیلتر بین‌بازاری,
    هم‌ترازی سشن‌ها]
dependencies:
  mandatory: []
  optional: [mtf-engineering, repainting-and-lookahead, data-integrity, pine-v6]
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
  - request.financial/economic semantics, ticker construction APIs, 40/64
    request cap — consistent with batch-001-verified facts.
  - request.quandl() REMOVED — negative claim preserved as a forbidden-API gate.
  - request.footprint 2026-01 addition independently confirmed during batch-001
    import; source claim consistent.
repainting_findings: defers every request's repaint pattern to repainting-and-lookahead/mtf-engineering — recorded as a hard dependency-on-behavior.
mtf_findings: HTF request patterns consumed; session alignment across exchanges registered here.
runtime_performance_findings: request-budget discipline (reuse duplicates, precompute list, guard optional symbols) recorded.
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - mtf-engineering (batch-002): TF mechanics vs symbol engineering;
    relationship: complementary. recommended_action: keep_separate
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
