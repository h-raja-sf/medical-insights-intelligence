public with sharing class MI_AsyncInsightJob implements Queueable, Database.AllowsCallouts {

    private String utterance;
    private String productName;
    private String accountName;
    private String channel;
    private Id agentUserId;

    /**
     * @param utterance   Full user utterance text
     * @param productName Product name as plain text (e.g., "Immunexis 10mg")
     * @param accountName Account / HCP / HCO name as plain text (e.g., "Pavinder Gill")
     * @param channel     Source channel (e.g., "Agent", "Slack", "WebChat")
     * @param agentUserId User running the agent (for auditing if needed)
     */
    public MI_AsyncInsightJob(String utterance,
                              String productName,
                              String accountName,
                              String channel,
                              Id agentUserId) {
        this.utterance   = utterance;
        this.productName = productName;
        this.accountName = accountName;
        this.channel     = channel;
        this.agentUserId = agentUserId;
    }

    public void execute(QueueableContext qc) {
        // --- 1) Resolve Product2 by name (optional) ---
        Product2 prod = null;
        if (!String.isBlank(productName)) {
            try {
                prod = [
                    SELECT Id, Name
                    FROM Product2
                    WHERE Name = :productName
                    LIMIT 1
                ];
            } catch (Exception e) {
                // Swallow lookup errors – we don't want to fail the whole job
            }
        }

        // --- 2) Resolve Account by name (optional) ---
        Account acct = null;
        if (!String.isBlank(accountName)) {
            try {
                acct = [
                    SELECT Id, Name
                    FROM Account
                    WHERE Name = :accountName
                    LIMIT 1
                ];
            } catch (Exception e) {
                // Same: ignore lookup failures
            }
        }

        // --- 3) Create a Medical Insight record ---
        // IMPORTANT:
        // If your org uses the standard LSC MedicalInsight object, use "MedicalInsight" as the sObject name.
        // If it's a custom object, change "MedicalInsight__c" accordingly.
        // Also adjust field API names: Content, SourceType, etc.

        // Replace "MedicalInsight__c" with "MedicalInsight" if that's your real object name.
        MedicalInsight mi = new MedicalInsight();

        // Name – simple timestamp-based name for now
        mi.Name = 'Agent Insight - ' + Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

        // Content – respect 1000-character limit from the managed field
        // If your content field is "Content" (standard), change Content__c → Content
        String safeText = String.isBlank(utterance) ? '' : utterance;
        if (safeText.length() > 1000) {
            safeText = safeText.left(1000);
        }
        mi.Content = safeText;
        
        // REQUIRED: SourceType picklist must be set to a valid value
        // Adjust this to whatever you want to standardize on.
        mi.SourceType = 'Account';
        // or: mi.SourceType = 'Home Page'; etc.

        // Source type / channel – adjust to your picklist / fields
        // If you have a SourceType picklist, set it to "Agent" or similar
        // mi.SourceType__c = 'Agent';
        //if (!String.isBlank(channel)) {
        //    mi.SourceChannel__c = channel; // optional custom field
        //}

        // Optional: mark as queued for AI processing
        // mi.AI_ProcessingStatus__c = 'Queued';

        insert mi;

        // --- 4) (Optional) Link product/account via junction objects ---
        // If you are using MedicalInsightProduct / MedicalInsightAccount and
        // your org allows inserting them, you can uncomment this block and
        // adjust object/field API names as needed.

        /*
        if (prod != null) {
            MedicalInsightProduct__c mip = new MedicalInsightProduct__c();
            mip.MedicalInsight__c = mi.Id;
            mip.Product__c        = prod.Id;
            insert mip;
        }

        if (acct != null) {
            MedicalInsightAccount__c mia = new MedicalInsightAccount__c();
            mia.MedicalInsight__c = mi.Id;
            mia.Account__c        = acct.Id;
            insert mia;
        }
        */

        // Your existing record-triggered Flow on MedicalInsight will fire now
        // and handle AI tagging, subject/product/account tags, action score, etc.
    }
}