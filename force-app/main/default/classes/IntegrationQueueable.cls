public class IntegrationQueueable implements Queueable, Database.AllowsCallouts {

    private List<Integration_Event__e> eventsToProcess;

    public IntegrationQueueable(List<Integration_Event__e> events) {
        this.eventsToProcess = events;
    }

    public void execute(QueueableContext context) {
        // Only process up to 100 callouts per transaction.
        // If more than 100 events, process 100 and chain the rest.
        Integer limitToProcess = Math.min(this.eventsToProcess.size(), 100);
        List<Integration_Event__e> currentBatch = new List<Integration_Event__e>();
        List<Integration_Event__e> remainingBatch = new List<Integration_Event__e>();

        for(Integer i = 0; i < this.eventsToProcess.size(); i++) {
            if(i < limitToProcess) {
                currentBatch.add(this.eventsToProcess[i]);
            } else {
                remainingBatch.add(this.eventsToProcess[i]);
            }
        }

        for(Integration_Event__e evt : currentBatch) {
            if(evt.Action__c == 'Sync') {
                NetSuiteIntegrationService.syncRecord(evt.Record_Id__c, evt.Object_Type__c, evt.Payload__c);
            }
        }

        if(!remainingBatch.isEmpty()) {
            if(!Test.isRunningTest()) {
                System.enqueueJob(new IntegrationQueueable(remainingBatch));
            }
        }
    }
}
