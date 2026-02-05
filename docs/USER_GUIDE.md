# Medical Insights Intelligence - User Guide

## Overview
This guide is for Medical Science Liaisons (MSLs) and field medical teams who capture medical insights. Learn how to create high-quality insights that the AI can accurately analyze and tag.

---

## Table of Contents
1. [What is Medical Insights Intelligence?](#what-is-medical-insights-intelligence)
2. [How to Capture an Insight](#how-to-capture-an-insight)
3. [Writing High-Quality Insights](#writing-high-quality-insights)
4. [Understanding AI Tags](#understanding-ai-tags)
5. [Reviewing Your Insights](#reviewing-your-insights)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## What is Medical Insights Intelligence?

Medical Insights Intelligence is an AI-powered tool that helps you capture and organize field intelligence from your interactions with Healthcare Providers (HCPs).

### What It Does

When you create a medical insight, the AI automatically:
- 📊 **Identifies subjects** (topics like Clinical Safety, Market Access, etc.)
- 💊 **Tags products** mentioned in your insight
- 👨‍⚕️ **Links HCPs** referenced in the conversation
- 📝 **Generates a summary** of the key finding
- 🎯 **Calculates priority scores** to help leadership focus on what matters

### Why It Matters

Before this tool:
- ❌ Insights lived in email or notes, hard to search
- ❌ Manual tagging was time-consuming and inconsistent
- ❌ Leadership couldn't spot trends across the field team
- ❌ Critical information got buried

With Medical Insights Intelligence:
- ✅ All insights in one place, fully searchable
- ✅ Automatic tagging in seconds
- ✅ Real-time dashboards showing field intelligence
- ✅ High-priority insights surfaced immediately

---

## How to Capture an Insight

### Method 1: Create Insight Directly (Standard)

1. **Navigate to Medical Insights**
   - Click the **Medical Insights** tab in Salesforce
   - Or click the **App Launcher** (grid icon) and search "Medical Insights"

2. **Click New**
   - Click the **New** button in the top right

3. **Fill in Basic Information**
   - **Name**: Brief title (e.g., "Dr. Chen feedback on Immunexis dosing")
   - **Content**: Full insight text (see "Writing High-Quality Insights" below)
   - **Source Type**: Select the source (Account, Event, etc.)
   - **Other fields**: Fill in any required fields per your org's setup

4. **Save**
   - Click **Save**
   - The AI will automatically process your insight in 5-10 seconds
   - Refresh the page to see AI-generated tags

5. **Review AI Tags**
   - Check the **Subjects**, **Products**, and **Accounts** related lists
   - Verify the AI correctly identified the key elements
   - Review the **AI Summary** field

### Method 2: Agentforce Capture (If Enabled)

If your organization has enabled Agentforce capture:

1. **Access Agentforce**
   - Click the Agentforce icon in Salesforce
   - Or use voice/chat interface

2. **Say or Type**
   - "Capture medical insight"
   - Or use your org's configured trigger phrase

3. **Provide Details**
   - Agentforce will ask you questions:
     - What did the HCP say?
     - Which HCP was this?
     - Which products were discussed?
     - Any other relevant details?

4. **Confirm**
   - Review the captured information
   - Agentforce will create the MedicalInsight record
   - AI tagging happens automatically

---

## Writing High-Quality Insights

The quality of your insight text directly impacts AI accuracy. Follow these guidelines:

### ✅ Good Insight Example

```
Dr. Sarah Chen expressed concern about cardiovascular safety in her elderly
patients taking Immunexis 100mg. She mentioned two patients over 75 who
experienced elevated blood pressure requiring dose adjustment. Dr. Chen
requested additional safety data on geriatric populations and asked if we
have any guidelines for cardiac monitoring in this age group. She is currently
hesitant to prescribe Immunexis to patients over 70 without baseline cardiac
workup.
```

**Why this is good:**
- ✅ Names the specific HCP (Dr. Sarah Chen)
- ✅ Mentions the specific product and dose (Immunexis 100mg)
- ✅ Describes the issue clearly (cardiovascular safety in elderly)
- ✅ Includes specific details (two patients, over 75, elevated BP)
- ✅ Notes the HCP's request (safety data, monitoring guidelines)
- ✅ Captures the impact (hesitant to prescribe to >70 age group)

### ❌ Poor Insight Example

```
Talked to Dr. Chen about safety stuff. She had some questions.
```

**Why this is poor:**
- ❌ Too brief, lacks detail
- ❌ Vague ("safety stuff", "some questions")
- ❌ No product mentioned
- ❌ No specific concern or request
- ❌ No actionable information

### Key Elements of a Great Insight

Every insight should include:

1. **Who** (the HCP)
   - Use full name: "Dr. John Smith"
   - Include credentials if relevant: "Dr. Smith, a cardiologist at Mayo Clinic"

2. **What** (the key finding or request)
   - Be specific: "requested efficacy data" not "had questions"
   - Quote the HCP when possible: "Dr. Smith said, 'I need more safety data'"

3. **Which** (products, if applicable)
   - Include brand name and dose: "Cardixol 20mg"
   - Mention competitors if discussed: "comparing Cardixol to Competitor X"

4. **Why** (context or reason)
   - Why is this important?
   - What's the clinical context?
   - What's the practice pattern?

5. **Impact** (so what?)
   - How does this affect prescribing?
   - What action is needed?
   - What's the business implication?

### Template for Writing Insights

Use this template as a starting point:

```
[HCP Name] [action: mentioned/requested/expressed concern about/asked] [topic/issue]
regarding [product name]. [Details: specific examples, patient population, context].
[HCP's perspective or request]. [Impact on prescribing/practice/perception].
```

**Example using template:**
```
Dr. Michael Rodriguez requested prior authorization support for Cardixol 20mg.
He mentioned 3 recent denials from BlueCross BlueShield, citing lack of
step therapy documentation. Dr. Rodriguez asked for a PA template and
wondered if we have a dedicated team to help with appeals. He stated he's
considering switching to Competitor Y due to fewer PA hurdles.
```

---

## Understanding AI Tags

After you save an insight, the AI analyzes it and adds several pieces of metadata:

### AI-Generated Fields

#### AI Summary
- **What it is**: A concise 1-2 sentence summary of your insight
- **Example**: "Dr. Chen reported cardiovascular safety concerns in elderly patients on Immunexis 100mg"
- **How to use it**: Quick scan to understand the key finding without reading full text

#### AI Confidence Score
- **What it is**: How confident the AI is in its tagging (0.0 to 1.0)
- **Good score**: >0.7
- **Review needed**: <0.5
- **What it means**: Low confidence means the AI had trouble understanding your insight—consider adding more detail

#### AI Action Score
- **What it is**: How urgent or important the insight is (0.0 to 1.0)
- **High priority**: >0.8 (urgent medical info, safety signals, major barriers)
- **Medium priority**: 0.5-0.8 (important but not urgent)
- **Low priority**: <0.5 (general feedback, routine observations)

#### AI Cluster Key
- **What it is**: Groups similar insights together
- **Example**: "immunexis-elderly-safety"
- **How to use it**: Find related insights across the field team

### Related Records (Junction Objects)

#### Subjects
- **What they are**: Topic categories (Clinical Safety, Market Access, etc.)
- **Where to see them**: "Subjects" related list on the insight record
- **How they're added**: AI automatically selects relevant subjects based on your text

#### Products
- **What they are**: Products mentioned in your insight
- **Where to see them**: "Products" related list on the insight record
- **How they're added**: AI automatically detects product names in your text

#### Accounts (HCPs)
- **What they are**: Healthcare providers mentioned in your insight
- **Where to see them**: "Accounts" related list on the insight record
- **How they're added**: AI automatically matches HCP names to Account records

---

## Reviewing Your Insights

### Checking AI Accuracy

After the AI processes your insight:

1. **Verify Subjects**
   - Do the tagged subjects make sense?
   - Are any subjects missing?
   - Are any subjects incorrectly applied?

2. **Verify Products**
   - Did the AI correctly identify all products?
   - Is the dose strength correct?
   - Are competitor products tagged if mentioned?

3. **Verify Accounts**
   - Is the correct HCP linked?
   - If multiple HCPs are mentioned, are all linked?
   - Is the HCP name spelled correctly?

### What to Do If Tags Are Wrong

If the AI didn't tag correctly:

**For Subjects:**
1. Navigate to the "Subjects" related list
2. Click **New** to manually add a subject
3. Select the appropriate subject from the lookup
4. Save

**For Products:**
1. Navigate to the "Products" related list
2. Click **New** to manually add a product
3. Select the product from the lookup
4. Save

**For Accounts:**
1. Navigate to the "Accounts" related list
2. Click **New** to manually add an account
3. Select the HCP from the lookup
4. Save

### Editing Insights

You can edit an insight at any time:
1. Open the insight record
2. Click **Edit**
3. Update the **Content** field with more details
4. Save
5. The AI will re-process the insight with the new information

---

## Best Practices

### Capture Insights Promptly
- ✅ **Within 24 hours** of the HCP interaction
- ❌ Don't wait until end of week—details fade

### Be Specific
- ✅ "Dr. Chen has 15 rheumatoid arthritis patients on Immunexis 50mg"
- ❌ "Dr. Chen uses our product"

### Use Full Names
- ✅ "Dr. Sarah Chen"
- ❌ "Dr. C" or "Sarah"

### Include Product Details
- ✅ "Immunexis 100mg once weekly"
- ❌ "the drug"

### Quote the HCP
- ✅ "Dr. Chen said, 'I need more data on long-term safety'"
- ❌ "Dr. Chen had concerns"

### Provide Context
- ✅ "This is the 3rd request this month for cardiac safety data in elderly patients"
- ❌ "Another safety question"

### Note Follow-Up Actions
- ✅ "I committed to providing the SENIOR trial data by next week"
- ❌ "I'll get back to her"

### Use Standard Terminology
- ✅ Use medical terms the AI can understand
- ❌ Avoid internal jargon or abbreviations

---

## Troubleshooting

### "AI fields are blank after I saved"

**Possible causes:**
- The AI is still processing (wait 10-15 seconds and refresh)
- The flow is disabled (contact your admin)
- Your insight text is too brief (add more detail)

**Solution:**
1. Wait 15 seconds
2. Refresh the page
3. If still blank, click **Edit** and add more detail to the Content field

### "AI Confidence is low (<0.5)"

**Why it happens:**
- Insight text is vague or too brief
- Product/HCP names don't match Salesforce records
- Multiple topics mixed together

**Solution:**
1. Review your insight text
2. Ensure product names match exactly (check Products tab)
3. Ensure HCP names match Account records (check Accounts tab)
4. Consider splitting complex insights into multiple records

### "Wrong subjects were tagged"

**Why it happens:**
- Insight text is ambiguous
- Multiple topics in one insight
- AI prompt needs refinement

**Solution:**
1. Manually add the correct subject (see "Reviewing Your Insights")
2. Edit the insight to be more specific
3. Contact your admin if this happens frequently

### "HCP not linked even though I mentioned them"

**Possible causes:**
- HCP name doesn't exactly match an Account record
- HCP doesn't exist in Salesforce yet
- Name spelling is different

**Solution:**
1. Check the Accounts tab for the correct spelling
2. If HCP doesn't exist, ask your admin to create the account
3. Manually link the HCP (see "Reviewing Your Insights")

---

## Quick Reference Card

### Before You Write
- [ ] Do I have all the details fresh in my mind?
- [ ] Do I know the HCP's full name?
- [ ] Do I know which products were discussed?
- [ ] What's the key takeaway or action item?

### While You Write
- [ ] Include HCP full name
- [ ] Mention specific products with doses
- [ ] Provide specific examples or patient counts
- [ ] Explain the clinical context
- [ ] Note any follow-up commitments

### After You Save
- [ ] Wait 10 seconds and refresh
- [ ] Check AI Summary—does it capture the key point?
- [ ] Verify Subjects are correct
- [ ] Verify Products are correct
- [ ] Verify HCP is linked correctly
- [ ] Check AI Confidence (should be >0.7)

---

## Examples: Before and After

### Example 1: Market Access Insight

**❌ Before (Poor):**
```
PA issues with Dr. Rodriguez.
```

**✅ After (Good):**
```
Dr. Michael Rodriguez reported significant prior authorization delays for
Cardixol 20mg with Aetna. He stated that 4 out of his last 5 PA requests
have been denied initially, requiring appeals that take 2-3 weeks. Dr.
Rodriguez mentioned that patients are starting on competitor drugs while
waiting for approval, and he's losing confidence in prescribing Cardixol
for new patients. He requested a dedicated PA support line or co-pilot
service to streamline the process.
```

### Example 2: Clinical Insight

**❌ Before (Poor):**
```
Dr. Chen asked about dosing.
```

**✅ After (Good):**
```
Dr. Sarah Chen asked whether Immunexis 50mg can be titrated to 100mg in
patients with chronic kidney disease Stage 3. She has three CKD patients
showing suboptimal response at 50mg but is concerned about drug accumulation
at higher doses given reduced renal clearance. Dr. Chen requested
pharmacokinetic data in CKD populations and any dosing guidelines for
patients with eGFR 30-60. She mentioned this would help her feel comfortable
dose-adjusting approximately 10-15 patients in her practice.
```

### Example 3: Competitive Insight

**❌ Before (Poor):**
```
Competitor talk with Dr. Washington.
```

**✅ After (Good):**
```
Dr. Emily Washington compared Cardixol 20mg to Competitor X (Entresto) for
heart failure with reduced ejection fraction. She noted that while Cardixol
has fewer GI side effects in her experience, Competitor X has more robust
outcomes data from the PARADIGM-HF trial. Dr. Washington asked if we have
any head-to-head data or real-world evidence comparing hospitalizations
between the two drugs. She's currently prescribing 60% Competitor X and
40% Cardixol for new HFrEF patients.
```

---

## Getting Help

- **Questions about the tool?** Contact your Medical Insights Administrator
- **Technical issues?** Submit a case via your org's support process
- **Training resources?** Check your org's training portal or learning management system

---

*Version 1.0 | Medical Insights Intelligence | Salesforce Labs*
