/**
 * This trigger listens for change events on the ActionCadenceStepTracker and publishes a platform
 * event (SalesCadenceStepTrackerEvent__e) whenever a step tracker is first started and when it is
 * completed.  You can then use Flows or Process Builder to listen to the platform event. */
trigger ActionCadenceStepTrackerChangeEventTrigger on ActionCadenceStepTrackerChangeEvent(
  after insert
) {
  List<SalesCadenceStepTrackerEvent__e> cadenceEvents = new List<SalesCadenceStepTrackerEvent__e>();
  List<String> stepTrackerIdsToQuery = new List<String>();
  for (ActionCadenceStepTrackerChangeEvent event : Trigger.New) {
    EventBus.ChangeEventHeader header = event.ChangeEventHeader;
    List<String> recordIds = event.ChangeEventHeader.getRecordIds();
    String stepTrackerId = recordIds.get(0);
    // If StepTracker was completed, then we should send an event
    if (header.changeType == 'UPDATE') {
      if (event.State == 'Completed') {
        // Update events do not have all the info we need so we have to query 
        stepTrackerIdsToQuery.add(stepTrackerId);
      }
    }
    // If StepTracker was created, then we should send an event
    if (header.changeType == 'CREATE') {
      SalesCadenceStepTrackerEvent__e cadenceEvent = new SalesCadenceStepTrackerEvent__e();
      cadenceEvent.StepTrackerId__c = stepTrackerId;
      cadenceEvent.CadenceId__c = event.ActionCadenceId;
      cadenceEvent.CadenceStepId__c = event.ActionCadenceStepId;
      cadenceEvent.State__c = event.State; // This will be 'Active' 
      cadenceEvent.StepType__c = event.StepType; // This will be SendAnEmail, MakeACall, etc.
      cadenceEvent.TargetId__c = event.TargetId; // This will be the lead, contact, person account id
      cadenceEvent.StepTitle__c = event.StepTitle;
      cadenceEvents.add(cadenceEvent);
    }
  }
  // Query for the step trackers
  if (stepTrackerIdsToQuery.size() > 0) {
    List<ActionCadenceStepTracker> stepTrackers = [
      SELECT
        Id,
        ActionCadenceId,
        ActionCadenceStepId,
        State,
        StepTitle,
        StepType,
        TargetId
      FROM ActionCadenceStepTracker
      WHERE Id IN :stepTrackerIdsToQuery
    ];
    for (ActionCadenceStepTracker stepTracker : stepTrackers) {
      SalesCadenceStepTrackerEvent__e cadenceEvent = new SalesCadenceStepTrackerEvent__e();
      cadenceEvent.StepTrackerId__c = stepTracker.Id;
      cadenceEvent.CadenceId__c = stepTracker.ActionCadenceId;
      cadenceEvent.CadenceStepId__c = stepTracker.ActionCadenceStepId;
      cadenceEvent.State__c = stepTracker.State; // This will be 'Completed'
      cadenceEvent.StepType__c = stepTracker.StepType; // This will be SendAnEmail, MakeACall, etc.
      cadenceEvent.TargetId__c = stepTracker.TargetId; // This will be the lead, contact, person account id
      cadenceEvent.StepTitle__c = stepTracker.StepTitle;
      cadenceEvents.add(cadenceEvent);
    }
  }
  // Publish the events for Flow or Process Builder to listen to  
  EventBus.publish(cadenceEvents);
}
