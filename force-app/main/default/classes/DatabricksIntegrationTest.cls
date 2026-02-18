@IsTest
private class DatabricksIntegrationTest {

    // Mock: token OK + main OK
    private class TokenOkMainOkMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();

            String endpoint = req.getEndpoint();

            if (endpoint != null && endpoint.startsWith('callout:DatabricksToken')) {
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"access_token":"TEST_ACCESS_TOKEN","token_type":"Bearer","expires_in":3600}');
                return res;
            }

            if (endpoint != null && endpoint.startsWith('callout:DatabricksMain/notify')) {
                // Basic assertions to hit more lines / validate headers
                System.assertEquals('POST', req.getMethod());
                System.assertEquals('application/json', req.getHeader('Content-Type'));
                System.assertEquals('Bearer TEST_ACCESS_TOKEN', req.getHeader('Authorization'));
                System.assert(!String.isBlank(req.getBody()), 'Expected body');

                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"ok":true}');
                return res;
            }

            if (endpoint != null && endpoint.startsWith('callout:DatabricksMain/jira-client-sync')) {
                System.assertEquals('POST', req.getMethod());
                System.assertEquals('application/json', req.getHeader('Content-Type'));
                System.assertEquals('Bearer TEST_ACCESS_TOKEN', req.getHeader('Authorization'));

                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"status_code":200,"message":"already exists"}');
                return res;
            }

            System.assert(false, 'Unexpected endpoint: ' + endpoint);
            res.setStatusCode(500);
            res.setBody('{"error":"Unexpected endpoint"}');
            return res;
        }
    }

    // Mock: token returns >= 400 to hit DatabricksIntegrationException branch
    private class TokenFailsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();

            String endpoint = req.getEndpoint();
            System.assert(endpoint != null && endpoint.startsWith('callout:DatabricksToken'));

            res.setStatusCode(401);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":"invalid_client"}');
            return res;
        }
    }

    // Mock: token OK but missing access_token to hit missing-field branch
    private class TokenMissingAccessTokenMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();

            String endpoint = req.getEndpoint();
            System.assert(endpoint != null && endpoint.startsWith('callout:DatabricksToken'));

            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"token_type":"Bearer","expires_in":3600}');
            return res;
        }
    }

    @IsTest
    static void test_sendPost_and_callNotify_success() {
        Test.setMock(HttpCalloutMock.class, new TokenOkMainOkMock());

        Test.startTest();
        // Covers callNotify -> sendPost -> fetchAccessToken
        HttpResponse res = DatabricksIntegration.callNotify('{"hello":"world"}');
        Test.stopTest();

        System.assertEquals(200, res.getStatusCode());
        System.assert(res.getBody().contains('"ok":true'));
    }

    @IsTest
    static void test_sendPost_success_otherEndpoint() {
        Test.setMock(HttpCalloutMock.class, new TokenOkMainOkMock());

        Test.startTest();
        HttpResponse res = DatabricksIntegration.sendPost(
            '/jira-client-sync',
            '{"account_name":"Acme Corp"}'
        );
        Test.stopTest();

        System.assertEquals(200, res.getStatusCode());
        System.assert(res.getBody().contains('"message"'));
    }

    @IsTest
    static void test_fetchAccessToken_throws_when_token_call_fails() {
        Test.setMock(HttpCalloutMock.class, new TokenFailsMock());

        Boolean threw = false;

        Test.startTest();
        try {
            // Any method that triggers token fetch
            DatabricksIntegration.sendPost('/jira-client-sync', '{"account_name":"Acme Corp"}');
        } catch (DatabricksIntegration.DatabricksIntegrationException e) {
            threw = true;
            System.assert(e.getMessage().contains('Databricks token request failed'));
            System.assert(e.getMessage().contains('Status: 401'));
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Expected DatabricksIntegrationException');
    }

    @IsTest
    static void test_fetchAccessToken_throws_when_access_token_missing() {
        Test.setMock(HttpCalloutMock.class, new TokenMissingAccessTokenMock());

        Boolean threw = false;

        Test.startTest();
        try {
            DatabricksIntegration.sendPost('/jira-client-sync', '{"account_name":"Acme Corp"}');
        } catch (DatabricksIntegration.DatabricksIntegrationException e) {
            threw = true;
            System.assert(e.getMessage().contains('missing access_token'));
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Expected DatabricksIntegrationException');
    }
}