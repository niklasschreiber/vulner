/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Contact and Org Settings class in NPSP.
*/
public with sharing class ContactAndOrgSettings {

    npe01__Contacts_And_Orgs_Settings__c contactsAndOrgsSettings;

    public ContactAndOrgSettings() {
        this(UTIL_CustomSettingsFacade.getContactsSettings());
    }

    @TestVisible
    private ContactAndOrgSettings(npe01__Contacts_And_Orgs_Settings__c settings) {
        this.contactsAndOrgsSettings = settings;
    }

    public Boolean isHouseholdAccountModelEnabled() {
        return contactsAndOrgsSettings.npe01__Account_Processor__c ==
                CAO_Constants.HH_ACCOUNT_PROCESSOR;
    }

    public Boolean isBucketAccountEnabled() {
        return CAO_Constants.isBucketModel();
    }

    public Boolean isOneToOneAccountsEnabled() {
        return CAO_Constants.isOneToOne();
    }

    /*******************************************************************************************************
    * @description utility to return the recordtypeId for a new account, given the account model.
    * @param isHHAccountModel whether we are using the Household Account Model
    * @return Id. recordtype Id to use, or null if none is specified for the account model.
    */
    public static Id rtIdForAccountModel(Boolean isHHAccountModel) {
        npe01__Contacts_And_Orgs_Settings__c contactsSettings =
                UTIL_CustomSettingsFacade.getContactsSettings();
        // check if recordtypes are enabled, and if it matches the existing setting
        // we go thru describe to validate that it is a valid recordType ID.
        Id individualRecordTypeId = isHHAccountModel
                ? contactsSettings.npe01__HH_Account_RecordTypeID__c
                : contactsSettings.npe01__One_to_One_RecordTypeID__c;
        if (individualRecordTypeId != null) {
            Schema.RecordTypeInfo recordTypeInfo =
                    UTIL_Describe.getObjectDescribe(Account.SObjectType)
                            .getRecordTypeInfosById()
                            .get(individualRecordTypeId);
            return recordTypeInfo == null
                    ? null
                    : recordTypeInfo.getRecordTypeId();
        }

        return null;
    }
}