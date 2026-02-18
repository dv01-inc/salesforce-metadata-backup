@IsTest
private class DatabricksJiraClientSyncFlowActionTest {

    private class JiraSyncMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            String endpoint = req.getEndpoint();

            // Token call
            if (endpoint != null && endpoint.startsWith('callout:DatabricksToken')) {
                System.assertEquals('POST', req.getMethod());
                res.setStatusCode(200);
                res.setBody('{"access_token":"TEST_ACCESS_TOKEN","token_type":"Bearer","expires_in":3600}');
                return res;
            }

            // Main /jira-client-sync call
            if (endpoint != null && endpoint.startsWith('callout:DatabricksMain/jira-client-sync')) {
                System.assertEquals('POST', req.getMethod());
                System.assertEquals('application/json', req.getHeader('Content-Type'));
                System.assertEquals('Bearer TEST_ACCESS_TOKEN', req.getHeader('Authorization'));

                Map<String, Object> body =
                    (Map<String, Object>) JSON.deserializeUntyped(req.getBody());

                System.assertEquals('Acme Corp', String.valueOf(body.get('account_name')));

                res.setStatusCode(200);
                res.setBody('{"status_code":200,"message":"added Acme Corp to JIRA client field"}');
                return res;
            }

            System.assert(false, 'Unexpected endpoint called: ' + endpoint);
            res.setStatusCode(500);
            res.setBody('{"error":"Unexpected endpoint"}');
            return res;
        }
    }

    @IsTest
    static void test_jiraClientSync_success() {
        Test.setMock(HttpCalloutMock.class, new JiraSyncMock());

        DatabricksJiraClientSyncFlowAction.Request r =
            new DatabricksJiraClientSyncFlowAction.Request();
        r.account_name = 'Acme Corp';

        Test.startTest();
        List<DatabricksJiraClientSyncFlowAction.Response> results =
            DatabricksJiraClientSyncFlowAction.jiraClientSync(
                new List<DatabricksJiraClientSyncFlowAction.Request>{ r }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(200, results[0].statusCode);
        System.assertEquals(200, results[0].app_status_code);
        System.assertEquals('added Acme Corp to JIRA client field', results[0].message);
        System.assert(results[0].responseBody.contains('"status_code":200'));
    }

    @IsTest
    static void test_jiraClientSync_blankAccountName_validation() {
        DatabricksJiraClientSyncFlowAction.Request r =
            new DatabricksJiraClientSyncFlowAction.Request();
        r.account_name = '   ';

        Test.startTest();
        List<DatabricksJiraClientSyncFlowAction.Response> results =
            DatabricksJiraClientSyncFlowAction.jiraClientSync(
                new List<DatabricksJiraClientSyncFlowAction.Request>{ r }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(0, results[0].statusCode);
        System.assertEquals('Validation error: account_name is required.', results[0].responseBody);
    }
}