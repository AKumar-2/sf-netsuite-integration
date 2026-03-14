public with sharing class IntegrationDashboardController {
    @AuraEnabled(cacheable=true)
    public static List<Integration_Log__c> getFailedLogs() {
        return [
            SELECT Id, Name, Target_System__c, Object_Type__c, Record_Id__c, Status__c, Error_Message__c, Retry_Count__c, SLA_Breached__c, CreatedDate
            FROM Integration_Log__c
            WHERE Status__c IN ('Failed', 'Retry Pending')
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }

    @AuraEnabled
    public static void retryLog(Id logId) {
        Integration_Log__c log = [SELECT Id, Target_System__c, Object_Type__c, Record_Id__c, Payload__c, Retry_Count__c FROM Integration_Log__c WHERE Id = :logId LIMIT 1];

        if (log != null && log.Payload__c != null) {
            log.Retry_Count__c = (log.Retry_Count__c != null ? log.Retry_Count__c : 0) + 1;

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
                    log.Error_Message__c = 'Manual Retry ' + log.Retry_Count__c + ' HTTP ' + res.getStatusCode() + ': ' + res.getBody();
                }
            } catch(Exception e) {
                log.Status__c = 'Failed';
                log.Error_Message__c = 'Manual Retry ' + log.Retry_Count__c + ' Exception: ' + e.getMessage();
            }
            update log;
        }
    }
}
