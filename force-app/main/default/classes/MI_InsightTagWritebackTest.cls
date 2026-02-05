/**
 * @description Test class for MI_InsightTagWriteback
 * Validates junction object creation, deduplication, and error handling
 * Target: >80% code coverage
 */
@IsTest
private class MI_InsightTagWritebackTest {

    @TestSetup
    static void setupTestData() {
        // Create test Subjects with MedicalInsight usage type
        List<Subject> subjects = new List<Subject>();
        subjects.add(new Subject(
            Name = 'Clinical – Efficacy & Outcomes',
            Description = 'Clinical trial efficacy data and patient outcomes',
            UsageType = 'MedicalInsight'
        ));
        subjects.add(new Subject(
            Name = 'Clinical – Safety & Tolerability',
            Description = 'Adverse events and safety profiles',
            UsageType = 'MedicalInsight'
        ));
        subjects.add(new Subject(
            Name = 'Market Access – Reimbursement',
            Description = 'Payer coverage and reimbursement issues',
            UsageType = 'MedicalInsight'
        ));
        insert subjects;

        // Create test Products
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Immunexis 50mg', IsActive = true));
        products.add(new Product2(Name = 'Immunexis 100mg', IsActive = true));
        products.add(new Product2(Name = 'Cardixol 10mg', IsActive = true));
        insert products;

        // Create test Accounts (HCPs)
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'Dr. Sarah Chen'));
        accounts.add(new Account(Name = 'Dr. John Martinez'));
        accounts.add(new Account(Name = 'Dr. Emily Rodriguez'));
        insert accounts;

        // Create test MedicalInsights
        List<MedicalInsight> insights = new List<MedicalInsight>();
        insights.add(new MedicalInsight(
            Name = 'Test Insight 1',
            Content = 'Test content for medical insight 1',
            SourceType = 'Account'
        ));
        insights.add(new MedicalInsight(
            Name = 'Test Insight 2',
            Content = 'Test content for medical insight 2',
            SourceType = 'Account'
        ));
        insert insights;
    }

    /**
     * Test successful junction creation from valid JSON
     */
    @IsTest
    static void testSuccessfulJunctionCreation() {
        // Get test data
        MedicalInsight mi = [SELECT Id FROM MedicalInsight LIMIT 1];
        List<Subject> subjects = [SELECT Id, Name FROM Subject WHERE UsageType = 'MedicalInsight' LIMIT 2];
        List<Product2> products = [SELECT Id, Name FROM Product2 LIMIT 2];
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 2];

        // Build valid JSON response
        String modelJson = buildModelJson(subjects, products, accounts,
            'Patient experienced mild nausea with Immunexis',
            'immunexis-adverse-nausea',
            0.92,
            false,
            0.85
        );

        // Create input
        MI_InsightTagWriteback.Input input = new MI_InsightTagWriteback.Input();
        input.insightId = mi.Id;
        input.modelJson = modelJson;

        Test.startTest();
        List<MI_InsightTagWriteback.Output> results =
            MI_InsightTagWriteback.writeTagsToJunctions(new List<MI_InsightTagWriteback.Input>{ input });
        Test.stopTest();

        // Verify output
        System.assertEquals(1, results.size(), 'Should return one output');
        MI_InsightTagWriteback.Output out = results[0];
        System.assert(out.success, 'Should succeed: ' + out.errorMessage);
        System.assertEquals(2, out.subjectCount, 'Should create 2 subject assignments');
        System.assertEquals(2, out.productCount, 'Should create 2 product junctions');
        System.assertEquals(2, out.accountCount, 'Should create 2 account junctions');

        // Verify SubjectAssignments were created
        List<SubjectAssignment> subjectAssignments = [
            SELECT Id, SubjectId, AssignmentId, UsageType
            FROM SubjectAssignment
            WHERE AssignmentId = :mi.Id
        ];
        System.assertEquals(2, subjectAssignments.size(), 'Should have 2 subject assignments');
        System.assertEquals('MedicalInsight', subjectAssignments[0].UsageType, 'Should have correct usage type');

        // Verify MedicalInsightProduct junctions were created
        List<MedicalInsightProduct> productJunctions = [
            SELECT Id, MedicalInsightId, ProductId
            FROM MedicalInsightProduct
            WHERE MedicalInsightId = :mi.Id
        ];
        System.assertEquals(2, productJunctions.size(), 'Should have 2 product junctions');

        // Verify MedicalInsightAccount junctions were created
        List<MedicalInsightAccount> accountJunctions = [
            SELECT Id, MedicalInsightId, AccountId
            FROM MedicalInsightAccount
            WHERE MedicalInsightId = :mi.Id
        ];
        System.assertEquals(2, accountJunctions.size(), 'Should have 2 account junctions');

        // Verify MedicalInsight was updated
        MedicalInsight updated = [
            SELECT Name, AI_Action_Score__c, AI_Cluster_Key__c, AI_Confidence__c,
                   AI_Redacted__c, AI_Summary__c, AI_Model_Version__c
            FROM MedicalInsight
            WHERE Id = :mi.Id
        ];
        System.assertEquals('Patient experienced mild nausea with Immunexis', updated.Name,
            'Name should be updated with summary');
        System.assertEquals(0.85, updated.AI_Action_Score__c, 'Action score should be set');
        System.assertEquals('immunexis-adverse-nausea', updated.AI_Cluster_Key__c, 'Cluster key should be set');
        System.assertEquals(0.92, updated.AI_Confidence__c, 'Confidence should be set');
        System.assertEquals(false, updated.AI_Redacted__c, 'Redacted flag should be set');
        System.assertEquals('v1.0', updated.AI_Model_Version__c, 'Model version should be set');
    }

    /**
     * Test delete-and-recreate pattern (no duplicates)
     */
    @IsTest
    static void testDeduplication() {
        // Get test data
        MedicalInsight mi = [SELECT Id FROM MedicalInsight LIMIT 1];
        List<Subject> subjects = [SELECT Id, Name FROM Subject WHERE UsageType = 'MedicalInsight' LIMIT 2];
        List<Product2> products = [SELECT Id, Name FROM Product2 LIMIT 2];
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 2];

        // Create initial junctions manually
        insert new SubjectAssignment(
            AssignmentId = mi.Id,
            SubjectId = subjects[0].Id,
            UsageType = 'MedicalInsight'
        );
        insert new SubjectAssignment(
            AssignmentId = mi.Id,
            SubjectId = subjects[1].Id,
            UsageType = 'MedicalInsight'
        );

        // Use dynamic SObject creation for managed objects
        Schema.SObjectType mipType = Schema.getGlobalDescribe().get('MedicalInsightProduct');
        SObject mip1 = mipType.newSObject();
        mip1.put('MedicalInsightId', mi.Id);
        mip1.put('ProductId', products[0].Id);
        insert mip1;

        Schema.SObjectType miaType = Schema.getGlobalDescribe().get('MedicalInsightAccount');
        SObject mia1 = miaType.newSObject();
        mia1.put('MedicalInsightId', mi.Id);
        mia1.put('AccountId', accounts[0].Id);
        insert mia1;

        // Verify initial state
        System.assertEquals(2, [SELECT COUNT() FROM SubjectAssignment WHERE AssignmentId = :mi.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM MedicalInsightProduct WHERE MedicalInsightId = :mi.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM MedicalInsightAccount WHERE MedicalInsightId = :mi.Id]);

        // Run writeback with DIFFERENT data (should replace, not accumulate)
        List<Subject> newSubjects = new List<Subject>{subjects[0]}; // Only 1 subject this time
        String modelJson = buildModelJson(newSubjects, products, accounts,
            'Updated insight with different tags',
            'updated-cluster',
            0.88,
            false,
            0.75
        );

        MI_InsightTagWriteback.Input input = new MI_InsightTagWriteback.Input();
        input.insightId = mi.Id;
        input.modelJson = modelJson;

        Test.startTest();
        List<MI_InsightTagWriteback.Output> results =
            MI_InsightTagWriteback.writeTagsToJunctions(new List<MI_InsightTagWriteback.Input>{ input });
        Test.stopTest();

        // Verify delete-and-recreate worked
        System.assertEquals(1, [SELECT COUNT() FROM SubjectAssignment WHERE AssignmentId = :mi.Id],
            'Should have exactly 1 subject assignment (deleted old, inserted new)');
        System.assertEquals(2, [SELECT COUNT() FROM MedicalInsightProduct WHERE MedicalInsightId = :mi.Id],
            'Should have exactly 2 product junctions (deleted old, inserted new)');
        System.assertEquals(2, [SELECT COUNT() FROM MedicalInsightAccount WHERE MedicalInsightId = :mi.Id],
            'Should have exactly 2 account junctions (deleted old, inserted new)');
    }

    /**
     * Test handling of empty arrays (no junctions created)
     */
    @IsTest
    static void testEmptyArrays() {
        MedicalInsight mi = [SELECT Id FROM MedicalInsight LIMIT 1];

        // JSON with empty arrays
        String modelJson = '{"summary":"No specific tags",' +
            '"subjects":[],' +
            '"products":[],' +
            '"accounts":[],' +
            '"clusterKey":"general",' +
            '"confidence":0.5,' +
            '"redacted":false,' +
            '"actionScore":0.3}';

        MI_InsightTagWriteback.Input input = new MI_InsightTagWriteback.Input();
        input.insightId = mi.Id;
        input.modelJson = modelJson;

        Test.startTest();
        List<MI_InsightTagWriteback.Output> results =
            MI_InsightTagWriteback.writeTagsToJunctions(new List<MI_InsightTagWriteback.Input>{ input });
        Test.stopTest();

        // Verify success but no junctions created
        MI_InsightTagWriteback.Output out = results[0];
        System.assert(out.success, 'Should succeed with empty arrays');
        System.assertEquals(0, out.subjectCount, 'Should not create subject assignments');
        System.assertEquals(0, out.productCount, 'Should not create product junctions');
        System.assertEquals(0, out.accountCount, 'Should not create account junctions');

        // Verify no junctions exist
        System.assertEquals(0, [SELECT COUNT() FROM SubjectAssignment WHERE AssignmentId = :mi.Id]);
        System.assertEquals(0, [SELECT COUNT() FROM MedicalInsightProduct WHERE MedicalInsightId = :mi.Id]);
        System.assertEquals(0, [SELECT COUNT() FROM MedicalInsightAccount WHERE MedicalInsightId = :mi.Id]);

        // Verify MedicalInsight was still updated
        MedicalInsight updated = [SELECT Name, AI_Action_Score__c FROM MedicalInsight WHERE Id = :mi.Id];
        System.assertEquals('No specific tags', updated.Name, 'Name should still be updated');
        System.assertEquals(0.3, updated.AI_Action_Score__c, 'Action score should still be set');
    }

    /**
     * Test handling of invalid JSON
     */
    @IsTest
    static void testInvalidJson() {
        MedicalInsight mi = [SELECT Id FROM MedicalInsight LIMIT 1];

        // Invalid JSON
        String modelJson = '{"invalid": json syntax';

        MI_InsightTagWriteback.Input input = new MI_InsightTagWriteback.Input();
        input.insightId = mi.Id;
        input.modelJson = modelJson;

        Test.startTest();
        List<MI_InsightTagWriteback.Output> results =
            MI_InsightTagWriteback.writeTagsToJunctions(new List<MI_InsightTagWriteback.Input>{ input });
        Test.stopTest();

        // Verify failure is handled gracefully
        MI_InsightTagWriteback.Output out = results[0];
        System.assertEquals(false, out.success, 'Should fail with invalid JSON');
        System.assertNotEquals(null, out.errorMessage, 'Should return error message');
        System.assert(out.errorMessage.contains('Failed to parse'), 'Error should mention parsing failure');
    }

    /**
     * Test handling of null/blank JSON
     */
    @IsTest
    static void testBlankJson() {
        MedicalInsight mi = [SELECT Id FROM MedicalInsight LIMIT 1];

        MI_InsightTagWriteback.Input input = new MI_InsightTagWriteback.Input();
        input.insightId = mi.Id;
        input.modelJson = '';

        Test.startTest();
        List<MI_InsightTagWriteback.Output> results =
            MI_InsightTagWriteback.writeTagsToJunctions(new List<MI_InsightTagWriteback.Input>{ input });
        Test.stopTest();

        MI_InsightTagWriteback.Output out = results[0];
        System.assertEquals(false, out.success, 'Should fail with blank JSON');
        System.assert(out.errorMessage.contains('Failed to parse'), 'Should indicate parsing failure');
    }

    /**
     * Test handling of markdown-fenced JSON (common from LLMs)
     */
    @IsTest
    static void testMarkdownFencedJson() {
        MedicalInsight mi = [SELECT Id FROM MedicalInsight LIMIT 1];
        List<Subject> subjects = [SELECT Id, Name FROM Subject WHERE UsageType = 'MedicalInsight' LIMIT 1];

        // JSON wrapped in markdown fences
        String modelJson = '```json\n' +
            buildModelJson(subjects, new List<Product2>(), new List<Account>(),
                'Markdown test', 'markdown-test', 0.9, false, 0.6) +
            '\n```';

        MI_InsightTagWriteback.Input input = new MI_InsightTagWriteback.Input();
        input.insightId = mi.Id;
        input.modelJson = modelJson;

        Test.startTest();
        List<MI_InsightTagWriteback.Output> results =
            MI_InsightTagWriteback.writeTagsToJunctions(new List<MI_InsightTagWriteback.Input>{ input });
        Test.stopTest();

        // Verify markdown fences were stripped and parsing succeeded
        MI_InsightTagWriteback.Output out = results[0];
        System.assert(out.success, 'Should succeed after stripping markdown fences: ' + out.errorMessage);
        System.assertEquals(1, out.subjectCount, 'Should create subject assignment after fence stripping');
    }

    /**
     * Test bulk operation (multiple insights)
     */
    @IsTest
    static void testBulkOperation() {
        // Get multiple insights
        List<MedicalInsight> insights = [SELECT Id FROM MedicalInsight];
        System.assertEquals(2, insights.size(), 'Should have 2 test insights');

        List<Subject> subjects = [SELECT Id, Name FROM Subject WHERE UsageType = 'MedicalInsight' LIMIT 1];
        String modelJson = buildModelJson(subjects, new List<Product2>(), new List<Account>(),
            'Bulk test', 'bulk-test', 0.85, false, 0.7);

        // Build bulk inputs
        List<MI_InsightTagWriteback.Input> inputs = new List<MI_InsightTagWriteback.Input>();
        for (MedicalInsight mi : insights) {
            MI_InsightTagWriteback.Input input = new MI_InsightTagWriteback.Input();
            input.insightId = mi.Id;
            input.modelJson = modelJson;
            inputs.add(input);
        }

        Test.startTest();
        List<MI_InsightTagWriteback.Output> results =
            MI_InsightTagWriteback.writeTagsToJunctions(inputs);
        Test.stopTest();

        // Verify all succeeded
        System.assertEquals(2, results.size(), 'Should return 2 outputs');
        for (MI_InsightTagWriteback.Output out : results) {
            System.assert(out.success, 'All operations should succeed: ' + out.errorMessage);
            System.assertEquals(1, out.subjectCount, 'Each should create 1 subject');
        }

        // Verify total junctions created
        Integer totalSubjectAssignments = [SELECT COUNT() FROM SubjectAssignment WHERE AssignmentId IN :insights];
        System.assertEquals(2, totalSubjectAssignments, 'Should create 2 subject assignments total (1 per insight)');
    }

    /**
     * Test invalid IDs are skipped gracefully
     */
    @IsTest
    static void testInvalidIds() {
        MedicalInsight mi = [SELECT Id FROM MedicalInsight LIMIT 1];

        // JSON with invalid IDs (should skip them)
        String modelJson = '{"summary":"Invalid ID test",' +
            '"subjects":[{"id":"INVALID_ID","name":"Bad Subject"}],' +
            '"products":[{"id":"ALSO_INVALID","name":"Bad Product"}],' +
            '"accounts":[{"id":"NOT_A_REAL_ID","name":"Bad Account"}],' +
            '"clusterKey":"invalid-id-test",' +
            '"confidence":0.8,' +
            '"redacted":false,' +
            '"actionScore":0.5}';

        MI_InsightTagWriteback.Input input = new MI_InsightTagWriteback.Input();
        input.insightId = mi.Id;
        input.modelJson = modelJson;

        Test.startTest();
        List<MI_InsightTagWriteback.Output> results =
            MI_InsightTagWriteback.writeTagsToJunctions(new List<MI_InsightTagWriteback.Input>{ input });
        Test.stopTest();

        // Should succeed but create no junctions (invalid IDs skipped)
        MI_InsightTagWriteback.Output out = results[0];
        System.assert(out.success, 'Should succeed despite invalid IDs');
        System.assertEquals(0, out.subjectCount, 'Should skip invalid subject ID');
        System.assertEquals(0, out.productCount, 'Should skip invalid product ID');
        System.assertEquals(0, out.accountCount, 'Should skip invalid account ID');

        // But insight should still be updated
        MedicalInsight updated = [SELECT Name FROM MedicalInsight WHERE Id = :mi.Id];
        System.assertEquals('Invalid ID test', updated.Name, 'Should still update insight');
    }

    /**
     * Test long summary truncation (Name field has 255 char limit)
     */
    @IsTest
    static void testLongSummaryTruncation() {
        MedicalInsight mi = [SELECT Id FROM MedicalInsight LIMIT 1];

        // Create a summary longer than 255 characters
        String longSummary = 'This is a very long summary that exceeds the 255 character limit for the Name field. ' +
            'It contains detailed clinical information about adverse events, efficacy outcomes, and patient reported ' +
            'experiences that would typically be captured in a full medical insight record but needs to be truncated ' +
            'when used as the Name field to comply with Salesforce field length restrictions.';

        System.assert(longSummary.length() > 255, 'Summary should be longer than 255 chars');

        String modelJson = '{"summary":"' + longSummary + '",' +
            '"subjects":[],' +
            '"products":[],' +
            '"accounts":[],' +
            '"clusterKey":"truncation-test",' +
            '"confidence":0.9,' +
            '"redacted":false,' +
            '"actionScore":0.8}';

        MI_InsightTagWriteback.Input input = new MI_InsightTagWriteback.Input();
        input.insightId = mi.Id;
        input.modelJson = modelJson;

        Test.startTest();
        List<MI_InsightTagWriteback.Output> results =
            MI_InsightTagWriteback.writeTagsToJunctions(new List<MI_InsightTagWriteback.Input>{ input });
        Test.stopTest();

        MI_InsightTagWriteback.Output out = results[0];
        System.assert(out.success, 'Should succeed with long summary');

        // Verify Name was truncated
        MedicalInsight updated = [SELECT Name, AI_Summary__c FROM MedicalInsight WHERE Id = :mi.Id];
        System.assertEquals(255, updated.Name.length(), 'Name should be truncated to 255 chars');
        System.assertEquals(longSummary.substring(0, 255), updated.Name, 'Name should match first 255 chars');
    }

    /**
     * Test redacted flag is set correctly
     */
    @IsTest
    static void testRedactedFlag() {
        MedicalInsight mi = [SELECT Id FROM MedicalInsight LIMIT 1];

        String modelJson = '{"summary":"Contains PHI data",' +
            '"subjects":[],' +
            '"products":[],' +
            '"accounts":[],' +
            '"clusterKey":"phi-test",' +
            '"confidence":0.95,' +
            '"redacted":true,' +
            '"actionScore":0.9}';

        MI_InsightTagWriteback.Input input = new MI_InsightTagWriteback.Input();
        input.insightId = mi.Id;
        input.modelJson = modelJson;

        Test.startTest();
        List<MI_InsightTagWriteback.Output> results =
            MI_InsightTagWriteback.writeTagsToJunctions(new List<MI_InsightTagWriteback.Input>{ input });
        Test.stopTest();

        MedicalInsight updated = [SELECT AI_Redacted__c FROM MedicalInsight WHERE Id = :mi.Id];
        System.assertEquals(true, updated.AI_Redacted__c, 'Redacted flag should be set to true');
    }

    // ========== HELPER METHODS ==========

    /**
     * Builds a valid model JSON string for testing
     */
    private static String buildModelJson(
        List<Subject> subjects,
        List<Product2> products,
        List<Account> accounts,
        String summary,
        String clusterKey,
        Decimal confidence,
        Boolean redacted,
        Decimal actionScore
    ) {
        List<String> subjectRefs = new List<String>();
        for (Subject s : subjects) {
            subjectRefs.add('{"id":"' + s.Id + '","name":"' + s.Name + '"}');
        }

        List<String> productRefs = new List<String>();
        for (Product2 p : products) {
            productRefs.add('{"id":"' + p.Id + '","name":"' + p.Name + '"}');
        }

        List<String> accountRefs = new List<String>();
        for (Account a : accounts) {
            accountRefs.add('{"id":"' + a.Id + '","name":"' + a.Name + '"}');
        }

        String json = '{' +
            '"summary":"' + summary + '",' +
            '"subjects":[' + String.join(subjectRefs, ',') + '],' +
            '"products":[' + String.join(productRefs, ',') + '],' +
            '"accounts":[' + String.join(accountRefs, ',') + '],' +
            '"clusterKey":"' + clusterKey + '",' +
            '"confidence":' + confidence + ',' +
            '"redacted":' + redacted + ',' +
            '"actionScore":' + actionScore +
        '}';

        return json;
    }
}
