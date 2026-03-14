public with sharing class IntegrationEventHandler {
    public static void handleEvents(List<Integration_Event__e> events) {
        // Start Queueable job for handling callouts asynchronously and bulkified
        if(events != null && !events.isEmpty()) {
            System.enqueueJob(new IntegrationQueueable(events));
        }
    }
}
