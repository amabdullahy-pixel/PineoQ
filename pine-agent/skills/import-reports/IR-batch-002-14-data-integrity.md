# Import Report — IR-batch-002-14

```yaml
report_id: IR-batch-002-14
import_batch: batch-002
original_filename: 14-data-integrity.md
source_path: skills/incoming/14-data-integrity.md
proposed_skill_id: data-integrity
final_skill_id: data-integrity
final_status: normalized
activation_status: eligible
primary_layer: IMPLEMENTATION
domains: [data-integrity, sessions-timezones]
extracted_triggers:
  english: [na handling, missing bars gaps, session filter, timezone bug,
    syminfo.timezone, holiday gaps, illiquid symbols, zero-volume bars, fixnan]
  persian: [مدیریت مقدار na, کندل‌های غایب و گپ, فیلتر سشن, باگ منطقه زمانی,
    تعطیلات بازار, کم‌نقدینگی]
dependencies:
  mandatory: []
  optional: [mtf-engineering, multi-symbol-engineering, repainting-and-lookahead,
    pine-type-system]
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
  - v6 strict bool/na rules (na/nz/fixnan reject bools; tri-state via int
    codes) consistent with pine-type-system (batch-001) — cross-referenced,
    not duplicated.
  - Session/time/bar-merging semantics per official docs cited by source; no
    contradictions found.
repainting_findings: gaps_on/na semantics and session-boundary na sources recorded — feeds repaint-adjacent data issues to repainting-and-lookahead.
mtf_findings: request gaps semantics consumed from/with mtf-engineering.
runtime_performance_findings: none in scope.
numerical_stability_findings: nz-on-price corruption class recorded (fake crashes).
duplicate_findings: none.
overlap_findings:
  - pine-type-system (batch-001): na/bool type rules vs data semantics;
    relationship: complementary. recommended_action: keep_separate
  - multi-symbol-engineering (batch-002): cross-market alignment depth lives
    there; session/na foundation here. relationship: complementary.
    recommended_action: keep_separate
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
