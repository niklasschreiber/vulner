public class RemoveTargetFromSalesCadence {
  @InvocableMethod(
    label='Remove Target From Sales Cadence'
    description='Uses REST Invocable Action to remove a Target to a Sales Cadence'
  )
  public static void removeTarget(List<RemoveTargetRequest> targetsToRemove) {
    System.debug('*** Targets to remove *** ' + targetsToRemove);
    if (targetsToRemove != null) {
      for (RemoveTargetRequest req : targetsToRemove) {
        System.debug('*** request *** ' + req);
        System.debug('\ttarget: ' + req.targetId);
        System.debug('\tcompletion reason code: ' + req.completionReasonCode);
        sendRequest(req.targetId, req.completionReasonCode);
      }
    } else {
      System.debug('*** null targetsToRemove received ***');
    }
  }

  @future(callout=true)
  private static void sendRequest(
    String targetId,
    String completionReasonCode
  ) {
    String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm();
    String actionsRestURL = sfdcURL + '/services/data/v45.0/actions';
    String removeTargetRESTUrl =
      actionsRestURL + '/standard/removeTargetFromSalesCadence';

    HttpRequest httpReq = new HttpRequest();
    httpReq.setMethod('POST');
    httpReq.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
    httpReq.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
    httpReq.setEndpoint(removeTargetRESTUrl);
    httpReq.setHeader('Content-Type', 'application/json');
    httpReq.setBody(
      '{"inputs" : [{"completionReasonCode" : "' +
      completionReasonCode +
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

  public class RemoveTargetRequest {
    @InvocableVariable(required=true)
    public Id targetId;

    @InvocableVariable(required=true)
    public String completionReasonCode;
  }
}
