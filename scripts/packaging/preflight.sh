#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

TARGET_ORG=""

usage() {
  cat <<USAGE
Usage: $0 [--target-org <org-alias>]

Checks packaging readiness for Salesforce Labs:
- package/ source set and sfdx-project defaults
- required metadata exists in package/
- optional org schema preflight (if --target-org is provided)
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-org)
      TARGET_ORG="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

fail() {
  echo "[FAIL] $1"
  exit 1
}

info() {
  echo "[INFO] $1"
}

pass() {
  echo "[PASS] $1"
}

if ! command -v sf >/dev/null 2>&1; then
  fail "Salesforce CLI (sf) is not installed or not in PATH"
fi

if ! command -v jq >/dev/null 2>&1; then
  fail "jq is required for preflight"
fi

cd "$PROJECT_DIR"

DEFAULT_PATH=$(jq -r '.packageDirectories[] | select(.default==true) | .path' sfdx-project.json)
if [[ "$DEFAULT_PATH" != "package" ]]; then
  fail "Default package directory must be 'package' (found: '$DEFAULT_PATH')"
fi
pass "sfdx-project default package directory is 'package'"

# Platform-native packaging posture: no Apex classes/triggers/custom objects/fields.
if find package/main/default/classes -type f \( -name '*.cls' -o -name '*.cls-meta.xml' \) | grep -q .; then
  fail "Package path must not contain Apex classes (platform-native package requirement)"
fi
pass "No Apex classes in package path"

if [[ -d package/main/default/triggers ]]; then
  if find package/main/default/triggers -type f \( -name '*.trigger' -o -name '*.trigger-meta.xml' \) | grep -q .; then
    fail "Package path must not contain Apex triggers (platform-native package requirement)"
  fi
fi
pass "No Apex triggers in package path"

if find package/main/default/objects -maxdepth 1 -mindepth 1 -type d -name '*__c' | grep -q .; then
  fail "Custom objects detected in package path (platform-native package requirement)"
fi
pass "No custom objects in package path"

if find package/main/default/objects -path '*/fields/*.field-meta.xml' -type f | grep -q .; then
  fail "Custom field metadata detected in package path (platform-native package requirement)"
fi
pass "No custom fields in package path"

if [[ -f package/main/default/flows/Insight_Trigger_Flow.flow-meta.xml ]]; then
  fail "Deprecated flow Insight_Trigger_Flow must not be packaged"
fi
pass "Deprecated flow metadata excluded from package path"

if [[ -d package/main/default/genAiPlannerBundles ]] && find package/main/default/genAiPlannerBundles -type f | grep -q .; then
  fail "Agent planner bundle metadata must not be packaged (prevents active-agent deploy failures)"
fi
pass "Agent planner bundle metadata excluded from package path"

for required_file in \
  "package/main/default/flows/MI_Capture_Insight_Fast.flow-meta.xml" \
  "package/main/default/genAiFunctions/MI_Capture_Medical_Insight/MI_Capture_Medical_Insight.genAiFunction-meta.xml" \
  "package/main/default/permissionsets/MI_MSL_User.permissionset-meta.xml"; do
  if [[ ! -f "$required_file" ]]; then
    fail "Missing required package metadata: $required_file"
  fi
done
pass "Required package metadata files are present"

# Hardening checks for Labs packaging posture
if rg -n "Raw JSON|raw JSON|Stack trace:" package/main/default/classes/MI_*.cls >/dev/null 2>&1; then
  fail "Sensitive/debug logging found in package MI_* classes (Raw JSON/Stack trace)"
fi
pass "No sensitive raw payload/stack logging found in package MI_* classes"

if find package/main/default/objects/MedicalInsight/fields -maxdepth 1 -type f -name 'Temp_Debug_Model_Json__c.field-meta.xml' | grep -q .; then
  fail "Debug-only field Temp_Debug_Model_Json__c must not be packaged"
fi
pass "Debug-only fields are excluded from package metadata"

if rg -n "<name>(ManageUsers|ViewAllData)</name>" package/main/default/permissionsets/MI_*.permissionset-meta.xml >/dev/null 2>&1; then
  fail "Over-privileged user permissions detected in packaged MI permission sets (ManageUsers/ViewAllData)"
fi
pass "Packaged MI permission sets exclude ManageUsers/ViewAllData"

# Drift check for MI_* classes between package and force-app (if present)
DRIFT=0
while IFS= read -r class_file; do
  class_name="$(basename "$class_file")"
  other_file="force-app/main/default/classes/$class_name"
  if [[ -f "$other_file" ]] && ! cmp -s "$class_file" "$other_file"; then
    echo "[WARN] Drift detected: $class_file vs $other_file"
    DRIFT=1
  fi
done < <(find package/main/default/classes -maxdepth 1 -type f -name 'MI_*')

if [[ "$DRIFT" -eq 0 ]]; then
  pass "No MI_* class drift between package/ and force-app/"
else
  info "Drift warnings were found. Package builds still use package/ as source of truth."
fi

if [[ -z "$TARGET_ORG" ]]; then
  pass "Local packaging preflight completed"
  exit 0
fi

info "Running org schema preflight against '$TARGET_ORG'"
sf org display --target-org "$TARGET_ORG" >/dev/null
pass "Target org is reachable"

REQUIRED_OBJECTS=(
  "MedicalInsight"
  "Subject"
  "SubjectAssignment"
  "MedicalInsightProduct"
  "MedicalInsightAccount"
  "Product2"
  "Account"
)

for obj in "${REQUIRED_OBJECTS[@]}"; do
  if sf sobject describe --target-org "$TARGET_ORG" --sobject "$obj" --json >/dev/null 2>&1; then
    pass "Object available: $obj"
  else
    fail "Required object not available: $obj"
  fi
done

APEX_FILE="$(mktemp /tmp/mi_preflight_XXXXXX.apex)"
cat > "$APEX_FILE" <<'APEX'
Schema.SObjectType miType = Schema.getGlobalDescribe().get('MedicalInsight');
if (miType == null) {
    throw new IllegalArgumentException('MedicalInsight is missing');
}
Schema.DescribeSObjectResult miDescribe = miType.getDescribe();
if (!miDescribe.isCreateable()) {
    throw new IllegalArgumentException('MedicalInsight is not createable');
}

Map<String, Schema.SObjectField> fields = miDescribe.fields.getMap();
for (String requiredField : new List<String>{'Content','SourceType'}) {
    if (!fields.containsKey(requiredField) || !fields.get(requiredField).getDescribe().isCreateable()) {
        throw new IllegalArgumentException('Required createable field missing: ' + requiredField);
    }
}

for (String junctionObject : new List<String>{'SubjectAssignment','MedicalInsightProduct','MedicalInsightAccount'}) {
    Schema.SObjectType jType = Schema.getGlobalDescribe().get(junctionObject);
    if (jType == null || !jType.getDescribe().isCreateable()) {
        throw new IllegalArgumentException('Junction object not createable: ' + junctionObject);
    }
}

System.debug('MI_PREFLIGHT_OK');
APEX

if sf apex run --target-org "$TARGET_ORG" --file "$APEX_FILE" >/dev/null 2>&1; then
  pass "Apex describe probe passed"
else
  rm -f "$APEX_FILE"
  fail "Apex describe probe failed (missing permissions/fields/schema mismatches)"
fi

rm -f "$APEX_FILE"
pass "Org packaging preflight completed"
