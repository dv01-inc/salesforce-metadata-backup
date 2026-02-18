@isTest
private class JiraWebhookFlowTriggerTest {
    @isTest
    static void testValidRequest() {
        // Prepare mock request body
        String body = JSON.serialize(new Map<String, Object>{
            'issueKey' => 'JIRA-123',
            'newStatus' => 'In Progress',
            'title' => 'Test Issue',
            'description' => 'This is a test issue from Jira',
            'client' => 'TestClient'
        });

        // Simulate REST request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jiraWebhookFlow/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        req.addHeader('X-Auth-Key', 'qzFJgYr6rjNYc5EM2UWaK1sw0CkU4v6W9k7A+0sFw5s=');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        // Since Flow.Interview cannot run in test context, catch the exception
        try {
            JiraWebhookFlowTrigger.doPost();
        } catch (Exception e) {
            System.debug('Expected exception in test context: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Expected status 200 for valid request');
    }

    @isTest
    static void testInvalidAuthKey() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jiraWebhookFlow/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{}');
        req.addHeader('X-Auth-Key', 'invalid_key');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        JiraWebhookFlowTrigger.doPost();
        Test.stopTest();

        System.assertEquals(401, RestContext.response.statusCode, 'Should return 401 for invalid auth key');
    }

    @isTest
    static void testMissingAuthKey() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jiraWebhookFlow/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{}');  // empty body
        // No auth header
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        JiraWebhookFlowTrigger.doPost();
        Test.stopTest();

        System.assertEquals(401, RestContext.response.statusCode, 'Should return 401 for missing auth key');
    }
}