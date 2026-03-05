# Salesforce Labs Packaging Checklist

Use this checklist before each release candidate.

## Packaging Posture (Source of Truth)

- Release source: `package/`
- Org/demo source: `force-app/`
- `sfdx-project.json` default package directory must be `package`

Platform-native scope for this package:
- No Apex classes
- No Apex triggers
- No custom objects
- No custom fields
- Flow tagging policy: up to 3 matches each for Account/Product/Subject, capped at 8 total tags per insight

## Gate 1: Preflight

Run local checks:

```bash
./scripts/packaging/preflight.sh
```

Run org-aware checks:

```bash
./scripts/packaging/preflight.sh --target-org <org-alias>
```

Validates:
1. Default package path correctness.
2. Required metadata presence.
3. Platform-native guardrails.
4. Security hardening (no over-privileged packaged MI permission sets).
5. Required Agentforce for Life Sciences object availability in target org.
6. MedicalInsight/junction createability probe via Apex describe.

## Gate 2: Dry-Run Deploy Validation

```bash
./scripts/packaging/build-and-validate.sh --target-org <org-alias>
```

Runs:
1. Preflight
2. `sf project deploy start --source-dir package --dry-run --test-level RunLocalTests`

## Gate 3: Package Version Creation

```bash
./scripts/packaging/build-and-validate.sh \
  --target-org <org-alias> \
  --create-version true \
  --devhub-org <devhub-alias>
```

Runs:
1. Preflight
2. Dry-run deploy validation
3. `sf package version create` with code coverage

## Failure Handling

If any gate fails:
1. Fix `package/` metadata (not `force-app/`).
2. Re-run Gate 1 and Gate 2.
3. Retry version creation only when both pass.

## Admin Usability Readiness (Labs Review)

Before submission, verify:
- Installation guide is current and follows admin setup order.
- Permission set assignment steps are explicit.
- Agentforce action configuration for `MI_Capture_Medical_Insight` is documented.
- Subject taxonomy requirements (Active + `Other` fallback) are documented.
- Field user path is zero-training: dictate -> record created -> related tags visible.
