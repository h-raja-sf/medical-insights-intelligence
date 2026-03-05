# Medical Insights Intelligence

Medical Insights Intelligence is a platform-native package for capturing Medical Insight dictations in Agentforce for Life Sciences and creating standard insight tags.

This package is intentionally lean:
- No Apex classes
- No custom objects
- No custom fields
- Uses only standard objects, flows, GenAI function metadata, layouts, and permission sets

## What It Does

When an Agentforce action calls `MI_Capture_Medical_Insight`, the flow `MI_Capture_Insight_Fast`:
- Creates the `MedicalInsight` record quickly
- Links matching `Account`, `Product2`, and `Subject` records through standard junctions
- Supports up to 3 matches each for Account/Product/Subject inputs
- Enforces a hard cap of 8 total links per insight for predictable performance
- Uses active `Subject` records only
- Falls back to `Subject = Other` (if present and active) when no subject match is found
- Truncates long content safely and stores full text in Notes when needed
- Returns a status payload to Agentforce immediately

## Package Contents

- Flow: `MI_Capture_Insight_Fast`
- GenAI Function: `MI_Capture_Medical_Insight` (invokes the flow)
- GenAI Plugin: `Insight_Log_Helper_MSL`
- Permission Sets:
  - `Medical Insights - MSL User`
- Medical Insight layout (optimized for dictation review + related lists)

## Required Standard Objects

- `MedicalInsight`
- `Subject`
- `SubjectAssignment`
- `MedicalInsightProduct`
- `MedicalInsightAccount`
- `Product2`
- `Account`

## Admin Quick Start

Use the full install sequence in [docs/INSTALLATION_GUIDE.md](docs/INSTALLATION_GUIDE.md).

Short version for first-time setup:
1. Install package.
2. Assign permission sets:
   - Field medical users: `Medical Insights - MSL User`
3. Ensure active `Subject` records exist for your taxonomy, including an active `Other` record for fallback.
4. Configure your Agentforce action to call `MI_Capture_Medical_Insight`.
5. Test with one dictation and verify account/product/subject related lists populate.

## Field User Experience

After admin setup, field medical users do not need a separate guide:
- User dictates insight in Agentforce
- Agent calls `MI_Capture_Medical_Insight`
- Insight is created and tagged
- User can open the Medical Insight record and review linked account/product/subject + notes

## Packaging Validation

Run these before a release candidate:

```bash
./scripts/packaging/preflight.sh
./scripts/packaging/preflight.sh --target-org <org-alias>
./scripts/packaging/build-and-validate.sh --target-org <org-alias>
```

See [docs/SALESFORCE_LABS_PACKAGING.md](docs/SALESFORCE_LABS_PACKAGING.md) for the full Labs checklist.
