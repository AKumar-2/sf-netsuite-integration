@isTest
public class NetSuiteInboundServiceTest {

    @isTest
    static void testInboundPostSuccess() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/NetSuiteIntegration/Order';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"orderId": "NS-123", "status": "Pending"}');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        NetSuiteInboundService.handleInboundPost();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);

        List<Integration_Log__c> logs = [SELECT Id, Status__c, Object_Type__c FROM Integration_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Success', logs[0].Status__c);
        System.assertEquals('Order', logs[0].Object_Type__c);
    }

    @isTest
    static void testInboundPostError() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/NetSuiteIntegration/Order';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('Invalid JSON'); // Will cause JSON parsing exception

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        NetSuiteInboundService.handleInboundPost();
        Test.stopTest();

        System.assertEquals(500, res.statusCode);

        List<Integration_Log__c> logs = [SELECT Id, Status__c FROM Integration_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Failed', logs[0].Status__c);
    }
}
