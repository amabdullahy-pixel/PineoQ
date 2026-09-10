# Import Report — IR-batch-001-05

```yaml
report_id: IR-batch-001-05
import_batch: batch-001
original_filename: 05-pine-v6.md
source_path: skills/incoming/05-pine-v6.md
proposed_skill_id: pine-v6
final_skill_id: pine-v6
final_status: normalized
activation_status: eligible
primary_layer: CORE
domains: [pine-syntax, version-compatibility]
extracted_triggers:
  english: [pine v6, version 6 migration, v5 to v6, dynamic requests, strict booleans,
    lazy and or, negative array indices, order trimming 9000, timeframe.period 1D,
    transp removed, when removed]
  persian: [پایین اسکریپت نسخه ۶, مهاجرت نسخه ۵ به ۶, تغییرات نسخه ششم, درخواست‌های داینامیک]
dependencies:
  mandatory: []
  optional: [pine-version-intelligence, pine-language-core, pine-type-system]
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
  - Import-time verification against official TradingView release notes (2026-09):
    CONFIRMED — once conditional structure (Aug 2026; block executes once when
    condition first true on a closed bar), request.footprint() (Jan 2026),
    multiline strings (Apr 2026), UDT sort/binary search via sort_field
    (Apr + Aug 2026).
  - NOT PRESENT IN SOURCE (found in release notes, recorded as missing
    information — not invented into rules): July 2026 calc_on_every_history_tick
    strategy parameter; strategy Properties/report UI reorganization (Bar
    detalization replacing Bar Magnifier UI, leverage inputs replacing margin
    inputs, Order execution delay input); automatic-parentheses editor feature.
  - All v6-defining changes listed by the source (dynamic requests, strict
    booleans, lazy and/or, negative indices, order trimming, timeframe.period,
    const int division, [] restrictions, when/transp removal, loop boundary) are
    consistent with the migration-guide era facts the source cites.
repainting_findings: none directly; dynamic-requests audit requirement flagged for repaint-sensitive MTF use (deferral to repainting-and-lookahead / mtf-engineering).
mtf_findings: dynamic request behavior affects MTF designs — flagged for mtf-engineering consistency on its import.
runtime_performance_findings: platform limits recorded (20s/40s, 500ms/loop, 64 plots, drawings 500/500/500/100/9, request 40/64, intrabars 100K–200K plan-gated, 127 tuple elements, 1000 vars/scope).
numerical_stability_findings: const int division → float noted; no other numeric issues in scope.
duplicate_findings: none — pine-version-intelligence is the verification process; pine-v6 is the curated fact base.
overlap_findings:
  - pine-version-intelligence: verification pipeline vs curated facts;
    relationship: complementary. recommended_action: dependency_relationship
  - pine-language-core / pine-type-system: overlap limited to individual facts
    (lazy and/or, bool na) that each need locally; relationship: complementary.
    recommended_action: keep_separate
ambiguities:
  - Source's post-release-additions list may be non-exhaustive vs live release
    notes (evidenced by the July 2026 gap). Rule framing already defers unknown
    facts to pine-version-intelligence; treated as non-blocking.
missing_information:
  - July 2026 release-note items (calc_on_every_history_tick; strategy UI
    changes; automatic parentheses editor) absent from source — documented in
    the normalized Skill's Missing Information section for a future source
    revision.
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - Documented (did not apply) the July 2026 release-note gap as missing
    information; no rule rewritten.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-001)
recommended_action: keep_separate
next_action: eligible for Router discovery; suggest future source revision to
  fold in July 2026 items (owner: source author, not import).
```
