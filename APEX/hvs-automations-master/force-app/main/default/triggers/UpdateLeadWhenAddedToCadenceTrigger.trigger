trigger UpdateLeadWhenAddedToCadenceTrigger on ActionCadenceTrackerChangeEvent(
  after insert
) {
  Set<Id> leadIds = new Set<Id>();
  for (ActionCadenceTrackerChangeEvent event : Trigger.New) {
    EventBus.ChangeEventHeader header = event.ChangeEventHeader;
    // If tracker created (lead added to Sales Cadence), change Lead Status to 'Working'
    if (header.changeType == 'CREATE') {
      // The Id may not be a leadId, but in that case it won't be returned by the query
      leadIds.add(event.TargetId);
    }
  }

  List<Lead> leadsToUpdate = [SELECT Status FROM Lead WHERE Id IN :leadIds];
  for (Lead leadToUpdate : leadsToUpdate) {
    if (leadToUpdate.Status != 'Working') {
      leadToUpdate.Status = 'Working';
    }
  }
  update leadsToUpdate;
}
