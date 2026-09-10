# Import Report — IR-batch-001-01

```yaml
report_id: IR-batch-001-01
import_batch: batch-001
original_filename: 01-pine-language-core.md
source_path: skills/incoming/01-pine-language-core.md
proposed_skill_id: pine-language-core
final_skill_id: pine-language-core
final_status: normalized
activation_status: eligible
primary_layer: CORE
domains: [pine-syntax]
extracted_triggers:
  english: [pine syntax, variable declaration, reassignment operator, var vs varip,
    lazy and or short circuit, history-reference operator, user-defined function,
    method overloading, local scope rules, switch default branch, loop timeout]
  persian: [سینتکس پایین اسکریپت, تعریف متغیر, تفاوت var و varip, ارجاع به تاریخچه,
    تابع کاربر, متد, محدوده محلی, حلقه و مدت اجرا]
dependencies:
  mandatory: []
  optional: [pine-type-system, pine-data-structures, pine-functions-libraries, pine-v6]
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
  - Lazy and/or, strict bool (no na), history-operator restrictions, var/varip/once
    semantics, conditional ta.* call trap, loop limits — all v6-consistent; the
    once construct was confirmed against official release notes (Aug 2026).
  - Source self-declares verification against official docs; no contradiction found.
repainting_findings: none directly; conditional ta.* history corruption flagged as an indirect repaint-adjacent failure mode (deferral to repainting-and-lookahead).
mtf_findings: none in scope.
runtime_performance_findings: loop 500 ms/bar, script 20 s/40 s, 1000 vars/scope recorded as constraints.
numerical_stability_findings: none in scope.
duplicate_findings: none — closest neighbors are pine-type-system and pine-v6, both complementary (different scopes).
overlap_findings:
  - pine-v6 covers migration + release additions; rule-level overlap is minimal and
    cross-referenced rather than duplicated. relationship: complementary.
    recommended_action: keep_separate
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings (faithful; technical terms untranslated).
  - Converted implicit scope boundaries into explicit Constraints/Dependencies.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-001)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
