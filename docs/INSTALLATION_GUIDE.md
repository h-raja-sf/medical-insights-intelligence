# Medical Insights Intelligence - Installation Guide

## Overview
Medical Insights Intelligence transforms how Life Sciences organizations capture, analyze, and act on field intelligence from Medical Science Liaisons (MSLs) and field medical teams. Using Agentforce AI, this solution automatically extracts subjects, products, and accounts from unstructured insight text and links them to standard Life Sciences Cloud objects.

## Prerequisites

### Required Salesforce Editions
- **Enterprise Edition** or higher
- **Life Sciences Cloud** license required
- **Agentforce** enabled (for AI-powered insight capture)

### Required Objects
This package uses standard Life Sciences Cloud objects:
- `MedicalInsight` - Core insight record
- `Subject` - Topic taxonomy
- `SubjectAssignment` - Junction for insight-subject relationships
- `MedicalInsightProduct` - Junction for insight-product relationships
- `MedicalInsightAccount` - Junction for insight-account (HCP) relationships
- `Product2` - Standard product catalog
- `Account` - Healthcare providers (HCPs)

### User Permissions
- System Administrator access for installation
- Salesforce Flow enabled
- Apex classes enabled

---

## Installation Steps

### Step 1: Install the Package

1. **Access the AppExchange Listing**
   - Navigate to Salesforce AppExchange
   - Search for "Medical Insights Intelligence"
   - Click **Get It Now**

2. **Choose Installation Location**
   - Select **Install in Production** or **Install in Sandbox**
   - Log in with your System Administrator credentials
   - Click **Confirm and Install**

3. **Select Installation Option**
   - Choose: **Install for All Users** (recommended)
   - Click **Install**
   - Wait for installation to complete (typically 5-10 minutes)

4. **Approve Third-Party Access**
   - Review the package access requirements
   - Check: "Yes, grant access to these third-party web sites"
   - Click **Continue**

### Step 2: Post-Installation Configuration

#### A. Assign Permission Sets

Assign users to the appropriate permission set based on their role:

1. Navigate to **Setup → Users → Permission Sets**
2. Find and assign the relevant permission set:
   - **Medical Insights - Administrator**: Full admin access for setup and configuration
   - **Medical Insights - MSL User**: Field users who capture insights via Agentforce
   - **Medical Insights - Operations Manager**: Analytics and reporting access

**To assign:**
- Open the permission set
- Click **Manage Assignments**
- Click **Add Assignments**
- Select users and click **Assign**

#### B. Activate Flows

1. Navigate to **Setup → Process Automation → Flows**
2. Activate the following flows:
   - `Insight_Trigger_Flow` - Orchestrates AI tagging pipeline
   - `MI_Insight_Theme_Summary_Flow` - Generates AI summaries and extracts tags

**To activate:**
- Click on the flow name
- Click **Activate**
- Confirm activation

#### C. Configure Agentforce Prompt Templates

1. Navigate to **Setup → Prompt Builder → Prompt Templates**
2. Locate: `Medical_Insight_Tagger`
3. Review the prompt configuration
4. Ensure the following resources are connected:
   - **MI_SubjectOptionsBuilder**: Builds available subjects for AI
   - **MI_ProductOptionsBuilder**: Builds available products for AI
   - **MI_AccountOptionsBuilder**: Builds available accounts for AI

5. Test the prompt:
   - Click **Preview**
   - Enter sample insight text
   - Verify JSON output includes subjects, products, accounts arrays

### Step 3: Generate Sample Data (Optional but Recommended)

To quickly test the solution, generate sample data:

1. Open **Developer Console** (Setup → Developer Console)
2. Click **Debug → Open Execute Anonymous Window**
3. Paste the following code:

```apex
MI_SampleDataGenerator.GenerationResult result = MI_SampleDataGenerator.generateAll();
System.debug('Subjects created: ' + result.subjectsCreated);
System.debug('Products created: ' + result.productsCreated);
System.debug('Accounts created: ' + result.accountsCreated);
System.debug('Insights created: ' + result.insightsCreated);
```

4. Click **Execute**
5. Check the debug log for results

**Sample data includes:**
- 14 standard pharma subject categories (Clinical, Market Access, Practice Patterns, etc.)
- 5 sample products (Immunexis, Cardixol, NeuroVance)
- 5 HCP accounts
- 3 realistic sample insights with AI tags

### Step 4: Verify Installation

#### Test the AI Tagging Pipeline

1. Navigate to **Medical Insights** tab
2. Click **New**
3. Enter the following test insight:

**Name:** Test - Immunexis dosing feedback
**Content:**
```
Dr. Sarah Chen mentioned that her rheumatology patients on Immunexis 50mg
are showing good efficacy but she's concerned about long-term safety.
She requested more data on cardiovascular outcomes. This is related to
our clinical safety monitoring program.
```

4. **Save** the record
5. Wait 5-10 seconds for AI processing
6. Refresh the page
7. Verify the following fields are populated:
   - `AI_Summary__c` - Should contain a concise summary
   - `AI_Confidence__c` - Confidence score (0-1)
   - `AI_Action_Score__c` - Action priority score (0-1)
   - `AI_Cluster_Key__c` - Clustering identifier

8. Check related lists:
   - **Subjects** - Should show "Clinical – Safety & Tolerability"
   - **Products** - Should show "Immunexis 50mg"
   - **Accounts** - Should show "Dr. Sarah Chen"

#### Verify Junction Records

1. Open **Developer Console**
2. Execute the following SOQL:

```sql
SELECT Id, AssignmentId, SubjectId, Subject.Name
FROM SubjectAssignment
WHERE AssignmentId IN (SELECT Id FROM MedicalInsight WHERE Name LIKE 'Test - Immunexis%')
```

3. Verify SubjectAssignment records exist

4. Check product junctions:
```sql
SELECT Id, MedicalInsightId, ProductId, Product2.Name
FROM MedicalInsightProduct
WHERE MedicalInsightId IN (SELECT Id FROM MedicalInsight WHERE Name LIKE 'Test - Immunexis%')
```

5. Check account junctions:
```sql
SELECT Id, MedicalInsightId, AccountId, Account.Name
FROM MedicalInsightAccount
WHERE MedicalInsightId IN (SELECT Id FROM MedicalInsight WHERE Name LIKE 'Test - Immunexis%')
```

---

## Troubleshooting

### Issue: Flows Not Triggering

**Symptoms:** Insight saved but AI fields remain blank

**Resolution:**
1. Verify flows are activated (Setup → Flows)
2. Check flow run history (Setup → Process Automation → Flow Run History)
3. Look for error messages in Apex Jobs (Setup → Apex Jobs)

### Issue: No Subject/Product/Account Options in AI Output

**Symptoms:** AI returns empty arrays for subjects/products/accounts

**Resolution:**
1. Verify Subject records exist with `UsageType = 'MedicalInsight'`
2. Verify Product2 records exist and are active (`IsActive = true`)
3. Verify Account records exist
4. Check Apex logs for errors in option builder classes

### Issue: Junction Records Not Created

**Symptoms:** AI fields populate but no related records appear

**Resolution:**
1. Navigate to Setup → Apex Jobs
2. Look for failed jobs from `MI_InsightTagWriteback`
3. Check debug logs for specific errors
4. Common causes:
   - Invalid JSON format in AI output
   - Missing IDs (subject/product/account doesn't exist)
   - Permission issues (verify user has create access to junction objects)

### Issue: Permission Errors

**Symptoms:** "Insufficient privileges" errors

**Resolution:**
1. Verify permission sets are assigned correctly
2. Check object permissions:
   - MSL Users need Create on MedicalInsight
   - System needs Create/Delete on junction objects (SubjectAssignment, MedicalInsightProduct, MedicalInsightAccount)
3. Verify field-level security on custom fields:
   - `AI_Action_Score__c`
   - `AI_Cluster_Key__c`
   - `AI_Confidence__c`
   - `AI_Redacted__c`
   - `AI_Model_Version__c`
   - `AI_Summary__c`

---

## Next Steps

After successful installation:

1. **Review the [Setup Guide](SETUP_GUIDE.md)** to configure your subject taxonomy and product catalog
2. **Review the [User Guide](USER_GUIDE.md)** to learn how MSLs capture insights
3. **Review the [Admin Guide](ADMIN_GUIDE.md)** for ongoing administration and monitoring

---

## Support

For issues, questions, or feature requests:
- **AppExchange Listing**: Rate and review, ask questions
- **Documentation**: Check the complete documentation in the package
- **Community**: Join the Salesforce Life Sciences Community

---

## Package Components

This package includes:

**Apex Classes:**
- `MI_InsightTagWriteback` - Junction writer with deduplication
- `MI_AgentCaptureInvoker` - Agentforce invocable action
- `MI_AsyncInsightJob` - Async insight creation
- `MI_SubjectOptionsBuilder` - Builds subject options for AI
- `MI_ProductOptionsBuilder` - Builds product options for AI
- `MI_AccountOptionsBuilder` - Builds account options for AI
- `MI_InsightsToJsonBuilder` - Exports insights to JSON
- `MI_SampleDataGenerator` - Sample data generator
- Test classes with 85%+ coverage

**Flows:**
- `Insight_Trigger_Flow` - Record-triggered flow on MedicalInsight
- `MI_Insight_Theme_Summary_Flow` - AI processing orchestration

**Permission Sets:**
- `Medical Insights - Administrator`
- `Medical Insights - MSL User`
- `Medical Insights - Operations Manager`

**Custom Fields on MedicalInsight:**
- `AI_Action_Score__c` (Number, 0-1)
- `AI_Cluster_Key__c` (Text, 255)
- `AI_Confidence__c` (Number, 0-1)
- `AI_Redacted__c` (Checkbox)
- `AI_Model_Version__c` (Text, 50)
- `AI_Summary__c` (Long Text Area, 32,768)

**Prompt Templates:**
- `Medical_Insight_Tagger` - AI prompt for insight tagging

---

*Version 1.0 | Medical Insights Intelligence | Salesforce Labs*
