# Medical Insights Intelligence - Administrator Guide

## Overview
This guide is for Salesforce Administrators responsible for managing Medical Insights Intelligence. Learn how to monitor system health, troubleshoot issues, optimize performance, and provide ongoing support to your field teams.

---

## Table of Contents
1. [Administrator Responsibilities](#administrator-responsibilities)
2. [Monitoring System Health](#monitoring-system-health)
3. [Managing Subjects and Taxonomy](#managing-subjects-and-taxonomy)
4. [Troubleshooting Common Issues](#troubleshooting-common-issues)
5. [Performance Optimization](#performance-optimization)
6. [User Management](#user-management)
7. [Data Quality Management](#data-quality-management)
8. [Reporting and Analytics](#reporting-and-analytics)
9. [Maintenance Tasks](#maintenance-tasks)
10. [Advanced Configuration](#advanced-configuration)

---

## Administrator Responsibilities

As the Medical Insights Administrator, you are responsible for:

### Day-to-Day
- ✅ Monitor Apex job success rates
- ✅ Review insights flagged for manual review (low confidence)
- ✅ Respond to user questions and issues
- ✅ Ensure data quality standards are maintained

### Weekly
- ✅ Review system health dashboard
- ✅ Check for failed Apex jobs and resolve
- ✅ Analyze AI confidence trends
- ✅ Review subject usage patterns

### Monthly
- ✅ Refine subject taxonomy based on usage
- ✅ Update AI prompts if needed
- ✅ Review and optimize performance
- ✅ Generate executive reports on field intelligence

### Quarterly
- ✅ Conduct user training refreshers
- ✅ Audit data quality
- ✅ Review permission sets and access
- ✅ Plan enhancements or customizations

---

## Monitoring System Health

### Key Health Indicators

Monitor these metrics to ensure the system is running smoothly:

#### 1. Apex Job Success Rate
- **Target**: >95% success rate
- **Where to check**: Setup → Apex Jobs
- **What to look for**: Failed jobs from `MI_InsightTagWriteback` or `MI_AsyncInsightJob`

#### 2. Average AI Confidence Score
- **Target**: >0.75
- **Where to check**: Create a report on MedicalInsight with AVG(AI_Confidence__c)
- **What it means**: Lower scores indicate insights are poorly written or AI prompt needs tuning

#### 3. Junction Record Creation Rate
- **Target**: Should match insight creation rate
- **Where to check**: Compare count of MedicalInsight records to SubjectAssignment records
- **What to look for**: Orphaned insights without any subject/product/account assignments

#### 4. User Adoption
- **Target**: Set based on your field team size
- **Where to check**: Report on MedicalInsight by CreatedBy and CreatedDate
- **What to look for**: Users not creating insights, or sudden drop-offs

### Setting Up Admin Dashboard

Create a dashboard to monitor system health:

1. **Navigate to Dashboards → New Dashboard**
2. **Name it**: "Medical Insights - Admin Health Dashboard"
3. **Add Components**:

**Component 1: Apex Job Success Rate (Last 7 Days)**
- Type: Gauge
- Source: Apex Jobs (custom report)
- Show: % of successful jobs

**Component 2: Insights Created (Last 30 Days)**
- Type: Line Chart
- Source: MedicalInsight records
- Group by: CreatedDate (day)

**Component 3: Average AI Confidence**
- Type: Gauge
- Source: MedicalInsight records
- Show: AVG(AI_Confidence__c)
- Color thresholds: Green >0.75, Yellow 0.5-0.75, Red <0.5

**Component 4: Insights Needing Review**
- Type: Table
- Source: MedicalInsight WHERE AI_Confidence__c < 0.5
- Columns: Name, CreatedBy, CreatedDate, AI_Confidence__c

**Component 5: Subject Usage Distribution**
- Type: Horizontal Bar Chart
- Source: SubjectAssignment grouped by Subject
- Show: Top 10 subjects by count

**Component 6: High Priority Insights**
- Type: Table
- Source: MedicalInsight WHERE AI_Action_Score__c > 0.8
- Columns: Name, AI_Summary__c, AI_Action_Score__c, CreatedDate

### Daily Health Check Routine

Spend 10 minutes each morning reviewing:

1. **Check Apex Jobs** (Setup → Apex Jobs)
   - Filter by Status = Failed, CreatedDate = Yesterday
   - Investigate any failures
   - Re-run if needed

2. **Review Low Confidence Insights**
   - Run report: MedicalInsight WHERE AI_Confidence__c < 0.5 AND CreatedDate = LAST_N_DAYS:1
   - Contact users to provide feedback on writing better insights

3. **Check for Orphaned Records**
   - Run query to find insights with no subject assignments:
   ```sql
   SELECT Id, Name FROM MedicalInsight
   WHERE Id NOT IN (SELECT AssignmentId FROM SubjectAssignment)
   AND CreatedDate = LAST_N_DAYS:1
   ```
   - Investigate why tagging failed

---

## Managing Subjects and Taxonomy

### Subject Lifecycle

Subjects evolve over time. Follow this process for managing your taxonomy:

#### Adding New Subjects

**When to add:**
- Users consistently mention topics not covered
- New therapeutic areas or product launches
- Regulatory or market changes

**How to add:**
1. Navigate to **Subjects** tab → **New**
2. Fill in:
   - **Name**: Use format "Category – Topic"
   - **Description**: Detailed description to guide AI (2-3 sentences)
   - **Usage Type**: Select `MedicalInsight`
3. Click **Save**
4. Test by creating a sample insight mentioning this subject
5. Verify AI correctly tags it

**Best practices:**
- Get input from field teams before adding
- Ensure it doesn't overlap with existing subjects
- Keep the name clear and distinctive

#### Editing Existing Subjects

**When to edit:**
- Subject name is confusing to users or AI
- Description needs clarification
- Usage patterns show misapplication

**How to edit:**
1. Navigate to **Subjects** tab
2. Find the subject and click **Edit**
3. Update Name or Description
4. Click **Save**
5. Monitor subsequent insights to see if tagging improves

**Impact:**
- Existing SubjectAssignment records are NOT updated
- Only future insights will use the new name/description

#### Merging Subjects

**When to merge:**
- Two subjects are redundant
- Usage shows overlap
- Simplifying taxonomy

**How to merge:**
1. Decide which subject to keep (Subject A) and which to retire (Subject B)
2. Update all SubjectAssignment records:
   ```apex
   List<SubjectAssignment> assignmentsToUpdate = [
       SELECT Id, SubjectId
       FROM SubjectAssignment
       WHERE SubjectId = :subjectBId
   ];
   for (SubjectAssignment sa : assignmentsToUpdate) {
       sa.SubjectId = subjectAId;
   }
   update assignmentsToUpdate;
   ```
3. Delete Subject B
4. Communicate the change to users

#### Deleting Subjects

**When to delete:**
- Subject is no longer relevant
- Was created by mistake
- Never used

**How to delete:**
1. Check usage: Run report on SubjectAssignment filtered by Subject
2. If heavily used, consider merging instead
3. If ok to delete:
   - Navigate to **Subjects** tab
   - Click on the subject
   - Click **Delete**
   - Confirm

**Impact:**
- Deletes all associated SubjectAssignment records
- Cannot be undone (except via data backup)

### Taxonomy Audit Process

Conduct quarterly audits of your subject taxonomy:

**Step 1: Usage Analysis**
- Create report: SubjectAssignment grouped by Subject
- Identify subjects with <5 assignments in last 90 days
- Consider deleting or merging underused subjects

**Step 2: Misclassification Analysis**
- Review insights with multiple subjects (>3)
- Check if users are manually changing AI-selected subjects
- Look for patterns indicating AI confusion

**Step 3: Coverage Analysis**
- Review insights with no subjects assigned
- Look for common themes not covered by current taxonomy
- Consider adding new subjects

**Step 4: User Feedback**
- Survey field teams: "Which subjects are confusing?"
- Ask: "What topics are missing?"
- Incorporate feedback into taxonomy updates

---

## Troubleshooting Common Issues

### Issue 1: Insights Not Being Tagged

**Symptoms:**
- Insight saved but AI fields remain blank
- No subjects/products/accounts assigned

**Diagnostic Steps:**
1. Check if flows are active:
   - Setup → Flows
   - Verify `Insight_Trigger_Flow` and `MI_Insight_Theme_Summary_Flow` are Active

2. Check Apex Jobs:
   - Setup → Apex Jobs
   - Filter by CreatedDate = Today
   - Look for failed jobs

3. Check debug logs:
   - Setup → Debug Logs
   - Enable logging for the user who created the insight
   - Recreate the issue
   - Review the log for errors

**Common Causes & Solutions:**

**Cause: Flow is inactive**
- Solution: Reactivate the flow

**Cause: Apex class permission issue**
- Solution: Verify user's permission set includes access to MI classes

**Cause: Agentforce prompt failed**
- Solution: Check Prompt Builder logs, test the prompt manually

**Cause: Invalid JSON returned by AI**
- Solution: Review prompt template, ensure JSON structure is correct

### Issue 2: Low AI Confidence Scores

**Symptoms:**
- AI_Confidence__c consistently <0.5
- Many insights flagged for manual review

**Diagnostic Steps:**
1. Review sample insights with low confidence
2. Look for common patterns:
   - Too brief?
   - Vague language?
   - Missing product/HCP names?

**Solutions:**

**Solution 1: User Training**
- Conduct refresher training on writing quality insights
- Share examples of good vs. poor insights
- Provide templates

**Solution 2: Update Prompt**
- Adjust the AI prompt to better handle common cases
- Add examples to the prompt
- Test changes thoroughly

**Solution 3: Refine Taxonomy**
- If subjects are confusing the AI, simplify
- Add more detailed descriptions to subjects
- Remove overlapping subjects

### Issue 3: Wrong Products/Accounts Tagged

**Symptoms:**
- AI tags incorrect products
- Wrong HCP accounts linked

**Diagnostic Steps:**
1. Check if product/account names are ambiguous
2. Look for duplicate records
3. Review insight text for clarity

**Solutions:**

**Solution 1: Clean Up Data**
- Merge duplicate accounts
- Ensure product names are unique
- Use consistent naming conventions

**Solution 2: Improve Insight Quality**
- Train users to use full product names with doses
- Use full HCP names, not nicknames
- Avoid abbreviations

**Solution 3: Adjust AI Prompt**
- Add disambiguation instructions to the prompt
- Provide examples of correct matching
- Use fuzzy matching hints

### Issue 4: Junction Records Not Created

**Symptoms:**
- AI fields populate but no related records in Subject/Product/Account lists

**Diagnostic Steps:**
1. Check Apex Jobs for `MI_InsightTagWriteback` failures
2. Review debug logs for the insight record
3. Check for permission issues

**Common Causes & Solutions:**

**Cause: Invalid JSON format**
- Solution: Review the AI prompt output, ensure valid JSON

**Cause: IDs don't exist**
- Solution: Verify subjects/products/accounts exist in Salesforce

**Cause: Permission issue**
- Solution: Verify the running user has Create access to junction objects

**Cause: Apex governor limits**
- Solution: If processing >200 insights in one transaction, optimize code

### Issue 5: Apex Jobs Failing

**Symptoms:**
- Apex Jobs showing "Failed" status
- Email alerts about Apex failures

**Diagnostic Steps:**
1. Navigate to Setup → Apex Jobs
2. Click on the failed job
3. Review the error message
4. Check the debug log

**Common Errors:**

**Error: "UNABLE_TO_LOCK_ROW"**
- Cause: Record is being edited by user or another process
- Solution: Retry the job; if persists, check for long-running processes

**Error: "FIELD_CUSTOM_VALIDATION_EXCEPTION"**
- Cause: Validation rule blocking the update
- Solution: Review validation rules on MedicalInsight/junction objects

**Error: "INVALID_CROSS_REFERENCE_KEY"**
- Cause: Trying to link to a deleted record
- Solution: Check if subjects/products/accounts were deleted

**Error: "System.LimitException: Too many SOQL queries"**
- Cause: Processing too many records at once
- Solution: Contact support or developer to optimize code

---

## Performance Optimization

### Apex Performance

Monitor and optimize Apex execution:

#### CPU Time Limits
- **Default limit**: 10,000ms CPU time per transaction
- **Monitor**: Setup → Apex Jobs → check execution time
- **Optimize if**: Jobs consistently >5,000ms

**Optimization techniques:**
- Reduce SOQL queries (use bulkified queries)
- Limit the number of records processed per transaction
- Use asynchronous processing (Queueable/Batch)

#### SOQL Query Limits
- **Default limit**: 100 SOQL queries per transaction
- **Monitor**: Debug logs showing query counts
- **Optimize if**: Approaching 50+ queries

**Optimization techniques:**
- Bulkify queries (query all records at once)
- Use collections (Lists, Maps, Sets)
- Avoid SOQL in loops

### Flow Performance

Monitor Flow execution:

1. Navigate to **Setup → Process Automation → Paused Flow Interviews**
2. Look for paused or stuck flows
3. Resume or terminate as needed

**Common issues:**
- Flow waiting for user input (shouldn't happen for auto-triggered flows)
- Flow hitting governor limits
- Flow timing out on external callout

### AI Prompt Performance

The AI prompt adds latency. Monitor and optimize:

#### Latency Metrics
- **Target**: <5 seconds for prompt execution
- **Monitor**: Check Agentforce prompt logs
- **Optimize if**: >10 seconds consistently

**Optimization techniques:**
- Reduce the number of examples in the prompt
- Simplify prompt instructions
- Use smaller context windows
- Cache subject/product/account lists if possible

---

## User Management

### Permission Set Strategy

Three permission sets are provided:

#### MI_Admin
- **Who**: Salesforce Admins, Medical Affairs Directors
- **Access**: Full CRUD on all objects, all Apex classes
- **Use case**: System configuration and administration

#### MI_MSL_User
- **Who**: Medical Science Liaisons, Field Medical
- **Access**: Create/Edit insights, Read-only on junctions, limited Apex
- **Use case**: Day-to-day insight capture

#### MI_Ops_Manager
- **Who**: Operations Managers, Analysts
- **Access**: Edit insights, Read-only on junctions, reporting tools, limited Apex
- **Use case**: Analytics, reporting, insight management

### Assigning Permission Sets

**For new users:**
1. Navigate to **Setup → Users → Permission Sets**
2. Select the appropriate permission set
3. Click **Manage Assignments**
4. Click **Add Assignments**
5. Select the users
6. Click **Assign**

**Bulk assignment via Data Loader:**
1. Export PermissionSetAssignment records
2. Add new assignments (UserId + PermissionSetId)
3. Import via Data Loader

### Custom Permission Sets

You may want to create custom permission sets for specific needs:

**Example: MI_ReadOnly_Viewer**
- Use case: Executive leadership, view-only access
- Permissions:
  - Read on MedicalInsight, Subject, junction objects
  - No Create/Edit/Delete
  - No Apex class access
  - RunReports = true

**To create:**
1. Navigate to **Setup → Permission Sets → New**
2. Name it: `Medical Insights - Read Only Viewer`
3. Clone permissions from MI_Ops_Manager
4. Remove Edit access
5. Save

---

## Data Quality Management

### Insight Quality Standards

Define standards for what constitutes a "quality" insight:

**Minimum standards:**
- [ ] At least 50 words of content
- [ ] Mentions at least one HCP or account
- [ ] Mentions at least one product (if applicable)
- [ ] AI Confidence score >0.5
- [ ] At least one subject assigned

**Gold standard:**
- [ ] 100-300 words of content
- [ ] Specific HCP name and context
- [ ] Specific product with dose
- [ ] Clear action item or takeaway
- [ ] AI Confidence score >0.75
- [ ] 1-3 subjects assigned

### Monitoring Data Quality

Create reports to track quality metrics:

**Report 1: Low Confidence Insights**
- Filter: AI_Confidence__c < 0.5
- Group by: CreatedBy
- Use: Identify users needing training

**Report 2: Brief Insights**
- Filter: LEN(Content) < 200
- Group by: CreatedBy
- Use: Coach users to provide more detail

**Report 3: Untagged Insights**
- Filter: Insights with no SubjectAssignment records
- Use: Identify systemic tagging issues

### Data Quality Workflows

Consider creating automated workflows:

**Workflow 1: Flag Low Quality**
- Trigger: MedicalInsight created
- Criteria: AI_Confidence__c < 0.3 OR LEN(Content) < 50
- Action: Send email to user with improvement tips

**Workflow 2: Escalate High Priority**
- Trigger: MedicalInsight created
- Criteria: AI_Action_Score__c > 0.9
- Action: Create Task for Medical Director, send Slack notification

**Workflow 3: Weekly Digest**
- Trigger: Scheduled (every Monday 8am)
- Action: Send email to team with last week's insight summary

### Data Retention Policy

Define how long to keep insights:

**Recommended retention:**
- Active insights: Keep indefinitely
- Archived insights: 7 years (regulatory compliance)
- Test/sample insights: Delete after 90 days

**To archive old insights:**
1. Create a checkbox field: `Archived__c`
2. Create a process or flow:
   - Criteria: CreatedDate < 3 years ago
   - Action: Set Archived__c = true
3. Filter reports/dashboards to exclude archived records

**To delete old test insights:**
```apex
List<MedicalInsight> testInsights = [
    SELECT Id FROM MedicalInsight
    WHERE Name LIKE 'Test%'
    AND CreatedDate < LAST_N_DAYS:90
];
delete testInsights;
```

---

## Reporting and Analytics

### Standard Reports

Create these reports for ongoing monitoring:

#### Insight Volume Reports
1. **Insights by Subject (Last 30 Days)**
   - Object: SubjectAssignment with MedicalInsight
   - Group by: Subject
   - Chart: Bar chart

2. **Insights by Product (Last 30 Days)**
   - Object: MedicalInsightProduct with MedicalInsight
   - Group by: Product
   - Chart: Horizontal bar

3. **Insights by User (Last 30 Days)**
   - Object: MedicalInsight
   - Group by: CreatedBy
   - Chart: Leaderboard

#### Quality Reports
1. **AI Confidence Distribution**
   - Object: MedicalInsight
   - Bucket AI_Confidence__c: <0.5, 0.5-0.7, 0.7-0.9, >0.9
   - Chart: Donut chart

2. **High Priority Insights**
   - Object: MedicalInsight
   - Filter: AI_Action_Score__c > 0.8
   - Columns: Name, AI_Summary__c, AI_Action_Score__c, CreatedBy, CreatedDate
   - Sort: AI_Action_Score__c DESC

#### Trend Reports
1. **Insight Volume Trend**
   - Object: MedicalInsight
   - Group by: CreatedDate (Week)
   - Show: Count
   - Chart: Line chart (last 12 weeks)

2. **Subject Trend**
   - Object: SubjectAssignment with MedicalInsight
   - Group by: CreatedDate (Week), Subject
   - Chart: Stacked bar chart

### Executive Dashboard

Create a dashboard for leadership:

**Components:**
1. Total Insights (Last 30 Days) - Metric
2. Insights by Subject - Donut Chart
3. High Priority Insights - Table
4. Insight Volume Trend - Line Chart
5. Top Products Mentioned - Horizontal Bar
6. Top HCPs Mentioned - Horizontal Bar
7. Average AI Confidence - Gauge
8. Field Team Leaderboard - Table

---

## Maintenance Tasks

### Weekly Tasks

**Monday Morning (15 minutes):**
- [ ] Review Apex Job failures from last week
- [ ] Check AI confidence trends
- [ ] Review high-priority insights
- [ ] Respond to user questions

### Monthly Tasks

**First Monday of Month (1 hour):**
- [ ] Generate executive report
- [ ] Review subject usage and consider taxonomy updates
- [ ] Check for orphaned records
- [ ] Review and optimize slow-running processes
- [ ] Update documentation if needed

### Quarterly Tasks

**End of Quarter (2-3 hours):**
- [ ] Conduct subject taxonomy audit
- [ ] User training refresher sessions
- [ ] Review permission sets and access
- [ ] Performance optimization review
- [ ] Archive old insights (if applicable)
- [ ] Review and update AI prompts

### Annual Tasks

**End of Year (1 day):**
- [ ] Comprehensive data quality audit
- [ ] Review all custom configurations
- [ ] Update all documentation
- [ ] Plan enhancements for next year
- [ ] Backup all data
- [ ] Review Salesforce release notes for relevant updates

---

## Advanced Configuration

### Custom Fields

Consider adding custom fields to MedicalInsight for your org's needs:

**Territory Management:**
- Territory__c (Lookup to Territory)
- Region__c (Picklist)

**Brand/Therapeutic Area:**
- Therapeutic_Area__c (Picklist)
- Brand__c (Picklist)

**Interaction Type:**
- Visit_Type__c (Picklist: Virtual, In-Person, Phone)
- Meeting_Purpose__c (Picklist: Medical Inquiry, Advisory Board, Speaker Program)

**Follow-Up:**
- Follow_Up_Required__c (Checkbox)
- Follow_Up_Due_Date__c (Date)
- Follow_Up_Completed__c (Checkbox)

### Workflow Automation

**Email Alerts on High Priority:**
```
Trigger: MedicalInsight created/updated
Criteria: AI_Action_Score__c > 0.9
Action: Send email to Medical Director
```

**Slack Notifications:**
Use Process Builder or Flow to:
1. Trigger on high-priority insight
2. Call external service (Slack webhook)
3. Post message to channel

**Task Creation:**
```
Trigger: MedicalInsight with Follow_Up_Required__c = true
Action: Create Task assigned to insight owner
```

### Integration with Other Systems

**CRM Activity Linking:**
- Add a lookup field: Related_Event__c (Lookup to Event)
- Capture insights directly from HCP meeting records

**External BI Tools:**
- Use MI_InsightsToJsonBuilder to export insights as JSON
- Send to external analytics platforms (Tableau, Power BI)

**Data Warehouse:**
- Schedule nightly export of insights to data warehouse
- Use Salesforce APIs or ETL tools

---

## Support Resources

- **Installation Guide**: [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md)
- **Setup Guide**: [SETUP_GUIDE.md](SETUP_GUIDE.md)
- **User Guide**: [USER_GUIDE.md](USER_GUIDE.md)
- **Salesforce Life Sciences Community**: Join for Q&A and best practices
- **Trailhead**: Search for "Life Sciences Cloud" modules

---

*Version 1.0 | Medical Insights Intelligence | Salesforce Labs*
