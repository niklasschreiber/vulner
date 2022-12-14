/*
    Copyright (c) 2012,2013,2014 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2012 (2.0)
* @group Recurring Donations
* @description Trigger Handler on Recurring Donations
*/
public class RD_RecurringDonations_TDTM extends TDTM_Runnable {

    /*******************************************************************************************************
    * @description Trigger Handler on Recurring Donations.  Deals with creating/updating/deleting the opps
    * related to the Recurring Donations.
    * @param newlist the list of RD's from trigger new.
    * @param oldlist the list of RD's from trigger old.
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
    * @param objResult the describe for Recurring Donation
    * @return dmlWrapper.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        if (RD2_EnablementService.isRecurringDonations2Enabled) {
            return null;
        }

        map<id, npe03__Recurring_Donation__c> mapIdRDInserts = new map<id, npe03__Recurring_Donation__c>();
        list<npe03__Recurring_Donation__c> listRDUpdates = new list<npe03__Recurring_Donation__c>();

        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
        if (TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.RD)) {
            return null;
        }

        map<string, npe03__Custom_Installment_Settings__c> customInstallmentsMap
            = UTIL_ListCustomSettingsFacade.getMapCustomInstallmentSettings();


        if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            set<Id> setRDId = new set<Id>();
            for (SObject s : newlist) {
                setRDId.add(s.Id);
            }
            newlist = RD_RecurringDonations.requeryListRD(setRDId);
            // since we recreate newlist, we can't assume it is same order as oldlist.
            // luckily we don't need oldlist for the AfterInsert scenario.
            oldlist = null;
        } else if (triggerAction == TDTM_Runnable.Action.BeforeDelete) {
            // newlist will be null.  copy over oldlist, so we can use common loop below.
            newlist = oldlist;
        }

        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
            new RD2_NamingService().autogenerateNames(newlist);
        }

        if (triggerAction != TDTM_Runnable.Action.BeforeInsert && triggerAction != TDTM_Runnable.Action.BeforeUpdate) {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, true);
        }
        DmlWrapper dmlWrapper = new DmlWrapper();

        for (SObject sobj : newlist) {
            npe03__Recurring_Donation__c r = (npe03__Recurring_Donation__c)sobj;

            if (triggerAction == TDTM_Runnable.Action.BeforeInsert || triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
                validateRecurringDonationData(r, rds);

                if (shouldResetAlwaysUseLastDayOfMonth(r, customInstallmentsMap)) {
                    r.Always_Use_Last_Day_Of_Month__c = false;
                }

            } else if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
                mapIdRDInserts.put(r.id, r);

            } else if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                listRDUpdates.add(r);

            }
        }

        if (listRDUpdates.size() > 0) {
            RD_RecurringDonations.handleRecurringDonationUpdate(listRDUpdates, new map<Id,npe03__Recurring_Donation__c>((list<npe03__Recurring_Donation__c>)oldlist), dmlWrapper);
        }

        if (!mapIdRDInserts.isEmpty()) {
            if (mapIdRDInserts.keySet().size() == 1 || system.isFuture() || system.isBatch()) {
                RD_RecurringDonations.insertOppsOnRecurringDonationInsert(mapIdRDInserts.values());
            } else {
                RD_RecurringDonations.insertOppsOnRecurringDonationInsertFuture(mapIdRDInserts.keySet());
            }
        }

        if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            SfdoInstrumentationService.getInstance().log(
                SfdoInstrumentationEnum.Feature.LegacyRecurringDonations,
                SfdoInstrumentationEnum.Component.TriggerAction,
                SfdoInstrumentationEnum.Action.Create,
                newlist.size());
        }

        TDTM_TriggerHandler.processDML(dmlWrapper);
        dmlWrapper = null;
        if (triggerAction != TDTM_Runnable.Action.BeforeInsert && triggerAction != TDTM_Runnable.Action.BeforeUpdate) {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, false);
        }

        dispatchToIntegrationGateway(newlist, oldlist, triggerAction);
        return null;
    }

    /*******************************************************************************************************
    * @description Validates missing data on Recurring Donation
    * @param r the Recurring Donation to validate
    * @param rds Recurring Donation Settings
    ********************************************************************************************************/
    private void validateRecurringDonationData(npe03__Recurring_Donation__c r, npe03__Recurring_Donations_Settings__c rds){
        if (r.npe03__Organization__c == null && r.npe03__Contact__c == null) {
            r.addError(system.label.npe03.RecurringDonationMissingDataError);
        }
        if (r.npe03__Organization__c != null && r.npe03__Contact__c != null) {
            r.addError(system.label.RecurringDonationAccountAndContactError);
        }
        if (r.npe03__Installments__c > rds.npe03__Maximum_Donations__c &&
            (r.npe03__Open_Ended_Status__c != RD_Constants.OPEN_ENDED_STATUS_OPEN &&
                r.npe03__Open_Ended_Status__c != RD_Constants.OPEN_ENDED_STATUS_CLOSED)) {
            r.addError(system.label.npe03.RecurringDonationTooManyInstallmentsError);
        }
    }

    /*******************************************************************************************************
    * @description Returns whether or not to reset Always_Use_Last_Day_Of_Month__c
    * if the installment period is not Monthly, Quarterly, or one of the custom installment periods
    * @param r the Recurring Donation to check
    * @return boolean.
    ********************************************************************************************************/
    private Boolean shouldResetAlwaysUseLastDayOfMonth(npe03__Recurring_Donation__c r, map<string, npe03__Custom_Installment_Settings__c> customInstallmentsMap) {
        return
            r.Always_Use_Last_Day_Of_Month__c == true
            && r.npe03__Installment_Period__c != RD_Constants.INSTALLMENT_PERIOD_MONTHLY
            && r.npe03__Installment_Period__c != RD_Constants.INSTALLMENT_PERIOD_QUARTERLY
            && !customInstallmentsMap.containsKey(r.npe03__Installment_Period__c);
    }

    /*******************************************************************************************************
    * @description Dispatches trigger records to integration gateway
    * @param newlist the list of RD's from trigger new.
    * @param oldlist the list of RD's from trigger old.
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
    ********************************************************************************************************/
    private void dispatchToIntegrationGateway(List<SObject> newlist, List<SObject> oldlist, TDTM_Runnable.Action triggerAction) {
        if (triggerAction == TDTM_Runnable.Action.BeforeDelete) {
            integrationGateway.handleBeforeDelete(oldlist);
        }
    }
}