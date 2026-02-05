public with sharing class MI_InsightResultParserTags {

    // Input wrapper from Flow
    public class Input {
        @InvocableVariable(required=true)
        public String modelJson;
    }

    // Output wrapper back to Flow
    public class Output {
        @InvocableVariable public String summary;
        @InvocableVariable public String clusterKey;
        @InvocableVariable public Decimal confidence;
        @InvocableVariable public Boolean redacted;
        @InvocableVariable public Decimal actionScore;

        // Names (joined) for display / reporting
        @InvocableVariable public String subjectNamesJoined;
        @InvocableVariable public String productNamesJoined;
        @InvocableVariable public String accountNamesJoined;

        // IDs (collections) for junctions / downstream logic
        @InvocableVariable public List<String> subjectIds;
        @InvocableVariable public List<String> productIds;
        @InvocableVariable public List<String> accountIds;
    }

    // DTOs for JSON deserialize
    private class SubjectRef { public String id; public String name; }
    private class ProductRef { public String id; public String name; }
    private class AccountRef { public String id; public String name; }
    private class GoalRef { public String name; }

    private class ModelDto {
        public String summary;
        public List<SubjectRef> subjects;
        public List<ProductRef> products;
        public List<AccountRef> accounts;
        public String clusterKey;
        public Decimal confidence;
        public Boolean redacted;
        public List<GoalRef> goals;
        public Decimal actionScore;
    }

    @InvocableMethod(label='Parse Medical Insight Model JSON (Joined Tags + IDs)')
    public static List<Output> parse(List<Input> inputs) {
        List<Output> results = new List<Output>();

        for (Input inp : inputs) {
            Output o = new Output();

            // Initialize defaults so Flow never sees null collections
            o.subjectNamesJoined = '';
            o.productNamesJoined = '';
            o.accountNamesJoined = '';
            o.subjectIds = new List<String>();
            o.productIds = new List<String>();
            o.accountIds = new List<String>();

            if (String.isBlank(inp.modelJson)) {
                // Nothing to parse – just return empty output
                results.add(o);
                continue;
            }

            // Clean up common JSON issues
            String raw = inp.modelJson;

            // Trim whitespace and non-breaking spaces at both ends
            String cleaned = raw.trim();
            cleaned = cleaned.replace('\u00A0', ' '); // NBSP → normal space

            // Strip markdown fences if present
            if (cleaned.startsWith('```')) {
                Integer firstFenceEnd = cleaned.indexOf('```', 3);
                if (firstFenceEnd > 0) {
                    cleaned = cleaned.substring(firstFenceEnd + 3).trim();
                    if (cleaned.endsWith('```')) {
                        cleaned = cleaned.substring(0, cleaned.length() - 3).trim();
                    }
                }
            }

            ModelDto dto;
            try {
                dto = (ModelDto)JSON.deserialize(cleaned, ModelDto.class);
            } catch (System.JSONException e) {
                // IMPORTANT: do NOT throw – log and return empty so the Flow doesn't fail
                System.debug('MI_InsightResultParserTags JSON parse FAILED: ' + e.getMessage());
                System.debug('MI_InsightResultParserTags raw JSON: ' + raw);
                results.add(o);
                continue;
            }

            // Normal mapping if JSON parsed OK
            o.summary     = dto.summary;
            o.clusterKey  = dto.clusterKey;
            o.confidence  = dto.confidence;
            o.redacted    = dto.redacted;
            o.actionScore = dto.actionScore;

            // Collect names and IDs
            List<String> subjectNames = new List<String>();
            if (dto.subjects != null) {
                for (SubjectRef s : dto.subjects) {
                    if (s == null) continue;
                    if (!String.isBlank(s.name)) {
                        subjectNames.add(s.name);
                    }
                    if (!String.isBlank(s.id)) {
                        o.subjectIds.add(s.id);
                    }
                }
            }

            List<String> productNames = new List<String>();
            if (dto.products != null) {
                for (ProductRef p : dto.products) {
                    if (p == null) continue;
                    if (!String.isBlank(p.name)) {
                        productNames.add(p.name);
                    }
                    if (!String.isBlank(p.id)) {
                        o.productIds.add(p.id);
                    }
                }
            }

            List<String> accountNames = new List<String>();
            if (dto.accounts != null) {
                for (AccountRef a : dto.accounts) {
                    if (a == null) continue;
                    if (!String.isBlank(a.name)) {
                        accountNames.add(a.name);
                    }
                    if (!String.isBlank(a.id)) {
                        o.accountIds.add(a.id);
                    }
                }
            }

            o.subjectNamesJoined = String.join(subjectNames, '; ');
            o.productNamesJoined = String.join(productNames, '; ');
            o.accountNamesJoined = String.join(accountNames, '; ');

            results.add(o);
        }

        return results;
    }
}