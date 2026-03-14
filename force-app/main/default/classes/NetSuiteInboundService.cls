@RestResource(urlMapping='/NetSuiteIntegration/*')
global with sharing class NetSuiteInboundService {

    @HttpPost
    global static void handleInboundPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String requestBody = req.requestBody.toString();
        String uri = req.requestURI;
        // Example URI: /services/apexrest/NetSuiteIntegration/Order
        String objectType = uri.substring(uri.lastIndexOf('/') + 1);

        try {
            // Processing logic based on ObjectType
            // For a complete framework, this would deserialize the generic payload
            // and perform upserts on Products, Orders, Invoices.
            // As a framework placeholder, we'll assume success if JSON is valid.

            Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            // Log successful inbound
            IntegrationLogger.logSuccess('NetSuite Inbound', objectType, 'N/A', requestBody);

            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"status": "Success", "message": "Record received successfully."}');
        } catch (Exception e) {
            // Log error
            IntegrationLogger.logError('NetSuite Inbound', objectType, 'N/A', e.getMessage(), requestBody);

            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{"status": "Error", "message": "' + e.getMessage() + '"}');
        }
    }
}
