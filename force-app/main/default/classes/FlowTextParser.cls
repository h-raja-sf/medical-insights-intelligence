public class FlowTextParser {

    @InvocableMethod(label='Parse Text for Selection' description='Parses a block of text into a list of structured records for user selection.')
    public static List<List<TaskOutput>> parseText(List<TaskInput> inputs) {
        
        List<List<TaskOutput>> allTaskOutputs = new List<List<TaskOutput>>();

        for (TaskInput input : inputs) {
            List<TaskOutput> parsedTasks = new List<TaskOutput>();
            String[] rawTasks = input.textToParse.split('(?=Key Objectives:)');

            for (String rawTask : rawTasks) {
                if (String.isNotBlank(rawTask)) {
                    TaskOutput taskOutput = new TaskOutput();

                    taskOutput.keyObjective = extractValue(rawTask, 'Key Objectives:', 'Action Plan Name:');
                    taskOutput.actionPlanName = extractValue(rawTask, 'Action Plan Name:', 'Task Name:');
                    taskOutput.taskName = extractValue(rawTask, 'Task Name:', 'Task Description:');
                    taskOutput.taskDescription = extractValue(rawTask, 'Task Description:', 'Score:');
                    taskOutput.score = extractValue(rawTask, 'Score:', '');

                    parsedTasks.add(taskOutput);
                }
            }
            allTaskOutputs.add(parsedTasks);
        }
        return allTaskOutputs;
    }

    private static String extractValue(String source, String startKey, String endKey) {
        Integer startIndex = source.indexOf(startKey);
        if (startIndex == -1) {
            return null;
        }
        startIndex += startKey.length();

        Integer endIndex;
        if (String.isNotBlank(endKey)) {
            endIndex = source.indexOf(endKey, startIndex);
        } else {
            endIndex = source.length();
        }

        if (endIndex == -1) {
            endIndex = source.length();
        }

        return source.substring(startIndex, endIndex).trim();
    }

    public class TaskInput {
        @InvocableVariable(required=true)
        public String textToParse;
    }

    public class TaskOutput {
        @AuraEnabled @InvocableVariable
        public String keyObjective;
        @AuraEnabled @InvocableVariable
        public String actionPlanName;
        @AuraEnabled @InvocableVariable
        public String taskName;
        @AuraEnabled @InvocableVariable
        public String taskDescription;
        @AuraEnabled @InvocableVariable
        public String score;
    }
}