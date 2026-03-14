public with sharing class IntegrationLogger {

    public static Integration_Log__c createLog(String targetSystem, String objectType, String recordId, String status, String errorMessage, String payload) {
        Integration_Log__c log = new Integration_Log__c(
            Target_System__c = targetSystem,
            Object_Type__c = objectType,
            Record_Id__c = recordId,
            Status__c = status,
            Error_Message__c = errorMessage,
            Payload__c = payload,
            Retry_Count__c = 0
        );
        return log;
    }

    public static void logSuccess(String targetSystem, String objectType, String recordId, String payload) {
        Integration_Log__c log = createLog(targetSystem, objectType, recordId, 'Success', null, payload);
        insert log;
    }

    public static void logError(String targetSystem, String objectType, String recordId, String errorMessage, String payload) {
        Integration_Log__c log = createLog(targetSystem, objectType, recordId, 'Failed', errorMessage, payload);
        insert log;
    }
}
