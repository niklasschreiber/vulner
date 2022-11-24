trigger UpdateLeadOnStepCompletionTrigger on ActionCadenceStepTrackerChangeEvent(
  after insert
) {
  for (ActionCadenceStepTrackerChangeEvent event : Trigger.New) {
    EventBus.ChangeEventHeader header = event.ChangeEventHeader;
    List<String> recordIds = header.getRecordIds();

    System.debug(
      'Received change event for ' +
      header.entityName +
      ' for the ' +
      header.changeType +
      ' operation.'
    );

    if (recordIds.size() == 0) {
      continue;
    }

    // Get ActionCadenceStepTracker records for completed steps where the target is a lead
    List<ActionCadenceStepTracker> stepTrackers = [
      SELECT
        Id,
        ActionCadenceStepId,
        ActionCadenceName,
        TargetId,
        StepType,
        StepTitle
      FROM ActionCadenceStepTracker
      WHERE
        Id IN :recordIds
        AND State = 'Completed'
        AND Target.Type = 'Lead'
        AND StepTitle LIKE 'First Touch%'
    ];

    if (stepTrackers != null && stepTrackers.size() > 0) {
      System.debug('Found ' + stepTrackers.size() + ' step tracker events.');

      List<Lead> leads = new List<Lead>();
      for (ActionCadenceStepTracker stepTracker : stepTrackers) {
        System.debug(
          'Adding the lead ID  ' +
          stepTracker.TargetId +
          ' to Lead list.'
        );
        Lead lead = new Lead(Id = stepTracker.TargetId, Status = 'Contacted');
        leads.add(lead);
      }

      update leads;
    } else {
      System.debug(
        'Did not find any completed First Touch step trackers that are related to leads'
      );
    }
  }
}
