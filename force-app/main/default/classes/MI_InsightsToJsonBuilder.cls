public with sharing class MI_InsightsToJsonBuilder {

    public class Output {
        @InvocableVariable
        public String json;
    }

    @InvocableMethod(label='Build Insights JSON Array')
    public static List<Output> build(List<String> insightIds) {
        List<Output> results = new List<Output>();

        // Convert List<String> → Set<Id>
        Set<Id> realIds = new Set<Id>();
        if (insightIds != null) {
            for (String s : insightIds) {
                if (!String.isBlank(s)) {
                    try {
                        realIds.add((Id)s);
                    } catch (Exception e) {
                        System.debug('Skipping non-ID value: ' + s);
                    }
                }
            }
        }

        // Handle empty
        if (realIds.isEmpty()) {
            Output out = new Output();
            out.json = '[]';
            results.add(out);
            return results;
        }

        // Query insights
        List<MedicalInsight> insights = [
            SELECT Id,
                   CreatedDate,
                   AI_Summary__c,
                   Content,
                   AI_Subject_Tags__c,
                   AI_Product_Tags__c,
                   AI_Account_Tags__c
            FROM MedicalInsight
            WHERE Id IN :realIds
        ];

        // Build JSON
        List<Map<String, Object>> dtoList = new List<Map<String, Object>>();
        for (MedicalInsight mi : insights) {
            Map<String, Object> m = new Map<String, Object>();

            m.put('id', (String)mi.Id);
            m.put('date', mi.CreatedDate.date().format());

            String summary = mi.AI_Summary__c;
            if (String.isBlank(summary)) summary = mi.Content;
            m.put('summary', summary);

            m.put('subjects', splitTags(mi.AI_Subject_Tags__c));
            m.put('products', splitTags(mi.AI_Product_Tags__c));
            m.put('accounts', splitTags(mi.AI_Account_Tags__c));

            dtoList.add(m);
        }

        Output finalOut = new Output();
        finalOut.json = JSON.serialize(dtoList);
        results.add(finalOut);
        return results;
    }

    private static List<String> splitTags(String raw) {
        if (String.isBlank(raw)) return new List<String>();

        List<String> parts = raw.split(';');
        List<String> cleaned = new List<String>();
        for (String p : parts) {
            if (p != null && !String.isBlank(p.trim())) {
                cleaned.add(p.trim());
            }
        }
        return cleaned;
    }
}