@IsTest
private class DatabricksNotifyFlowActionTest {

    private class NotifyMock implements HttpCalloutMock {
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

            // Main /notify call
            if (endpoint != null && endpoint.startsWith('callout:DatabricksMain/notify')) {
                System.assertEquals('POST', req.getMethod());
                System.assertEquals('application/json', req.getHeader('Content-Type'));
                System.assertEquals('Bearer TEST_ACCESS_TOKEN', req.getHeader('Authorization'));
                System.assertEquals('{"hello":"world"}', req.getBody());

                res.setStatusCode(200);
                res.setBody('{"ok":true}');
                return res;
            }

            System.assert(false, 'Unexpected endpoint called: ' + endpoint);
            res.setStatusCode(500);
            res.setBody('{"error":"Unexpected endpoint"}');
            return res;
        }
    }

    @IsTest
    static void test_notify_success() {
        Test.setMock(HttpCalloutMock.class, new NotifyMock());

        DatabricksNotifyFlowAction.Request r = new DatabricksNotifyFlowAction.Request();
        r.bodyJson = '{"hello":"world"}';

        Test.startTest();
        List<DatabricksNotifyFlowAction.Response> results =
            DatabricksNotifyFlowAction.notify(new List<DatabricksNotifyFlowAction.Request>{ r });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(200, results[0].statusCode);
        System.assert(results[0].responseBody.contains('"ok":true'));
    }
}