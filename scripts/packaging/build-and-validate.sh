#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

TARGET_ORG=""
DEVHUB_ORG=""
PACKAGE_NAME="Medical Insights Intelligence"
CREATE_VERSION="false"
WAIT_MINUTES="30"
SKIP_PREFLIGHT="false"

usage() {
  cat <<USAGE
Usage: $0 [options]

Options:
  --target-org <alias>      Run dry-run deploy validation against org
  --devhub-org <alias>      Dev Hub alias for package version creation
  --package-name <name>     Package name or alias (default: Medical Insights Intelligence)
  --create-version <bool>   true|false, create 2GP version (default: false)
  --wait-minutes <int>      Wait time for package version create (default: 30)
  --skip-preflight <bool>   true|false, skip preflight checks (default: false)
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-org)
      TARGET_ORG="${2:-}"
      shift 2
      ;;
    --devhub-org)
      DEVHUB_ORG="${2:-}"
      shift 2
      ;;
    --package-name)
      PACKAGE_NAME="${2:-}"
      shift 2
      ;;
    --create-version)
      CREATE_VERSION="${2:-false}"
      shift 2
      ;;
    --wait-minutes)
      WAIT_MINUTES="${2:-30}"
      shift 2
      ;;
    --skip-preflight)
      SKIP_PREFLIGHT="${2:-false}"
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

info() {
  echo "[INFO] $1"
}

fail() {
  echo "[FAIL] $1"
  exit 1
}

cd "$PROJECT_DIR"

if ! command -v sf >/dev/null 2>&1; then
  fail "Salesforce CLI (sf) is not installed or not in PATH"
fi

if [[ "$(echo "$SKIP_PREFLIGHT" | tr '[:upper:]' '[:lower:]')" != "true" ]]; then
  info "Running packaging preflight"
  PREFLIGHT_CMD=("$SCRIPT_DIR/preflight.sh")
  if [[ -n "$TARGET_ORG" ]]; then
    PREFLIGHT_CMD+=("--target-org" "$TARGET_ORG")
  fi
  "${PREFLIGHT_CMD[@]}"
else
  info "Skipping preflight (--skip-preflight true)"
fi

if [[ -n "$TARGET_ORG" ]]; then
  info "Running dry-run deploy validation against $TARGET_ORG"
  sf project deploy start \
    --target-org "$TARGET_ORG" \
    --source-dir package \
    --dry-run \
    --test-level RunLocalTests \
    --wait 30
  info "Dry-run deploy validation passed"
else
  info "No --target-org provided, skipping deploy validation"
fi

if [[ "$(echo "$CREATE_VERSION" | tr '[:upper:]' '[:lower:]')" != "true" ]]; then
  info "Skipping package version creation (--create-version false)"
  exit 0
fi

if [[ -z "$DEVHUB_ORG" ]]; then
  fail "--devhub-org is required when --create-version true"
fi

info "Creating package version for '$PACKAGE_NAME' via Dev Hub '$DEVHUB_ORG'"
VERSION_JSON=$(sf package version create \
  --target-dev-hub "$DEVHUB_ORG" \
  --package "$PACKAGE_NAME" \
  --code-coverage \
  --installation-key-bypass \
  --wait "$WAIT_MINUTES" \
  --json)

STATUS=$(echo "$VERSION_JSON" | jq -r '.status')
if [[ "$STATUS" != "0" ]]; then
  echo "$VERSION_JSON"
  fail "Package version creation failed"
fi

REQUEST_ID=$(echo "$VERSION_JSON" | jq -r '.result.Id // empty')
VERSION_ID=$(echo "$VERSION_JSON" | jq -r '.result.SubscriberPackageVersionId // empty')

info "Package version create request id: ${REQUEST_ID:-unknown}"
info "Subscriber package version id: ${VERSION_ID:-unknown}"

if [[ -n "$VERSION_ID" ]]; then
  info "Install URL: https://login.salesforce.com/packaging/installPackage.apexp?p0=$VERSION_ID"
fi

info "Build and validation completed"
