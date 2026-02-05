public with sharing class MI_AccountOptionsBuilder {

    public class Result {
        @InvocableVariable(required=true)
        public String json;
    }

    @InvocableMethod(label='Build Account Options JSON')
    public static List<Result> build(List<String> dummy) {
        List<Account> accts = [
            SELECT Id, Name
            FROM Account
        ];

        List<Map<String, String>> payload = new List<Map<String, String>>();
        for (Account a : accts) {
            payload.add(new Map<String, String>{
                'id' => a.Id,
                'name' => a.Name
            });
        }

        Result outVal = new Result();
        outVal.json = JSON.serialize(payload);
        return new List<Result>{ outVal };
    }
}