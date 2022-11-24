/**
 * This trigger listens for change events on the ActionCadenceTracker and publishes a platform
 * event (SalesCadenceTrackerEvent__e) whenever a tracker is first started and when it is
 * completed.  You can then use Flows or Process Builder to listen to the platform event. */
trigger ActionCadenceTrackerChangeEventTrigger on ActionCadenceTrackerChangeEvent(
  after insert
) {
  List<SalesCadenceTrackerEvent__e> cadenceEvents = new List<SalesCadenceTrackerEvent__e>();
  List<String> trackerIdsToQuery = new List<String>();
  for (ActionCadenceTrackerChangeEvent event : Trigger.New) {
    EventBus.ChangeEventHeader header = event.ChangeEventHeader;
    List<String> recordIds = event.ChangeEventHeader.getRecordIds();
    String trackerId = recordIds.get(0);
    // If Tracker was completed, then we should send an event
    if (header.changeType == 'UPDATE') {
      if (event.State == 'Complete') {
        // Update events do not have all the info we need so we have to query
        trackerIdsToQuery.add(trackerId);
      }
    }
    // If Tracker was created, then we should send an event
    if (header.changeType == 'CREATE') {
      SalesCadenceTrackerEvent__e cadenceEvent = new SalesCadenceTrackerEvent__e();
      cadenceEvent.TrackerId__c = trackerId;
      cadenceEvent.CadenceId__c = event.ActionCadenceId;
      cadenceEvent.State__c = event.State; // This will be 'Running'
      cadenceEvent.TargetId__c = event.TargetId; // This will be the lead, contact, person account id
      cadenceEvents.add(cadenceEvent);
    }
    // Query for the trackers info for UPDATES
    if (trackerIdsToQuery.size() > 0) {
      List<ActionCadenceTracker> trackers = [
        SELECT Id, ActionCadenceId, State, TargetId
        FROM ActionCadenceTracker
        WHERE Id IN :trackerIdsToQuery
      ];
      for (ActionCadenceTracker tracker : trackers) {
        SalesCadenceTrackerEvent__e cadenceEvent = new SalesCadenceTrackerEvent__e();
        cadenceEvent.TrackerId__c = tracker.Id;
        cadenceEvent.CadenceId__c = tracker.ActionCadenceId;
        cadenceEvent.State__c = tracker.State; // This will be 'Complete'
        cadenceEvent.TargetId__c = tracker.TargetId; // This will be the lead, contact, person account id
        cadenceEvents.add(cadenceEvent);
      }
    }
  }

  // Publish the events for Flow or Process Builder to listen to
  EventBus.publish(cadenceEvents);
}
