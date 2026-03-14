public with sharing class NetSuiteIntegrationService {

    // Example endpoints depending on object type
    public static final String NS_NAMED_CREDENTIAL = 'callout:NetSuite_API';

    public static void syncRecord(Id recordId, String objectType, String payload) {
        HttpRequest req = new HttpRequest();
        String endpoint = NS_NAMED_CREDENTIAL + '/' + objectType.toLowerCase();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(payload);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                IntegrationLogger.logSuccess('NetSuite', objectType, recordId, payload);
            } else {
                String errorMsg = 'HTTP ' + res.getStatusCode() + ': ' + res.getBody();
                IntegrationLogger.logError('NetSuite', objectType, recordId, errorMsg, payload);
            }
        } catch(Exception e) {
            IntegrationLogger.logError('NetSuite', objectType, recordId, e.getMessage(), payload);
        }
    }

    @future(callout=true)
    public static void syncRecordFuture(Id recordId, String objectType, String payload) {
        syncRecord(recordId, objectType, payload);
    }
}
