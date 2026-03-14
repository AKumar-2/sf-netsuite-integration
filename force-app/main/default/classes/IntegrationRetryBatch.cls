public class IntegrationRetryBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Find failed logs or retry pending, limit to max retries
        String query = 'SELECT Id, Record_Id__c, Object_Type__c, Payload__c, Retry_Count__c FROM Integration_Log__c WHERE Status__c IN (\'Failed\', \'Retry Pending\') AND Retry_Count__c < 3 AND Target_System__c = \'NetSuite\'';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Integration_Log__c> scope) {
        List<Integration_Log__c> logsToUpdate = new List<Integration_Log__c>();

        for(Integration_Log__c log : scope) {
            log.Retry_Count__c = (log.Retry_Count__c != null ? log.Retry_Count__c : 0) + 1;

            // Attempt to re-sync
            HttpRequest req = new HttpRequest();
            String endpoint = NetSuiteIntegrationService.NS_NAMED_CREDENTIAL + '/' + log.Object_Type__c.toLowerCase();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(log.Payload__c);

            Http http = new Http();
            try {
                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    log.Status__c = 'Success';
                    log.Error_Message__c = '';
                } else {
                    log.Status__c = 'Failed';
                    log.Error_Message__c = 'Retry ' + log.Retry_Count__c + ' HTTP ' + res.getStatusCode() + ': ' + res.getBody();
                }
            } catch(Exception e) {
                log.Status__c = 'Failed';
                log.Error_Message__c = 'Retry ' + log.Retry_Count__c + ' Exception: ' + e.getMessage();
            }
            logsToUpdate.add(log);
        }

        if(!logsToUpdate.isEmpty()) {
            update logsToUpdate;
        }
    }

    public void finish(Database.BatchableContext BC) {
        // Any finalization logic
    }
}
