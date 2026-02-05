/**
 * @description Writes AI tagging results to standard Life Sciences Cloud junction objects
 *              instead of custom text fields. This enables proper filtering, reporting,
 *              and scalability.
 *
 * Uses static SOQL for SubjectAssignment (managed package limitation) and dynamic for others.
 *
 * @author Medical Insights Intelligence Package
 * @date 2026-02-04
 */
public with sharing class MI_InsightTagWriteback {

    // ========== INVOCABLE INTERFACE ==========

    public class Input {
        @InvocableVariable(required=true description='MedicalInsight record ID to update')
        public Id insightId;

        @InvocableVariable(required=true description='JSON response from Insight Tagger prompt template')
        public String modelJson;
    }

    public class Output {
        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String errorMessage;

        @InvocableVariable
        public Integer subjectCount;

        @InvocableVariable
        public Integer productCount;

        @InvocableVariable
        public Integer accountCount;
    }

    @InvocableMethod(
        label='Write Medical Insight Tags to Junctions'
        description='Parses AI output and writes to SubjectAssignment, MedicalInsightProduct, and MedicalInsightAccount junction objects. Replaces custom text field updates.'
        category='Medical Insights'
    )
    public static List<Output> writeTagsToJunctions(List<Input> inputs) {
        List<Output> results = new List<Output>();

        for (Input inp : inputs) {
            Output out = new Output();
            out.success = true;
            out.subjectCount = 0;
            out.productCount = 0;
            out.accountCount = 0;

            try {
                // Parse the JSON from the prompt template
                ModelDto dto = parseModelJson(inp.modelJson);

                if (dto == null) {
                    out.success = false;
                    out.errorMessage = 'Failed to parse model JSON';
                    results.add(out);
                    continue;
                }

                // Delete existing junctions (ensures no duplicates)
                deleteExistingJunctions(inp.insightId);

                // Insert new junctions
                out.subjectCount = insertSubjectAssignments(inp.insightId, dto.subjects);
                out.productCount = insertProductJunctions(inp.insightId, dto.products);
                out.accountCount = insertAccountJunctions(inp.insightId, dto.accounts);

                // Update MedicalInsight record with AI fields
                updateInsightRecord(inp.insightId, dto);

            } catch (Exception e) {
                out.success = false;
                out.errorMessage = e.getMessage();
                System.debug(LoggingLevel.ERROR, 'MI_InsightTagWriteback error: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            }

            results.add(out);
        }

        return results;
    }

    // ========== JSON PARSING ==========

    private class ModelDto {
        public String summary;
        public List<RefDto> subjects;
        public List<RefDto> products;
        public List<RefDto> accounts;
        public String clusterKey;
        public Decimal confidence;
        public Boolean redacted;
        public Decimal actionScore;
        public String modelVersion;
    }

    private class RefDto {
        public String id;
        public String name;
    }

    /**
     * @description Parses the JSON output from the prompt template
     * Handles common issues like markdown fences, whitespace, etc.
     */
    private static ModelDto parseModelJson(String rawJson) {
        if (String.isBlank(rawJson)) {
            return null;
        }

        // Clean up the JSON
        String cleaned = rawJson.trim();
        cleaned = cleaned.replace('\u00A0', ' '); // NBSP → space

        // Strip markdown code fences if present (```json ... ```)
        if (cleaned.startsWith('```')) {
            Integer firstFenceEnd = cleaned.indexOf('\n', 3);
            if (firstFenceEnd > 0) {
                cleaned = cleaned.substring(firstFenceEnd + 1).trim();
            }
            if (cleaned.endsWith('```')) {
                cleaned = cleaned.substring(0, cleaned.length() - 3).trim();
            }
        }

        try {
            ModelDto dto = (ModelDto) JSON.deserialize(cleaned, ModelDto.class);
            return dto;
        } catch (System.JSONException e) {
            System.debug(LoggingLevel.ERROR, 'JSON parse failed: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Raw JSON: ' + rawJson);
            return null;
        }
    }

    // ========== JUNCTION DELETION ==========

    /**
     * @description Deletes all existing junction records for this MedicalInsight
     * This ensures clean state before inserting new tags (no duplicates)
     *
     * NOTE: Uses static SOQL for SubjectAssignment due to managed package limitations.
     * Dynamic SOQL works for MedicalInsightProduct and MedicalInsightAccount.
     */
    private static void deleteExistingJunctions(Id insightId) {
        List<SObject> toDelete = new List<SObject>();

        // Delete SubjectAssignments - MUST use static SOQL (managed package limitation)
        List<SubjectAssignment> existingSubjects = [
            SELECT Id
            FROM SubjectAssignment
            WHERE AssignmentId = :insightId
        ];
        toDelete.addAll(existingSubjects);

        // Delete MedicalInsightProduct junctions - dynamic SOQL works
        String productQuery = 'SELECT Id FROM MedicalInsightProduct WHERE MedicalInsightId = \'' + insightId + '\'';
        toDelete.addAll(Database.query(productQuery));

        // Delete MedicalInsightAccount junctions - dynamic SOQL works
        String accountQuery = 'SELECT Id FROM MedicalInsightAccount WHERE MedicalInsightId = \'' + insightId + '\'';
        toDelete.addAll(Database.query(accountQuery));

        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }

    // ========== JUNCTION INSERTION ==========

    /**
     * @description Creates SubjectAssignment records
     * Uses Set to deduplicate subject IDs from the model output
     * Uses static typing for SubjectAssignment (managed package requirement)
     */
    private static Integer insertSubjectAssignments(Id insightId, List<RefDto> subjects) {
        if (subjects == null || subjects.isEmpty()) {
            return 0;
        }

        // Deduplicate using Set
        Set<Id> uniqueSubjectIds = new Set<Id>();
        for (RefDto ref : subjects) {
            if (!String.isBlank(ref.id)) {
                try {
                    uniqueSubjectIds.add(Id.valueOf(ref.id));
                } catch (Exception e) {
                    System.debug(LoggingLevel.WARN, 'Invalid Subject ID: ' + ref.id);
                }
            }
        }

        if (uniqueSubjectIds.isEmpty()) {
            return 0;
        }

        // Create SubjectAssignment records using static typing
        List<SubjectAssignment> assignments = new List<SubjectAssignment>();
        for (Id subjectId : uniqueSubjectIds) {
            assignments.add(new SubjectAssignment(
                AssignmentId = insightId,  // Links to MedicalInsight
                SubjectId = subjectId,
                UsageType = 'MedicalInsight'
            ));
        }

        insert assignments;
        return assignments.size();
    }

    /**
     * @description Creates MedicalInsightProduct junction records
     * Uses Set to deduplicate product IDs
     * Uses dynamic SObject creation for flexibility
     */
    private static Integer insertProductJunctions(Id insightId, List<RefDto> products) {
        if (products == null || products.isEmpty()) {
            return 0;
        }

        // Deduplicate using Set
        Set<Id> uniqueProductIds = new Set<Id>();
        for (RefDto ref : products) {
            if (!String.isBlank(ref.id)) {
                try {
                    uniqueProductIds.add(Id.valueOf(ref.id));
                } catch (Exception e) {
                    System.debug(LoggingLevel.WARN, 'Invalid Product ID: ' + ref.id);
                }
            }
        }

        if (uniqueProductIds.isEmpty()) {
            return 0;
        }

        // Create MedicalInsightProduct records dynamically
        List<SObject> junctions = new List<SObject>();
        Schema.SObjectType mipType = Schema.getGlobalDescribe().get('MedicalInsightProduct');

        for (Id productId : uniqueProductIds) {
            SObject mip = mipType.newSObject();
            mip.put('MedicalInsightId', insightId);
            mip.put('ProductId', productId);  // Note: ProductId, not Product2Id
            junctions.add(mip);
        }

        insert junctions;
        return junctions.size();
    }

    /**
     * @description Creates MedicalInsightAccount junction records
     * Uses Set to deduplicate account IDs
     * Uses dynamic SObject creation for flexibility
     */
    private static Integer insertAccountJunctions(Id insightId, List<RefDto> accounts) {
        if (accounts == null || accounts.isEmpty()) {
            return 0;
        }

        // Deduplicate using Set
        Set<Id> uniqueAccountIds = new Set<Id>();
        for (RefDto ref : accounts) {
            if (!String.isBlank(ref.id)) {
                try {
                    uniqueAccountIds.add(Id.valueOf(ref.id));
                } catch (Exception e) {
                    System.debug(LoggingLevel.WARN, 'Invalid Account ID: ' + ref.id);
                }
            }
        }

        if (uniqueAccountIds.isEmpty()) {
            return 0;
        }

        // Create MedicalInsightAccount records dynamically
        List<SObject> junctions = new List<SObject>();
        Schema.SObjectType miaType = Schema.getGlobalDescribe().get('MedicalInsightAccount');

        for (Id accountId : uniqueAccountIds) {
            SObject mia = miaType.newSObject();
            mia.put('MedicalInsightId', insightId);
            mia.put('AccountId', accountId);
            junctions.add(mia);
        }

        insert junctions;
        return junctions.size();
    }

    // ========== MEDICALINSIGHT UPDATE ==========

    /**
     * @description Updates the MedicalInsight record with AI-derived fields
     * Uses AI summary as the Name field (truncated to 255 chars)
     * Uses dynamic SObject for compatibility
     */
    private static void updateInsightRecord(Id insightId, ModelDto dto) {
        // Use dynamic SObject creation
        Schema.SObjectType miType = Schema.getGlobalDescribe().get('MedicalInsight');
        SObject mi = miType.newSObject();
        mi.put('Id', insightId);

        // Use AI summary as the Name (required field)
        if (!String.isBlank(dto.summary)) {
            String safeName = dto.summary.length() > 255
                ? dto.summary.substring(0, 255)
                : dto.summary;
            mi.put('Name', safeName);
        }

        // Update AI analytics fields (keep these for dashboards/reporting)
        if (dto.actionScore != null) {
            mi.put('AI_Action_Score__c', dto.actionScore);
        }

        if (!String.isBlank(dto.clusterKey)) {
            mi.put('AI_Cluster_Key__c', dto.clusterKey);
        }

        if (dto.confidence != null) {
            mi.put('AI_Confidence__c', dto.confidence);
        }

        if (dto.redacted != null) {
            mi.put('AI_Redacted__c', dto.redacted);
        }

        // Store model version for auditing
        if (!String.isBlank(dto.modelVersion)) {
            mi.put('AI_Model_Version__c', dto.modelVersion);
        } else {
            mi.put('AI_Model_Version__c', 'v1.0'); // Default version
        }

        // Also store the summary in the custom field if you want to preserve it
        if (!String.isBlank(dto.summary)) {
            mi.put('AI_Summary__c', dto.summary.length() > 255
                ? dto.summary.substring(0, 255)
                : dto.summary);
        }

        update mi;
    }
}
