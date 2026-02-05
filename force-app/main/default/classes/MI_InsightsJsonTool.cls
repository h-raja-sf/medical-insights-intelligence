public with sharing class MI_InsightsJsonTool {

    public class Request {
        @InvocableVariable(required=true)
        public String userQuestion;      // original user question

        @InvocableVariable(required=false)
        public String productFilter;     // e.g. "Immunexis" (name or substring)

        @InvocableVariable(required=false)
        public Integer daysBack;         // e.g. 30 for "last 30 days"

        @InvocableVariable(required=false)
        public String timeWindowLabel;   // e.g. "Last 30 days", "ACR 2025 Congress"
    }

    public class Response {
        @InvocableVariable
        public String insightsJson;      // JSON array for the summarizer prompt

        @InvocableVariable
        public String userQuestion;

        @InvocableVariable
        public String timeWindowLabel;
    }

    @InvocableMethod(label='Build Insights JSON For Themes')
    public static List<Response> build(List<Request> requests) {
        List<Response> results = new List<Response>();

        if (requests == null || requests.isEmpty()) {
            Response empty = new Response();
            empty.insightsJson   = '[]';
            empty.userQuestion   = '';
            empty.timeWindowLabel = '';
            results.add(empty);
            return results;
        }

        for (Request req : requests) {
            if (req == null) continue;

            Integer daysBack = (req.daysBack == null || req.daysBack <= 0)
                ? 30
                : req.daysBack;

            Date cutoffDate = Date.today().addDays(-daysBack);

            // 1) SOQL: ONLY filter on CreatedDate (filterable)
            List<MedicalInsight> allInsightsForWindow = [
                SELECT Id,
                       CreatedDate,
                       AI_Summary__c,
                       Content,
                       AI_Subject_Tags__c,
                       AI_Product_Tags__c,
                       AI_Account_Tags__c
                FROM MedicalInsight
                WHERE CreatedDate >= :cutoffDate
            ];

            // 2) In-memory filter by product, since AI_Product_Tags__c is a long text
            List<MedicalInsight> filteredInsights = new List<MedicalInsight>();
            String productFilterLower = String.isBlank(req.productFilter)
                ? null
                : req.productFilter.toLowerCase();

            for (MedicalInsight mi : allInsightsForWindow) {
                if (productFilterLower == null) {
                    // No product filter → include everything
                    filteredInsights.add(mi);
                } else {
                    String tags = mi.AI_Product_Tags__c;
                    if (tags != null && tags.toLowerCase().contains(productFilterLower)) {
                        filteredInsights.add(mi);
                    }
                }
            }

            // 3) Build DTO list from filteredInsights
            List<Map<String, Object>> dtoList = new List<Map<String, Object>>();
            for (MedicalInsight mi : filteredInsights) {
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

            Response out = new Response();
            out.insightsJson    = JSON.serialize(dtoList);
            out.userQuestion    = req.userQuestion;
            out.timeWindowLabel = String.isBlank(req.timeWindowLabel)
                                  ? ('Last ' + daysBack + ' days')
                                  : req.timeWindowLabel;
            results.add(out);
        }

        return results;
    }

    // Utility to split semi-colon delimited tags into a List<String>
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