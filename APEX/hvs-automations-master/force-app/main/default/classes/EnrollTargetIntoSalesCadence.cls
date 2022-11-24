public class EnrollTargetIntoSalesCadence {
  @InvocableMethod(
    label='Enroll Target In Sales Cadence'
    description='Uses REST Invocable Action to assign a Target to a Sales Cadence'
  )
  public static void enrollTarget(List<EnrollTargetRequest> targetsToEnroll) {
    System.debug('*** Targets to enroll *** ' + targetsToEnroll);
    if (targetsToEnroll != null) {
      for (EnrollTargetRequest req : targetsToEnroll) {
        System.debug('*** request *** ' + req);
        System.debug('\ttarget: ' + req.targetId);
        System.debug('\tsales cadence: ' + req.salesCadenceName);
        sendRequest(req.targetId, req.salesCadenceName);
      }
    } else {
      System.debug('*** null targetsToEnroll receieved ***');
    }
  }

  @future(callout=true)
  private static void sendRequest(
    String targetId,
    String salesCadenceNameOrId
  ) {
    String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm();
    String actionsRestURL = sfdcURL + '/services/data/v45.0/actions';
    String assignTargetRESTUrl =
      actionsRestURL + '/standard/assignTargetToSalesCadence';

    HttpRequest httpReq = new HttpRequest();
    httpReq.setMethod('POST');
    httpReq.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
    httpReq.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
    httpReq.setEndpoint(assignTargetRESTUrl);
    httpReq.setHeader('Content-Type', 'application/json');
    httpReq.setBody(
      '{"inputs" : [{"salesCadenceNameOrId" : "' +
      salesCadenceNameOrId +
      '", "targetId" : "' +
      targetId +
      '"}]}'
    );

    String response = '';
    try {
      Http http = new Http();
      HttpResponse httpResponse = http.send(httpReq);
      if (httpResponse.getStatusCode() == 200) {
        response = JSON.serializePretty(
          JSON.deserializeUntyped(httpResponse.getBody())
        );
      } else {
        System.debug('http response: ' + httpResponse.getBody());
        throw new CalloutException(httpResponse.getBody());
      }
    } catch (System.Exception e) {
      System.debug('ERROR! ' + e);
      throw e;
    }

    System.debug('response: ' + response);
  }

  public class EnrollTargetRequest {
    @InvocableVariable(required=true)
    public Id targetId;

    @InvocableVariable(required=true)
    public String salesCadenceName;
  }
}
