public class SlackPub {

    private static final String MESSAGE_TEMPLATE = 'The following {0} has changed:\n{1}\nNew {2}: *{3}*';

    private static final String SLACK_HOOK_URL = getSlackHookUrl();

    public class PubRecord {
        @InvocableVariable(label='Object Type')
        public String objName;
        @InvocableVariable(label='Name Value')
        public String nameValue;
        @InvocableVariable(label='Field 1 Name')
        public String field1Name;
        @InvocableVariable(label='Field 1 Value')
        public String field1Value;
    }

    @InvocableMethod(label='Post Record Changes to Slack')
    public static void postToSlack(List<PubRecord> records) {
        PubRecord record = records[0];
        List<String> inputVals = getListFromPubRecord(record);

        String msgText = String.format(MESSAGE_TEMPLATE,inputVals);

        Map<String, Object> msg = new Map<String,Object>();
        msg.put('text', msgText);
        msg.put('mrkdwn', true);

        String body = JSON.serialize(msg);

        // DEMO POINT 4: Here's where we actually instantiate and
        // pass the Queueable object to the queue, in order to execute it.
        System.enqueueJob(new QueueableSlackCall(SLACK_HOOK_URL, 'POST', body));
    }

    private static List<String> getListFromPubRecord(PubRecord record){
        List<String> fieldList = new List<String>();
        fieldList.add(record.objName);
        fieldList.add(record.nameValue);
        fieldList.add(record.field1Name);
        fieldList.add(record.field1Value);
        return fieldList;
    }

    // DEMO POINT 2: We are using an async callout via a Queuable class. Means asynchronous and can be monitored.
    // AllowsCallouts interface tells the Apex runtime that a callout will be permitted from this bit of code.
    public class QueueableSlackCall implements System.Queueable, Database.AllowsCallouts {

        private final String url;
        private final String method;
        private final String body;
        public QueueableSlackCall(String url, String method, String body){
            this.url = url;
            this.method = method;
            this.body = body;
        }

        // DEMO POINT 3: In the execute method we see a straightforward HTTP request
        public void execute(System.QueueableContext ctx){
            //An instance of HTTP is used to invoked the request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod(method);
            req.setBody(body);
            Http http = new Http();
            // Returns instance of HTTPResponse with any response data (none in this case, so we just leave it).
            HttpResponse resp = http.send(req);
        }
    }

    // DEMO POINT 1: We are retrieving the Slack hook URL from a custom metadata type.
    // This is a best practice because our token is safely stored, it's not hard coded and an admin can change it.
    private static String getSlackHookUrl() {
        Slack_Settings__mdt[] settings = [SELECT Post_Web_Hook__c FROM Slack_Settings__mdt LIMIT 1];
        if (settings.size() == 0 || settings[0].Post_Web_Hook__c == null) {
            throw new SlackConfigException('Missing Slack_Settings__mdt Custom Metadata');
        }
        return settings[0].Post_Web_Hook__c;
    }

    public class SlackConfigException extends Exception {}
}
