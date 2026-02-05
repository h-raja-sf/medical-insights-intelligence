public with sharing class MI_SubjectOptionsBuilder {

    public class Result {
        @InvocableVariable(required=true)
        public String json;
    }

    @InvocableMethod(label='Build Subject Options JSON')
    public static List<Result> build(List<String> dummy) {
        // Only child subjects, for Medical Insights
        List<Subject> subjects = [
            SELECT Id, Name, Description, ParentSubjectId
            FROM Subject
            WHERE UsageType = 'MedicalInsight'
            AND ParentSubjectId != null
            ORDER BY Name
            LIMIT 200
        ];

        List<Map<String, String>> payload = new List<Map<String, String>>();
        for (Subject s : subjects) {
            payload.add(new Map<String, String>{
                'id' => s.Id,
                'name' => s.Name,
                'description' => s.Description
            });
        }

        Result outVal = new Result();
        outVal.json = JSON.serialize(payload);
        return new List<Result>{ outVal };
    }
}