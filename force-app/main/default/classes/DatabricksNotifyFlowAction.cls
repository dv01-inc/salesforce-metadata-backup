public with sharing class DatabricksNotifyFlowAction {

    public class Request {
        @InvocableVariable(required=true)
        public String bodyJson;
    }

    public class Response {
        @InvocableVariable
        public Integer statusCode;

        @InvocableVariable
        public String responseBody;
    }

    @InvocableMethod(
        label='Call Databricks Notify'
        description='POSTs JSON to the Databricks /notify endpoint.'
    )
    public static List<Response> notify(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request r : requests) {
            HttpResponse res = DatabricksIntegration.callNotify(r.bodyJson);

            Response out = new Response();
            out.statusCode   = res.getStatusCode();
            out.responseBody = res.getBody();
            results.add(out);
        }

        return results;
    }
}