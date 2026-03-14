@isTest
public class IntegrationQueueableTest {

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

    @isTest
    static void testQueueableExecution() {
        List<Integration_Event__e> events = new List<Integration_Event__e>();
        // Add 5 events
        for(Integer i = 0; i < 5; i++) {
            events.add(new Integration_Event__e(
                Action__c = 'Sync',
                Object_Type__c = 'Account',
                Record_Id__c = '00100000000000' + i,
                Payload__c = '{"name":"Test' + i + '"}'
            ));
        }

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        Test.startTest();
        System.enqueueJob(new IntegrationQueueable(events));
        Test.stopTest(); // Synchronously executes queueable job

        List<Integration_Log__c> logs = [SELECT Id, Status__c FROM Integration_Log__c];
        System.assertEquals(5, logs.size());
        for(Integration_Log__c log : logs) {
            System.assertEquals('Success', log.Status__c);
        }
    }
}
