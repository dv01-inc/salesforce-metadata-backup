@RestResource(urlMapping='/jiraWebhookFlow/*')
global with sharing class JiraWebhookFlowTrigger {

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        String body = req.requestBody.toString();

        // 🔐 Validate X-Auth-Key header
        String expectedSecret = 'qzFJgYr6rjNYc5EM2UWaK1sw0CkU4v6W9k7A+0sFw5s=';  // ✅ Store this in Custom Metadata in production
        String providedSecret = req.headers.get('X-Auth-Key');

        if (String.isBlank(providedSecret) || providedSecret != expectedSecret) {
            RestContext.response.statusCode = 401;
            RestContext.response.responseBody = Blob.valueOf('Unauthorized: Invalid Auth Key');
            return;
        }

        try {
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(body);
        
            String issueKey    = (String) jsonMap.get('issueKey');
            String newStatus   = (String) jsonMap.get('newStatus');
            String title       = (String) jsonMap.get('title');
            String description = (String) jsonMap.get('description');
            String clientStr   = (String) jsonMap.get('client');
            String startDateStr= (String) jsonMap.get('start_date');
            String endDateStr  = (String) jsonMap.get('end_date');
        
            // --- Convert comma-separated client string into a List<String> ---
            List<String> clientList = new List<String>();
            if (!String.isBlank(clientStr)) {
                // Split on commas (handles normal CSV without quotes)
                for (String c : clientStr.split(',')) {
                    if (!String.isBlank(c)) {
                        clientList.add(c.trim());
                    }
                }
            }
        
            // --- Convert date strings into Date objects ---
            Date startDateVal;
            Date endDateVal;
            try {
                if (!String.isBlank(startDateStr)) startDateVal = Date.valueOf(startDateStr);
                if (!String.isBlank(endDateStr))   endDateVal   = Date.valueOf(endDateStr);
            } catch (Exception ex) {
                // If parsing fails, leave nulls so Flow can handle them gracefully
            }
        
            Map<String, Object> flowInputs = new Map<String, Object>{
                'issueKey'    => issueKey,
                'newStatus'   => newStatus,
                'title'       => title,
                'description' => description,
                'client'      => clientList,   // now a Text Collection
                'start_date'  => startDateVal, // real Date variable
                'end_date'    => endDateVal    // real Date variable
            };

            Flow.Interview.Jira_To_Salesforce flow =
                (Flow.Interview.Jira_To_Salesforce) Flow.Interview.createInterview('Jira_To_Salesforce', flowInputs);
            flow.start();

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf('Flow triggered successfully');
        } catch (Exception e) {
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('Error: ' + e.getMessage());
        }
    }
}