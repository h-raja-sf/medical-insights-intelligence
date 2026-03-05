# Medical Insights Intelligence - Installation Guide

This guide is for admins setting up Medical Insights Intelligence for the first time.
Goal: install once, assign access, and allow field medical users to dictate insights with no extra training.

## 1) Prerequisites

Required:
- Salesforce Enterprise Edition or higher
- Agentforce for Life Sciences enabled

Required standard objects:
- `MedicalInsight`
- `Subject`
- `SubjectAssignment`
- `MedicalInsightProduct`
- `MedicalInsightAccount`
- `Product2`
- `Account`

## 2) Install the Package

1. Install from AppExchange into sandbox or production.
2. Use **Install for All Users**.
3. Wait for install completion.

## 3) Assign Permission Sets

Assign these from Setup -> Permission Sets:

- Field medical users: `Medical Insights - MSL User`

Important:
- `Medical Insights - MSL User` is required for users who dictate insights.

## 4) Prepare Subject Taxonomy (One-Time)

The flow matches subjects from `Subject` records.

Requirements:
- Subjects must be **Active**
- Include an active `Other` subject for fallback handling
- Use `Subject.Description` to store a business follow-up suggestion used in `TopicNames`
- Tagging limits are intentional: up to 3 Account tags, 3 Product tags, and 3 Subject tags, with a hard max of 8 total tags per insight

Recommended format for `Subject.Description`:
- One short, practical next step (for example: "Confirm dizziness frequency and impact on adherence at next visit.")

## 5) Configure Agentforce Action

This package includes the capture function.
You still need to wire it into your org's Agentforce Topics & Actions.

In Agentforce Topics & Actions:
1. Add/Update an action that calls `MI_Capture_Medical_Insight`
2. Map input values:
   - `utterance` -> raw user dictation text
   - `accountName` -> extracted provider/account name (if present)
   - `productName` -> extracted product name (if present)
   - `subjectName` -> extracted subject hint (if present)
   - `channel` -> `Agent`
3. Publish the updated agent config.

## 6) Validate End-to-End (10 minutes)

1. Impersonate or login as a field user with `Medical Insights - MSL User`.
2. Dictate a realistic message, for example:
   - "Aaron Morita is switching to Immunexis over Glucovance due to significantly lower reported dizziness in elderly patients."
3. Confirm:
   - A `MedicalInsight` record is created
   - `MedicalInsightAccount` related list has account linkage (when account matches)
   - `MedicalInsightProduct` related list has product linkage (when product matches)
   - `SubjectAssignment` related list has subject linkage (or `Other` fallback)
   - For multi-entity dictation, no more than 8 total tags are created (by design)
   - Long dictation stores full text in related Notes when content is truncated

## 7) Troubleshooting

No account or product tags:
- Verify exact names exist in `Account` / `Product2`.
- Verify field user has read access via assigned permission set and org sharing model.

No subject tag:
- Verify matching subject exists, is active, and is discoverable.
- Verify active `Other` subject exists for fallback.

Insight created but UX feels slow:
- Confirm the agent action is calling `MI_Capture_Medical_Insight`.

## 8) Packaging/Admin Validation Commands

From project root:

```bash
./scripts/packaging/preflight.sh
./scripts/packaging/preflight.sh --target-org <org-alias>
./scripts/packaging/build-and-validate.sh --target-org <org-alias>
```
