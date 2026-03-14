@isTest
public class IntegrationFrameworkTest {

    // Mock class for successful HTTP callout
    public class MockHttpResponseSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    // Mock class for failed HTTP callout
    public class MockHttpResponseFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":"invalid_request"}');
            res.setStatusCode(400);
            return res;
        }
    }

    @isTest
    static void testLoggerSuccess() {
        IntegrationLogger.logSuccess('NetSuite', 'Account', '001000000000000', '{"name":"Test"}');

        List<Integration_Log__c> logs = [SELECT Id, Status__c, Object_Type__c FROM Integration_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Success', logs[0].Status__c);
    }

    @isTest
    static void testLoggerError() {
        IntegrationLogger.logError('NetSuite', 'Account', '001000000000000', 'Error occurred', '{"name":"Test"}');

        List<Integration_Log__c> logs = [SELECT Id, Status__c, Error_Message__c FROM Integration_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Failed', logs[0].Status__c);
        System.assertEquals('Error occurred', logs[0].Error_Message__c);
    }

    @isTest
    static void testSyncRecordSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        Test.startTest();
        NetSuiteIntegrationService.syncRecord('001000000000000', 'Account', '{"name":"Test"}');
        Test.stopTest();

        List<Integration_Log__c> logs = [SELECT Id, Status__c FROM Integration_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Success', logs[0].Status__c);
    }

    @isTest
    static void testSyncRecordFailure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseFailure());

        Test.startTest();
        NetSuiteIntegrationService.syncRecord('001000000000000', 'Account', '{"name":"Test"}');
        Test.stopTest();

        List<Integration_Log__c> logs = [SELECT Id, Status__c FROM Integration_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Failed', logs[0].Status__c);
    }

    @isTest
    static void testEventTrigger() {
        // Since we test future methods inside a trigger, test execution is asynchronous
        Integration_Event__e evt = new Integration_Event__e(
            Action__c = 'Sync',
            Object_Type__c = 'Account',
            Record_Id__c = '001000000000000',
            Payload__c = '{"name":"Test"}'
        );

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(evt);
        Test.stopTest(); // Future method executes here

        System.assertEquals(true, sr.isSuccess());

        // Assert log was created
        List<Integration_Log__c> logs = [SELECT Id, Status__c FROM Integration_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Success', logs[0].Status__c);
    }

    @isTest
    static void testRetryBatch() {
        // Create failed log
        Integration_Log__c log = new Integration_Log__c(
            Target_System__c = 'NetSuite',
            Object_Type__c = 'Account',
            Record_Id__c = '001000000000000',
            Status__c = 'Failed',
            Payload__c = '{"name":"RetryTest"}',
            Retry_Count__c = 0
        );
        insert log;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        Test.startTest();
        Database.executeBatch(new IntegrationRetryBatch());
        Test.stopTest();

        Integration_Log__c updatedLog = [SELECT Id, Status__c, Retry_Count__c FROM Integration_Log__c WHERE Id = :log.Id];
        System.assertEquals('Success', updatedLog.Status__c);
        System.assertEquals(1, updatedLog.Retry_Count__c);
    }

    @isTest
    static void testDashboardControllerGetLogs() {
        Integration_Log__c log = new Integration_Log__c(
            Target_System__c = 'NetSuite',
            Object_Type__c = 'Account',
            Status__c = 'Failed',
            Retry_Count__c = 0
        );
        insert log;

        List<Integration_Log__c> result = IntegrationDashboardController.getFailedLogs();
        System.assertEquals(1, result.size());
    }

    @isTest
    static void testDashboardControllerRetry() {
        Integration_Log__c log = new Integration_Log__c(
            Target_System__c = 'NetSuite',
            Object_Type__c = 'Account',
            Status__c = 'Failed',
            Payload__c = '{"name":"RetryTest"}',
            Retry_Count__c = 0
        );
        insert log;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        Test.startTest();
        IntegrationDashboardController.retryLog(log.Id);
        Test.stopTest();

        Integration_Log__c updatedLog = [SELECT Id, Status__c, Retry_Count__c FROM Integration_Log__c WHERE Id = :log.Id];
        System.assertEquals('Success', updatedLog.Status__c);
        System.assertEquals(1, updatedLog.Retry_Count__c);
    }
}
