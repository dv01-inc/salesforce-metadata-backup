// DatabricksIntegration.cls
// Helper for calling a Databricks endpoint using OAuth 2.0 client_credentials.
//
// Prereqs:
// 1) Custom Metadata Type: Databricks_OAuth_Settings__mdt
//    - Record DeveloperName: DatabricksConfig
//    - Fields (at least):
//        * Client_Id__c      (Text)
//        * Client_Secret__c  (Text)
// 2) Named Credential (no auth): DatabricksToken
//    - URL: https://1671591340373218.8.gcp.databricks.com/oidc/v1/token
// 3) Named Credential (no auth): DatabricksMain
//    - URL: https://sfdc-helper-endpoint-1671591340373218.gcp.databricksapps.com/   <-- note trailing slash

public with sharing class DatabricksIntegration {

    // CMDT record name
    private static final String CONFIG_RECORD_NAME = 'DatabricksConfig';

    // Named Credential API names
    private static final String TOKEN_NC = 'DatabricksToken';
    private static final String MAIN_NC  = 'DatabricksMain';

    // Custom exception
    public class DatabricksIntegrationException extends Exception {}

    /**
     * Convenience method: POST to /notify with the given JSON body.
     *
     * @param jsonBody JSON string to send to the Databricks /notify endpoint.
     */
    public static HttpResponse callNotify(String jsonBody) {
        return sendPost('/notify', jsonBody);
    }

    /**
     * Generic POST helper for the Databricks app.
     *
     * @param relativePath Path relative to DatabricksMain NC, e.g. "/notify"
     * @param jsonBody     JSON payload
     */
    public static HttpResponse sendPost(String relativePath, String jsonBody) {
        String token = fetchAccessToken();

        HttpRequest req = new HttpRequest();
        req.setMethod('POST');

        // IMPORTANT:
        // DatabricksMain NC URL must end with "/"
        // so "callout:DatabricksMain/notify" resolves correctly.
        req.setEndpoint('callout:' + MAIN_NC + relativePath);

        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setBody(jsonBody);

        Http http = new Http();
        HttpResponse res = http.send(req);

        return res;
    }

    /**
     * Fetches an access token from Databricks using client_credentials flow.
     * Reads client_id and client_secret from Databricks_OAuth_Settings__mdt.
     */
    private static String fetchAccessToken() {
        Databricks_OAuth_Settings__mdt cfg =
            Databricks_OAuth_Settings__mdt.getInstance(CONFIG_RECORD_NAME);

        if (cfg == null) {
            throw new DatabricksIntegrationException(
                'Custom Metadata record DatabricksConfig not found on Databricks_OAuth_Settings__mdt.'
            );
        }

        HttpRequest req = new HttpRequest();
        req.setMethod('POST');

        // DatabricksToken NC should point directly to the token URL
        req.setEndpoint('callout:' + TOKEN_NC);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        String body =
              'grant_type=client_credentials'
            + '&client_id='     + EncodingUtil.urlEncode(cfg.Client_Id__c, 'UTF-8')
            + '&client_secret=' + EncodingUtil.urlEncode(cfg.Client_Secret__c, 'UTF-8')
            + '&scope=all-apis';

        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() >= 400) {
            throw new DatabricksIntegrationException(
                'Databricks token request failed. Status: '
                + res.getStatusCode() + ', Body: ' + res.getBody()
            );
        }

        Map<String, Object> json =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        if (!json.containsKey('access_token')) {
            throw new DatabricksIntegrationException(
                'Token response missing access_token. Body: ' + res.getBody()
            );
        }

        return (String) json.get('access_token');
    }
}