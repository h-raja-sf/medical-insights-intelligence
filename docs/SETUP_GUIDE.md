# Medical Insights Intelligence - Setup Guide

## Overview
This guide walks you through configuring Medical Insights Intelligence after installation. You'll set up your subject taxonomy, configure products and accounts, customize AI prompts, and establish your insight capture workflow.

---

## Table of Contents
1. [Subject Taxonomy Setup](#subject-taxonomy-setup)
2. [Product Catalog Configuration](#product-catalog-configuration)
3. [Account (HCP) Setup](#account-hcp-setup)
4. [AI Prompt Customization](#ai-prompt-customization)
5. [Dashboard and Reports](#dashboard-and-reports)
6. [Best Practices](#best-practices)

---

## Subject Taxonomy Setup

### Understanding Subjects
Subjects are the topic categories that organize your medical insights. Think of them as tags or themes that help you analyze and report on field intelligence.

### Best Practices for Subject Design
- **Keep it simple**: 10-20 subjects is optimal; too many creates noise
- **Make them mutually exclusive**: Each subject should be distinct
- **Use descriptive names**: Clear names improve AI accuracy
- **Include descriptions**: Help the AI understand when to apply each subject

### Standard Pharma Subject Taxonomy

The sample data generator includes 14 standard subjects across 5 categories:

#### Clinical Subjects
- **Clinical – Efficacy & Outcomes**: Clinical trial results, real-world efficacy, patient outcomes
- **Clinical – Safety & Tolerability**: Adverse events, drug interactions, contraindications
- **Clinical – Dosing & Administration**: Titration protocols, dose adjustments, routes
- **Clinical – Special Populations**: Pediatrics, geriatrics, pregnancy, renal/hepatic impairment

#### Market Access Subjects
- **Market Access – Prior Authorization**: PA requirements, step therapy, appeals
- **Market Access – Formulary Status**: Formulary placement, tier status, restrictions
- **Market Access – Patient Assistance**: Copay cards, support programs, financial assistance

#### Practice Patterns
- **Practice Patterns – Treatment Sequencing**: Line of therapy, switching patterns
- **Practice Patterns – Patient Selection**: Diagnostic criteria, patient identification
- **Practice Patterns – Monitoring**: Lab monitoring, imaging requirements, follow-up

#### Competitive Intelligence
- **Competitive – Landscape**: Competitor positioning, market share, prescribing trends
- **Competitive – Product Comparison**: Head-to-head data, comparative effectiveness

#### Medical Education
- **Education – Knowledge Gaps**: Unmet educational needs, misconceptions, training needs
- **Education – Guidelines & Literature**: Treatment guidelines, new publications, clinical updates

### Creating Custom Subjects

1. Navigate to **Subjects** tab
2. Click **New**
3. Fill in the fields:
   - **Name**: Use format "Category – Topic" (e.g., "Clinical – Safety & Tolerability")
   - **Description**: Detailed description to guide AI (2-3 sentences)
   - **Usage Type**: Select `MedicalInsight`
4. Click **Save**

### Editing Existing Subjects

You can modify subjects at any time:
- Update names for clarity
- Enhance descriptions to improve AI accuracy
- Merge similar subjects by deleting duplicates

**Note:** Deleting a subject will also delete associated SubjectAssignment junction records.

---

## Product Catalog Configuration

### Using Standard Product2 Object

Medical Insights Intelligence uses the standard Salesforce `Product2` object. This means:
- ✅ No new product catalog to maintain
- ✅ Integrates with your existing product data
- ✅ Works with Price Books, Product Families, etc.

### Product Requirements

For products to appear in AI tagging, they must:
1. Exist in the `Product2` object
2. Have `IsActive = true`
3. Have a unique `Name`

### Sample Products Included

The sample data generator creates 5 products:
- **Immunexis 50mg** (IMX-050): Immunotherapy for inflammatory conditions
- **Immunexis 100mg** (IMX-100): High-dose immunotherapy
- **Cardixol 10mg** (CDX-010): Cardiovascular therapy
- **Cardixol 20mg** (CDX-020): Standard-dose cardiovascular therapy
- **NeuroVance 5mg** (NRV-005): Neurological therapy

### Adding Your Products

If you already have products in Salesforce:
1. Navigate to **Products** tab
2. Ensure your pharmaceutical products are marked as **Active**
3. Verify product names match how MSLs refer to them
4. Consider including dose strength in the product name for AI accuracy

If you need to create new products:
1. Navigate to **Products** tab
2. Click **New**
3. Fill in:
   - **Product Name**: Include brand name and strength (e.g., "Keytruda 100mg")
   - **Product Code**: Internal SKU/code
   - **Active**: Check this box
   - **Description**: Brief product description
4. Click **Save**

### Product Best Practices

- **Include dose strengths**: "Keytruda 100mg" vs. "Keytruda"
- **Use brand names**: MSLs typically use brand names, not generics
- **Keep active products updated**: Inactive products won't be tagged
- **Consider product families**: Group related products for easier reporting

---

## Account (HCP) Setup

### Using Standard Account Object

Medical Insights Intelligence uses standard Salesforce `Account` records to represent Healthcare Providers (HCPs). This means:
- ✅ Integrates with your existing CRM data
- ✅ Works with territory management
- ✅ Leverages existing data quality processes

### Account Requirements

For accounts to appear in AI tagging:
1. Must exist as `Account` records
2. Should have unique, recognizable names
3. Typically represent individual physicians or providers

### Sample Accounts Included

The sample data generator creates 5 HCP accounts:
- **Dr. Sarah Chen**: Rheumatology KOL, Academic Medical Center
- **Dr. Michael Rodriguez**: Community Rheumatologist
- **Dr. Emily Washington**: Cardiologist, Heart Failure Specialist
- **Dr. James Kumar**: Neurologist, Cognitive disorders focus
- **Dr. Lisa Martinez**: Internist with immunology practice

### Using Your Existing Accounts

Your existing Salesforce accounts will automatically be available for AI tagging. No additional setup required!

**Best practices:**
- Ensure HCP names are formatted consistently (e.g., "Dr. John Smith" vs. "Smith, John")
- Use the Account Description field to add specialty or practice details
- Maintain accurate account data for better AI matching

---

## AI Prompt Customization

### Understanding the Prompt Template

The `Medical_Insight_Tagger` prompt template is the "brain" of the AI tagging system. It:
- Receives insight text as input
- Has access to your subjects, products, and accounts via Apex resources
- Returns structured JSON with extracted tags

### Accessing the Prompt Template

1. Navigate to **Setup → Prompt Builder → Prompt Templates**
2. Find: `Medical_Insight_Tagger`
3. Click to open

### Prompt Components

The prompt has three main sections:

#### 1. System Instructions
Tells the AI what to do:
- Extract relevant subjects, products, and accounts
- Generate a concise summary
- Calculate confidence and action scores
- Return structured JSON

#### 2. Context Resources (Apex Functions)
Three invocable actions provide options to the AI:
- `MI_SubjectOptionsBuilder`: Returns available subjects with descriptions
- `MI_ProductOptionsBuilder`: Returns active products
- `MI_AccountOptionsBuilder`: Returns account options

#### 3. User Input
The insight text to analyze

### Customizing the Prompt

You can customize the prompt to match your business needs:

**To emphasize certain subjects:**
```
Pay special attention to safety-related insights. If the insight mentions
adverse events, drug interactions, or safety concerns, ALWAYS include
"Clinical – Safety & Tolerability" as a subject.
```

**To adjust action scoring:**
```
Calculate AI_Action_Score based on:
- Urgent medical information: 0.9-1.0
- Market access barriers: 0.7-0.9
- Competitive intelligence: 0.5-0.7
- General feedback: 0.3-0.5
```

**To modify summary style:**
```
Generate a 1-sentence executive summary in this format:
"[HCP Name] reported [key finding] regarding [product/topic]."
```

### Testing Your Prompt Changes

1. After editing, click **Save**
2. Click **Preview**
3. Enter sample insight text
4. Verify the JSON output looks correct
5. Check that subjects/products/accounts are being selected appropriately

---

## Dashboard and Reports

### Pre-Built Reports (Coming Soon)

The package includes several pre-built reports:

**Insight Volume Reports:**
- Insights by Subject (Last 30 Days)
- Insights by Product (Last 30 Days)
- Insights by MSL/User (Last 30 Days)

**Action Priority Reports:**
- High Action Score Insights (>0.8)
- Unaddressed Safety Insights
- Market Access Barriers Trending

**AI Performance Reports:**
- AI Confidence Distribution
- Insights Requiring Manual Review
- Tagging Accuracy Audit

### Creating Custom Reports

1. Navigate to **Reports** tab
2. Click **New Report**
3. Select **Medical Insights** as the primary object
4. Add filters:
   - Date range
   - AI Action Score thresholds
   - Specific subjects/products
5. Group by:
   - Subject
   - Product
   - Account
   - Owner
6. Add summary fields:
   - Record Count
   - Average AI Confidence
   - Average Action Score

### Building Dashboards

Create executive dashboards to monitor field intelligence:

1. Navigate to **Dashboards** tab
2. Click **New Dashboard**
3. Add components:
   - **Insight Volume by Subject** (Bar Chart)
   - **High Priority Insights** (Table)
   - **Product Mention Trends** (Line Chart)
   - **Top HCPs by Insight Volume** (Horizontal Bar)
   - **AI Confidence Distribution** (Gauge)

---

## Best Practices

### Subject Taxonomy Management

✅ **Do:**
- Review and refine subjects quarterly based on usage patterns
- Keep subject names concise and descriptive
- Use consistent naming conventions (Category – Topic)
- Provide detailed descriptions to improve AI accuracy

❌ **Don't:**
- Create too many subjects (>25 becomes unmanageable)
- Use vague names like "Other" or "Miscellaneous"
- Duplicate similar subjects
- Delete heavily-used subjects without planning

### Product Configuration

✅ **Do:**
- Keep product names consistent with how MSLs refer to them
- Include dose strength when relevant
- Mark discontinued products as inactive rather than deleting
- Use Product Families to group related products

❌ **Don't:**
- Use internal codes as product names
- Keep inactive products marked as active
- Use generic names when brand names are more common
- Create duplicate product records

### AI Prompt Optimization

✅ **Do:**
- Test prompt changes with real insight examples
- Provide clear instructions in the prompt
- Use examples in the prompt to guide AI behavior
- Monitor AI confidence scores to measure prompt quality

❌ **Don't:**
- Make major prompt changes without testing
- Overload the prompt with too many instructions
- Use ambiguous language in the prompt
- Change the expected JSON output structure

### Data Quality

✅ **Do:**
- Train MSLs to write clear, specific insights
- Include product names and HCP names in insight text
- Capture insights promptly while details are fresh
- Review insights with low AI confidence scores

❌ **Don't:**
- Use abbreviations or acronyms without context
- Write overly brief insights (1-2 sentences isn't enough)
- Wait days/weeks to capture insights
- Ignore insights flagged for manual review

### Monitoring and Maintenance

✅ **Do:**
- Review Apex Job logs weekly for errors
- Monitor average AI confidence scores (should be >0.7)
- Check for orphaned junction records
- Archive old insights per your retention policy

❌ **Don't:**
- Ignore failed Apex jobs
- Let low-confidence insights accumulate
- Disable flows without understanding impact
- Delete insights without considering dependencies

---

## Advanced Configuration

### Custom Fields on MedicalInsight

You can add custom fields to capture additional metadata:
- Territory
- Brand/Therapeutic Area
- Visit Type (Virtual, In-Person)
- Meeting Purpose

These fields can be populated by MSLs during insight capture and used for reporting.

### Integration with CRM Activities

Consider linking insights to:
- **Events**: Associate insights with specific HCP meetings
- **Campaigns**: Track insights generated from specific initiatives
- **Opportunities**: Link insights to business development activities

### Workflow Automation

Build additional automation on top of the AI tagging:
- **Email alerts**: Notify medical directors of high-priority insights
- **Slack notifications**: Post urgent insights to Slack channels
- **Case creation**: Automatically create cases for medical information requests
- **Task assignment**: Route insights to appropriate teams based on subject

---

## Next Steps

1. **Train Your MSLs**: Review the [User Guide](USER_GUIDE.md) with your field team
2. **Monitor Usage**: Check reports weekly to ensure adoption
3. **Iterate on Taxonomy**: Refine subjects based on real-world usage
4. **Optimize Prompts**: Adjust AI prompts as you learn what works

---

## Support Resources

- **Installation Guide**: [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md)
- **User Guide**: [USER_GUIDE.md](USER_GUIDE.md)
- **Admin Guide**: [ADMIN_GUIDE.md](ADMIN_GUIDE.md)
- **Salesforce Life Sciences Community**: Connect with other users

---

*Version 1.0 | Medical Insights Intelligence | Salesforce Labs*
