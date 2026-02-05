public with sharing class MI_AgentCaptureInvoker {

    public class Input {
        @InvocableVariable(required=true)
        public String utterance;

        @InvocableVariable(required=false)
        public String productName;

        @InvocableVariable(required=false)
        public String accountName;

        @InvocableVariable(required=false)
        public String channel;
    }

    public class Output {
        @InvocableVariable
        public Id enqueuedJobId;

        @InvocableVariable
        public Id insightId; // optional future use (we don't set it currently)
    }

    @InvocableMethod(
        label='Enqueue Medical Insight Capture'
        description='Enqueue a background job to turn a user utterance into a Medical Insight record.'
    )
    public static List<Output> enqueueInsight(List<Input> inputs) {
        List<Output> results = new List<Output>();

        for (Input inRec : inputs) {
            Output out = new Output();

            // Basic guardrail – ignore very short/empty utterances
            if (String.isBlank(inRec.utterance) || inRec.utterance.length() < 20) {
                results.add(out);
                continue;
            }

            MI_AsyncInsightJob job = new MI_AsyncInsightJob(
                inRec.utterance,
                inRec.productName,
                inRec.accountName,
                inRec.channel,
                UserInfo.getUserId()
            );
            Id jobId = System.enqueueJob(job);

            out.enqueuedJobId = jobId;
            // We don't know the insight Id at enqueue time; let your Flow / reports handle it.
            results.add(out);
        }

        return results;
    }
}