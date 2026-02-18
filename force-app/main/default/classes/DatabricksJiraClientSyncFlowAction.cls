public with sharing class DatabricksJiraClientSyncFlowAction {

    public class Request {
        @InvocableVariable(required=true)
        public String account_name;
    }

    public class Response {
        @InvocableVariable
        public Integer statusCode;

        @InvocableVariable
        public String responseBody;

        // Optional parsed fields from Databricks response
        @InvocableVariable
        public Integer app_status_code;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Databricks: Jira Client Sync'
        description='POSTs account_name to Databricks /jira-client-sync endpoint.'
    )
    public static List<Response> jiraClientSync(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request r : requests) {
            Response out = new Response();

            try {
                if (String.isBlank(r.account_name)) {
                    out.statusCode = 0;
                    out.responseBody = 'Validation error: account_name is required.';
                    results.add(out);
                    continue;
                }

                Map<String, Object> payload = new Map<String, Object>{
                    'account_name' => r.account_name
                };

                String jsonBody = JSON.serialize(payload);

                HttpResponse res =
                    DatabricksIntegration.sendPost('/jira-client-sync', jsonBody);

                out.statusCode   = res.getStatusCode();
                out.responseBody = res.getBody();

                // Best-effort parse for Flow outputs
                try {
                    Object parsed = JSON.deserializeUntyped(res.getBody());
                    if (parsed instanceof Map<String, Object>) {
                        Map<String, Object> m = (Map<String, Object>) parsed;

                        if (m.containsKey('status_code') && m.get('status_code') != null) {
                            out.app_status_code = (Integer) m.get('status_code');
                        }
                        if (m.containsKey('message') && m.get('message') != null) {
                            out.message = String.valueOf(m.get('message'));
                        }
                    }
                } catch (Exception ignoreParse) {
                    // Swallow parse errors; Flow still gets raw responseBody
                }

            } catch (Exception e) {
                // Prevent one failure from killing the entire Flow action
                out.statusCode = 0;
                out.responseBody = 'Exception: ' + e.getMessage();
            }

            results.add(out);
        }

        return results;
    }
}