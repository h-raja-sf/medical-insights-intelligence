public with sharing class MI_ProductOptionsBuilder {

    public class Result {
        @InvocableVariable(required=true)
        public String json;
    }

    @InvocableMethod(label='Build Product Options JSON')
    public static List<Result> build(List<String> dummy) {
        // Adjust to LifeSciMarketableProduct if needed
        List<Product2> prods = [
            SELECT Id, Name
            FROM Product2
            WHERE IsActive = true
            LIMIT 200
        ];

        List<Map<String, String>> payload = new List<Map<String, String>>();
        for (Product2 p : prods) {
            payload.add(new Map<String, String>{
                'id' => p.Id,
                'name' => p.Name
            });
        }

        Result outVal = new Result();
        outVal.json = JSON.serialize(payload);
        return new List<Result>{ outVal };
    }
}