@IsTest
private class MI_AgentCaptureInvokerTest {

    @IsTest
    static void testEnqueueInsight() {
        MI_AgentCaptureInvoker.Input input = new MI_AgentCaptureInvoker.Input();
        input.utterance   = 'Dr. Pavinder Gill is seeing early response variability with Immunexis 10mg in CKD patients.';
        input.productName = 'Immunexis 10mg';
        input.accountName = 'Pavinder Gill';
        input.channel     = 'Agent';

        Test.startTest();
        List<MI_AgentCaptureInvoker.Output> outputs =
            MI_AgentCaptureInvoker.enqueueInsight(new List<MI_AgentCaptureInvoker.Input>{ input });
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'One output expected');
        System.assertNotEquals(null, outputs[0].enqueuedJobId, 'Job Id should be set');
    }
}