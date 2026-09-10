#!/usr/bin/env python3
"""Debug script to simulate the static_checks function from implement.pl"""

# Read the generated Pine source
with open('phase9_pine.pine', 'r') as f:
    src = f.read()

lines = src.split('\n')

# Simulate the grep in scalar context (returns count)
has_version = sum(1 for l in lines if l.startswith('//@version=6'))
print(f"has_version count: {has_version}")
print(f"has_version truthy: {bool(has_version)}")

has_indicator = sum(1 for l in lines if l.startswith('indicator('))
print(f"has_indicator count: {has_indicator}")
print(f"has_indicator truthy: {bool(has_indicator)}")

# Check if the S-NO-VERSION blocker would be triggered
if not has_version:
    print("BUG: S-NO-VERSION blocker would be triggered (FALSE POSITIVE)")
else:
    print("OK: S-NO-VERSION blocker would NOT be triggered")

# Now check the check_id issue
# In run_pipeline, findings are matched to check domains by check_id
# But static_checks, traceability_checks, and determinism_check don't set check_id
# So findings default to check_id='' which doesn't match any domain

print("\n--- Check ID Issue ---")
print("static_checks findings have no check_id -> defaults to ''")
print("traceability_checks findings have no check_id -> defaults to ''")
print("determinism_check findings have no check_id -> defaults to ''")
print("validate_input findings have no check_id -> defaults to ''")
print("validate_plan findings have no check_id -> defaults to ''")
print("\nIn run_pipeline, grep { ($_->{check_id}//'') eq $cid } @all_F")
print("Since check_id is '' for all findings, they don't match S02, S03, S08, S09, S10")
print("So all checks show 'pass' with empty findings, but blockers still exist")
