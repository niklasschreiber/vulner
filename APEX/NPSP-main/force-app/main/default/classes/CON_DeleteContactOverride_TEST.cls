/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2015
* @group Contacts
* @group-content ../../ApexDocContent/Contacts.htm
* @description Test class for Contact delete override.
*/
@isTest
private class CON_DeleteContactOverride_TEST {
    /** @description Contact home page. */
    private static final String CONTACT_HOME = '/003/o';
    /** @description LEx navigation value to go back. */
    private static final String LEX_BACK = 'back';
    /** @description LEx navigation value to go to Contact Home. */
    private static final String LEX_HOME = 'home';
    /** @description RetURL parameter. */
    private static final String PARAM_RETURL = 'retURL';
    /** @description Cancel RetURL parameter. */
    private static final String PARAM_RETURL_FAIL = 'failRetURL';

    /*******************************************************************************************************
    * @description Deletes a contact not alone in their household, verifies household is not deleted.
    */
    @isTest static void deleteWithOtherMembers() {
        Contact con = new Contact(LastName = 'foo');
        insert con;

        list<Contact> queryCon = getContactList(con.Id);
        system.assertNotEquals(null, queryCon[0].AccountId, 'The contact should have an auto-build household.');
        system.assert(queryCon[0].Account.npe01__SYSTEMIsIndividual__c, 'The household should have the system flag set.');

        Contact con2 = new Contact(LastName = 'foo', FirstName = 'Mr.', AccountId = querycon[0].AccountId);
        insert con2;

        test.startTest();
        CON_DeleteContactOverride_CTRL ctrl = new CON_DeleteContactOverride_CTRL(new ApexPages.StandardController(con));
        ctrl.processDelete();
        test.stopTest();

        list<account> queryAcc = getAccountListAllRows(queryCon[0].AccountId);

        system.assertEquals(1, queryAcc.size(), 'There should be one account.');
        system.assertEquals(false, queryacc[0].isDeleted, 'Deleted flag should not be set.');

        queryCon = getContactListAllRows(con.id);

        system.assertEquals(1, queryCon.size(), 'There should be one deleted contact.');
        system.assert(queryCon[0].isDeleted, 'Deleted flag should be set.');

    }

    /*******************************************************************************************************
    * @description Deletes contact in the 1:1 account model. Verifies that contact is marked is in the
    * recycle bin and not hard deleted.
    */
    @isTest static void deleteOneToOne() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR
            )
        );
        Contact con = new Contact(LastName = 'foo');
        insert con;

        list<Contact> queryCon = getContactList(con.Id);
        system.assertNotEquals(null, queryCon[0].AccountId, 'The contact should have an auto-created household.');
        system.assert(queryCon[0].Account.npe01__SYSTEMIsIndividual__c, 'The household should have the system flag set.');

        test.startTest();
        CON_DeleteContactOverride_CTRL ctrl = new CON_DeleteContactOverride_CTRL(new ApexPages.StandardController(con));
        ctrl.processDelete();
        ctrl.deleteAccount();
        test.stopTest();

        list<account> queryAcc = getAccountListAllRows(queryCon[0].AccountId);

        system.assertEquals(1, queryAcc.size(), 'There should be one deleted account.');
        system.assert(queryacc[0].isDeleted, 'Deleted flag should be set.');

        queryCon = getContactListAllRows(con.id);

        system.assertEquals(1, queryCon.size(), 'There should be one deleted contact.');
        system.assert(queryCon[0].isDeleted, 'Deleted flag should be set.');
    }

    /*******************************************************************************************************
    * @description Deletes contact in the household account model that is alone in their household
    * account. Verifies that contact is in the recycle bin and not hard deleted.
    */
    @isTest static void deleteAloneInHousehold() {
        Contact con = new Contact(LastName = 'foo');
        insert con;

        list<Contact> queryCon = getContactList(con.Id);
        system.assertNotEquals(null, queryCon[0].AccountId, 'The contact should have an auto-created household.');
        system.assert(queryCon[0].Account.npe01__SYSTEMIsIndividual__c, 'The household should have the system flag set.');

        test.startTest();
        CON_DeleteContactOverride_CTRL ctrl = new CON_DeleteContactOverride_CTRL(new ApexPages.StandardController(con));
        ctrl.processDelete();
        ctrl.deleteAccount();
        test.stopTest();

        list<account> queryAcc = getAccountListAllRows(queryCon[0].AccountId);

        system.assertEquals(1, queryAcc.size(), 'There should be one deleted account.');
        system.assert(queryacc[0].isDeleted, 'Deleted flag should be set.');

        queryCon = getContactListAllRows(con.Id);

        system.assertEquals(1, queryCon.size(), 'There should be one deleted contact.');
        system.assert(queryCon[0].isDeleted, 'Deleted flag should be set.');

    }

    /*********************************************************************************************************
    @description
        Test Contact Delete page navigation parameters are set based on passed in Apex page parameters
    verify:
        The following properties are set:
        - Property to indicate if LEx or Classic is used,
        - Return URL
        - Fail (or Cancel) URL
    **********************************************************************************************************/
    private static testMethod void testNavigationParametersAreSetInConstructor() {
        Contact con = new Contact(LastName = 'foo');
        insert con;

        Test.setCurrentPage(Page.CON_DeleteContactOverride);

        String retUrl = 'foo/o';
        ApexPages.currentPage().getParameters().put(PARAM_RETURL, retUrl);

        String failRetUrl = 'bar/o';
        ApexPages.currentPage().getParameters().put(PARAM_RETURL_FAIL, failRetUrl);

        CON_DeleteContactOverride_CTRL ctrl = new CON_DeleteContactOverride_CTRL(new ApexPages.StandardController(con));

        System.assertEquals(retUrl, ctrl.retUrl, 'Return URL should be set');
        System.assertEquals(failRetUrl, ctrl.failRetUrl, 'Cancel URL should be set');
    }

    /*********************************************************************************************************
    @description
        Test RetURL is set to Contact Home page if it is not provided in the page params
    verify:
        Return URL property is set to Contact Home
    **********************************************************************************************************/
    private static testMethod void testRetUrlIsContactHomeIfNotProvided() {
        Contact con = new Contact(LastName = 'foo');
        insert con;

        CON_DeleteContactOverride_CTRL ctrl = new CON_DeleteContactOverride_CTRL(new ApexPages.StandardController(con));

        Map<String, String> params = new Map<String, String>{
            PARAM_RETURL_FAIL => 'foo/o'
        };
        ctrl.setNavigationParams(params);

        System.assertEquals(CONTACT_HOME, ctrl.retUrl, 'Return URL should be Contact Home page');
        System.assertEquals(params.get(PARAM_RETURL_FAIL), ctrl.failRetUrl, 'Cancel URL should be set');
    }

    /*********************************************************************************************************
    @description
        Test RetURL
    verify:
        Controller retUrl is retURL page param for Classic.
    **********************************************************************************************************/
    private static testMethod void testRetUrlForClassic() {
        Contact con = new Contact(LastName = 'foo');
        insert con;

        CON_DeleteContactOverride_CTRL ctrl = new CON_DeleteContactOverride_CTRL(new ApexPages.StandardController(con));

        Map<String, String> params = new Map<String, String>{
            PARAM_RETURL => 'foo/o'
        };

        ctrl.lexOrSF1User = false;
        ctrl.setNavigationParams(params);
        System.assertEquals(params.get(PARAM_RETURL), ctrl.retUrl, 'Return URL should be retURL page param for Classic');
    }

    /*********************************************************************************************************
    @description
        Test onCancel navigation
    verify:
        Cancel action navigates to failRetURL or retURL for Classic.
        Cancel action sets sfoceNav to "back" when in LEx.
    **********************************************************************************************************/
    private static testMethod void testOnCancel() {
        Contact con = new Contact(LastName = 'foo');
        insert con;

        CON_DeleteContactOverride_CTRL ctrl = new CON_DeleteContactOverride_CTRL(new ApexPages.StandardController(con));

        Map<String, String> params = new Map<String, String>{
            PARAM_RETURL => '006/o',
            PARAM_RETURL_FAIL => '001/o'
        };

        ctrl.lexOrSF1User = false;
        ctrl.setNavigationParams(params);
        PageReference cancelPage = ctrl.onCancel();
        System.assertNotEquals(null, cancelPage, 'Cancel page should be returned for Classic');
        System.assertEquals(params.get(PARAM_RETURL_FAIL), cancelPage.getUrl(), 'Cancel page should be navigate failRetURL for Classic');
        System.assertEquals(null, ctrl.sforceNav, 'Controller sforceNav should be null for Classic');

        params.remove(PARAM_RETURL_FAIL);
        ctrl.setNavigationParams(params);
        cancelPage = ctrl.onCancel();
        System.assertNotEquals(null, cancelPage, 'Cancel page should be returned for Classic');
        System.assertEquals(params.get(PARAM_RETURL), cancelPage.getUrl(), 'Cancel page should be navigate retURL for Classic');
        System.assert(cancelPage.getRedirect(), 'The Cancel page should redirect');

        ctrl.lexOrSF1User = true;
        ctrl.setNavigationParams(params);
        cancelPage = ctrl.onCancel();
        System.assertEquals(null, cancelPage, 'Cancel page should be null for LEx');
        System.assertEquals(LEX_BACK, ctrl.sforceNav, 'Controller sforceNav should be "back" for LEx');
    }

    /*********************************************************************************************************
    @description
        Test Contact deletion and leaving empty Account
    verify:
        The Contact is deleted.
        The Account is not deleted.
    **********************************************************************************************************/
    private static testMethod void testDeleteContactAndLeaveEmptyAccount() {
        Contact con = new Contact(LastName = 'foo');
        insert con;

        CON_DeleteContactOverride_CTRL ctrl = new CON_DeleteContactOverride_CTRL(new ApexPages.StandardController(con));
        ctrl.preProcessDelete(); // constructor logic has been minimized, so need to call what used to be in constructor...

        con = getContactList(con.Id)[0];
        System.assertNotEquals(null, con.AccountId, 'The Contact should have an auto-created household.');

        ctrl.lexOrSF1User = true;
        System.assertEquals(null, ctrl.sforceNav, 'Controller sforceNav should be null before an action');

        PageReference retPage = ctrl.deleteContactOnly();
        System.assertEquals(null, retPage, 'Return page should be null for LEx');
        System.assertEquals(LEX_HOME, ctrl.sforceNav, 'Controller sforceNav should be Contact Home in LEX');

        List<Account> accounts = getAccountListAllRows(con.AccountId);
        System.assertEquals(1, accounts.size(), 'The Account should be retrieved from DB.');
        System.assert(!accounts[0].isDeleted, 'The Account should not be deleted');

        con = getContactListAllRows(con.id)[0];
        System.assertNotEquals(null, con, 'The Contact should be retrieved from DB.');
        System.assert(con.isDeleted, 'The Contact should be deleted');
    }

    /*********************************************************************************************************
    * @description Attempts to delete contact with closed/won and org opps, verifies correct exception is thrown.
    */
    static testMethod void testContactDeleteExceptionWithOverride() {
        //use a non-system account for the contact's account, so that the delete override doesn't redirect us to delete the account
        Account account = new Account(Name = 'TEST_ACCOUNT');
        insert account;

        Contact contact = new Contact(LastName = 'TEST_CONTACT', AccountId = account.Id);
        insert contact;

        npe03__Recurring_Donation__c recurringDonation = getRecurringDonationBuilder()
            .withContact(contact.Id)
            .build();
        insert recurringDonation;

        List<npe4__Relationship__c> relationships = CDL_CascadeDeleteLookups_TEST.buildRelationships(new List<Contact>{
            contact
        });
        insert relationships;

        //org account for opportunity attribution
        Account orgAccount = new Account(Name = 'TEST_ORG_ACCOUNT');
        insert orgAccount;

        Opportunity closedWonOpp = new Opportunity(
            Amount = 8,
            Name = 'TEST_OPPORTUNITY1',
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = System.today(),
            Primary_Contact__c = contact.Id
        );
        insert closedWonOpp;

        Opportunity orgOpportunity = new Opportunity(
            Amount = 8,
            AccountId = orgAccount.Id,
            Name = 'TEST_OPPORTUNITY2',
            StageName = UTIL_UnitTestData_TEST.getClosedLostStage(),
            CloseDate = System.today(),
            Primary_Contact__c = contact.Id
        );
        insert orgOpportunity;

        Case contactCase = new Case(
            AccountId = account.Id,
            ContactId = contact.Id
        );
        insert contactCase;

        Test.setCurrentPage(Page.CON_DeleteContactOverride);
        ApexPages.currentPage().getParameters().put('Id', contact.Id);
        CON_DeleteContactOverride_CTRL ctrl = new CON_DeleteContactOverride_CTRL(new ApexPages.StandardController(contact));

        Test.startTest();
        ctrl.processDelete();
        Test.stopTest();

        System.assert(ApexPages.hasMessages(), 'An exception should be caught and added to page messages.');
        System.assert(ApexPages.getMessages()[0].getDetail().contains(closedWonOpp.Id), 'Exception message should contain the closed won opportunity Id.');
        System.assert(ApexPages.getMessages()[0].getDetail().contains(Label.ClosedWonOpportunities), 'Exception message should mention Closed Won Opportunities.');
        System.assert(ApexPages.getMessages()[0].getDetail().contains(orgOpportunity.Id), 'Exception message should contain the org opportunity Id.');
        System.assert(ApexPages.getMessages()[0].getDetail().contains(Label.OrganizationalOpportunities), 'Exception message should mention Organizational Opportunities.');
        System.assert(ApexPages.getMessages()[0].getDetail().contains(contactCase.Id), 'Exception message should contain the Case Id.');
        System.assert(ApexPages.getMessages()[0].getDetail().contains(Case.SObjectType.getDescribe().getLabelPlural()), 'Exception message should mention Cases.');

        List<Error__c> errors = CDL_CascadeDeleteLookups_TEST.getErrors();
        System.assertEquals(0, errors.size(), errors);

        List<npe03__Recurring_Donation__c> deletedRecurringDonations = CDL_CascadeDeleteLookups_TEST.getDeletedRecurringDonations();
        List<npe4__Relationship__c> deletedRelationships = CDL_CascadeDeleteLookups_TEST.getDeletedRelationships();

        System.assertEquals(0, deletedRecurringDonations.size(), 'The Contact Recurring Donation should NOT be cascade deleted because there is a validation error');
        System.assertEquals(0, deletedRelationships.size(), 'Contact Relationships should NOT be deleted because there is an exception.');
    }

    /*********************************************************************************************************
    * @description Attempts to delete contact with Recurring Donation, Opportunities and Relationships,
    * verifies Recurring Donation is deleted.
    */
    static testMethod void testContactDeleteWithOverride() {
        //use a non-system account for the contact's account, so that the delete override doesn't redirect us to delete the account
        Account account = new Account(Name = 'TEST_ACCOUNT');
        insert account;

        Contact contact = new Contact(LastName = 'TEST_CONTACT', AccountId = account.Id);
        insert contact;

        List<npe4__Relationship__c> relationships = CDL_CascadeDeleteLookups_TEST.buildRelationships(new List<Contact>{
            contact
        });
        insert relationships;

        TDTM_TriggerHandler.disableTDTM = true;

        npe03__Recurring_Donation__c recurringDonation = getRecurringDonationBuilder()
            .withContact(contact.Id)
            .build();
        insert recurringDonation;

        Opportunity orgOpportunity = new Opportunity(
            Amount = 8,
            AccountId = account.Id,
            Name = 'TEST_OPPORTUNITY',
            StageName = UTIL_UnitTestData_TEST.getClosedLostStage(),
            CloseDate = System.today(),
            Primary_Contact__c = contact.Id
        );
        insert orgOpportunity;

        TDTM_TriggerHandler.disableTDTM = false;

        Test.setCurrentPage(Page.CON_DeleteContactOverride);
        ApexPages.currentPage().getParameters().put('Id', contact.Id);
        CON_DeleteContactOverride_CTRL ctrl = new CON_DeleteContactOverride_CTRL(new ApexPages.StandardController(contact));

        Test.startTest();
        ctrl.processDelete();
        Test.stopTest();

        List<Error__c> errors = CDL_CascadeDeleteLookups_TEST.getErrors();
        System.assertEquals(0, errors.size(), errors);

        List<npe03__Recurring_Donation__c> deletedRecurringDonations = CDL_CascadeDeleteLookups_TEST.getDeletedRecurringDonations();
        List<npe4__Relationship__c> deletedRelationships = CDL_CascadeDeleteLookups_TEST.getDeletedRelationships();
        List<Opportunity> deletedRDOpportunities = CDL_CascadeDeleteLookups_TEST.getDeletedOpportunities();

        System.assertEquals(1, deletedRecurringDonations.size(), 'The Contact Recurring Donation should be cascade deleted when Contact is deleted.');
        System.assertEquals(relationships.size() * 2, deletedRelationships.size(), 'Contact relationships should be deleted when the Contacts are deleted.');
        System.assertEquals(1, deletedRDOpportunities.size(), 'The Opportunities should be cascade deleted.');
    }

    /*********************************************************************************************************
    * @description Attempts to delete Account with closed/won opp and case, verifies correct exception is thrown.
    */
    static testMethod void testAccountDeleteExceptionWithOverride() {
        //use a non-system account for the contact's account, so that the delete override doesn't redirect us to delete the account
        Account account = new Account(
            Name = 'TESTACCOUNT',
            npe01__SYSTEMIsIndividual__c = true
        );
        insert account;

        Contact contact1 = new Contact(
            LastName = 'TESTCONTACT1',
            AccountId = account.Id
        );
        Contact contact2 = new Contact(
            LastName = 'TESTCONTACT2',
            AccountId = account.Id
        );
        insert new List<Contact>{
            contact1, contact2
        };

        Opportunity closedWonOpp = new Opportunity(
            Amount = 8,
            AccountId = account.Id,
            Name = 'TEST_OPP',
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = System.today()
        );
        insert closedWonOpp;

        Case accountCase = new Case(
            AccountId = account.Id
        );
        insert accountCase;

        List<npe03__Recurring_Donation__c> recurringDonations = new List<npe03__Recurring_Donation__c>{
            getRecurringDonationBuilder()
                .withContact(contact1.Id)
                .build(),
            getRecurringDonationBuilder()
                .withAccount(account.Id)
                .build()
        };
        insert recurringDonations;

        General_Accounting_Unit__c generalAccountingUnit = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert generalAccountingUnit;
        List<Opportunity> opportunities = CDL_CascadeDeleteLookups_TEST.buildOpportunities(new List<Account>{
            account
        });
        insert opportunities;

        List<Allocation__c> allocations = new List<Allocation__c>();
        allocations.addAll(CDL_CascadeDeleteLookups_TEST.buildRDAllocations(generalAccountingUnit, recurringDonations));
        allocations.addAll(CDL_CascadeDeleteLookups_TEST.buildOpportunityAllocations(generalAccountingUnit, opportunities));
        insert allocations;

        List<npe4__Relationship__c> relationships = CDL_CascadeDeleteLookups_TEST.buildRelationships(new List<Contact>{
            contact1
        });
        insert relationships;

        Test.setCurrentPage(Page.CON_DeleteContactOverride);
        ApexPages.currentPage().getParameters().put('Id', contact1.Id);
        CON_DeleteContactOverride_CTRL ctrl = new CON_DeleteContactOverride_CTRL(new ApexPages.StandardController(contact1));
        ctrl.preProcessDelete(); // constructor logic has been minimized, so need to call what used to be in constructor...

        Test.startTest();
        ctrl.deleteAccount();
        Test.stopTest();

        System.assert(ApexPages.hasMessages(), 'An exception should be caught and added to page messages.');
        System.assert(String.valueOf(ApexPages.getMessages()).contains(closedWonOpp.Id), 'Exception message should contain the closed won opportunity Id.');
        System.assert(String.valueOf(ApexPages.getMessages()).contains(Label.ClosedWonOpportunities), 'Exception message should mention Closed Won Opportunities.');
        System.assert(String.valueOf(ApexPages.getMessages()).contains(accountCase.Id), 'Exception message should contain the Case Id.');
        System.assert(String.valueOf(ApexPages.getMessages()).contains(Case.SObjectType.getDescribe().getLabelPlural()), 'Exception message should mention Cases.');

        List<Error__c> errors = CDL_CascadeDeleteLookups_TEST.getErrors();
        System.assertEquals(0, errors.size(), errors);

        List<npe03__Recurring_Donation__c> deletedRecurringDonations = CDL_CascadeDeleteLookups_TEST.getDeletedRecurringDonations();
        System.assertEquals(0, deletedRecurringDonations.size(), 'Contact and Account Recurring Donation should NOT be cascade deleted.');

        List<Allocation__c> deletedAllocations = CDL_CascadeDeleteLookups_TEST.getDeletedAllocations();
        System.assertEquals(0, deletedAllocations.size(), 'Allocation should NOT be cascade deleted when recurring donations');

        List<npe4__Relationship__c> deletedRelationships = CDL_CascadeDeleteLookups_TEST.getDeletedRelationships();
        System.assertEquals(0, deletedRelationships.size(), 'The relationships created for Contact should NOT be deleted');
    }

    /*********************************************************************************************************
    * @description Verifies that minimum access flag is set when contact delete is not allowed.
    */
    @IsTest
    private static void shouldPreventContactDeletionWithoutContactDeleteAccess() {
        Account acct = new Account(Id = UTIL_UnitTestData_TEST.mockId(Account.SObjectType));
        Contact con = new Contact(Id = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType), AccountId = acct.Id);

        Test.setCurrentPage(Page.CON_DeleteContactOverride);
        ApexPages.currentPage().getParameters().put('Id', con.Id);
        CON_DeleteContactOverride_CTRL ctrl = new CON_DeleteContactOverride_CTRL(new ApexPages.StandardController(con));

        Boolean hasContactAccess = false;
        Boolean hasAccountAccess = true;

        CON_DeleteContactOverrideStub contactDeleteStub =
            new CON_DeleteContactOverrideStub(
                con.Id, hasContactAccess, acct.Id, hasAccountAccess, true
            );
        ctrl.contactOverrideSelector =
            (CON_DeleteContactOverrideSelector) Test.createStub(contactDeleteStub.classType, contactDeleteStub);

        ctrl.processDelete();

        System.assertEquals(false, ctrl.hasMinimumAccess, 'Controller should have hasMinimumAccess set to false.');
    }

    /*********************************************************************************************************
    * @description Verifies that missing account delete permission is identified.
    */
    @IsTest
    private static void shouldConfirmDeleteContactWithoutExposingAccountInfo() {
        Account acct = new Account(Id = UTIL_UnitTestData_TEST.mockId(Account.SObjectType));
        Contact con = new Contact(Id = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType), AccountId = acct.Id);

        Test.setCurrentPage(Page.CON_DeleteContactOverride);
        ApexPages.currentPage().getParameters().put('Id', con.Id);
        CON_DeleteContactOverride_CTRL ctrl = new CON_DeleteContactOverride_CTRL(new ApexPages.StandardController(con));

        Boolean hasContactAccess = true;
        Boolean hasAccountAccess = false;

        CON_DeleteContactOverrideStub contactDeleteStub =
            new CON_DeleteContactOverrideStub(
                con.Id, hasContactAccess, acct.Id, hasAccountAccess, true
            );
        ctrl.contactOverrideSelector =
            (CON_DeleteContactOverrideSelector) Test.createStub(contactDeleteStub.classType, contactDeleteStub);

        ctrl.processDelete();

        System.assertEquals(true,
            String.valueOf(ApexPages.getMessages()[0].getDetail()).contains(contactDeleteStub.CONTACT_NAME),
            'Message should contain contact name.');
        System.assertEquals(false,
            String.valueOf(ApexPages.getMessages()[0].getDetail()).contains(contactDeleteStub.ACCOUNT_NAME),
            'Message should not contain account name.');
    }

    /*********************************************************************************************************
    * @description Verifies that the presence of account delete permission is identified.
    */
    @IsTest
    private static void shouldConfirmDeleteContactAndExposeAccountInfo() {
        Account acct = new Account(Id = UTIL_UnitTestData_TEST.mockId(Account.SObjectType));
        Contact con = new Contact(Id = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType), AccountId = acct.Id);

        Test.setCurrentPage(Page.CON_DeleteContactOverride);
        ApexPages.currentPage().getParameters().put('Id', con.Id);
        CON_DeleteContactOverride_CTRL ctrl = new CON_DeleteContactOverride_CTRL(new ApexPages.StandardController(con));

        Boolean hasContactAccess = true;
        Boolean hasAccountAccess = true;

        CON_DeleteContactOverrideStub contactDeleteStub =
            new CON_DeleteContactOverrideStub(
                con.Id, hasContactAccess, acct.Id, hasAccountAccess, true
            );
        ctrl.contactOverrideSelector =
            (CON_DeleteContactOverrideSelector) Test.createStub(contactDeleteStub.classType, contactDeleteStub);

        ctrl.processDelete();

        System.assertEquals(true,
            String.valueOf(ApexPages.getMessages()[0].getDetail()).contains(contactDeleteStub.CONTACT_NAME),
            'Message should contain contact name.');
        System.assertEquals(true,
            String.valueOf(ApexPages.getMessages()[0].getDetail()).contains(contactDeleteStub.ACCOUNT_NAME),
            'Message should contain account name.');
    }

    // Helpers
    ///////////

    /*********************************************************************************************************
    * @description Get Contact
    * @param contactId A Contact Id
    * @return List<Contact> Return the Contact in the List
    **********************************************************************************************************/
    private static List<Contact> getContactList(Id contactId) {
        return [
            SELECT Id, AccountId, Account.npe01__SYSTEMIsIndividual__c
            FROM Contact
            WHERE Id = :contactId
        ];
    }

    /*********************************************************************************************************
    * @description Get Contact regardless if it is deleted
    * @param contactId A Contact Id
    * @return List<Contact> Return the Contact in the List
    **********************************************************************************************************/
    private static List<Contact> getContactListAllRows(Id contactId) {
        return [
            SELECT Id, isDeleted
            FROM Contact
            WHERE Id = :contactId
            ALL ROWS
        ];
    }

    /*********************************************************************************************************
    * @description Get Account
    * @param accountId An Account Id
    * @return List<Account> Return the Account in the List
    **********************************************************************************************************/
    private static List<Account> getAccountListAllRows(Id accountId) {
        return [
            SELECT Id, isDeleted
            FROM Account
            WHERE Id = :accountId
            ALL ROWS
        ];
    }

    /***
    * @description Builds Recurring Donation record with default values
    * @return npe03__Recurring_Donation__c
    */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder() {
        return new TEST_RecurringDonationBuilder()
            .withAmount(2)
            .withPlannedInstallments(2)
            .withInstallmentPeriodYearly()
            .withDateEstablished()
            .withScheduleTypeMultiplyValue();
    }

    private class CON_DeleteContactOverrideStub implements System.StubProvider {

        public Type classType = CON_DeleteContactOverrideSelector.class;

        private Id contactId;
        private Boolean canDeleteContact;
        private Id accountId;
        private Boolean canDeleteAccount;
        private Boolean isAccountWithSingleContact;

        final public String CONTACT_NAME = 'Test Contact';
        final public String ACCOUNT_NAME = 'Test Account';

        CON_DeleteContactOverrideStub(Id contactId, Boolean canDeleteContact, Id accountId, Boolean canDeleteAccount,
            Boolean isHouseholdWithSingleContact) {
            this.contactId = contactId;
            this.canDeleteContact = canDeleteContact;
            this.accountId = accountId;
            this.canDeleteAccount = canDeleteAccount;
            this.isAccountWithSingleContact = isHouseholdWithSingleContact;
        }

        private Contact queryContact() {
            Contact contactDetails = (Contact) JSON.deserialize('{' +
                '"Id": "' + this.contactId + '", ' +
                '"Name": "' + CONTACT_NAME + '", ' +
                '"FirstName": "' + 'Test' + '", ' +
                '"LastName": "' + 'Contact' + '", ' +
                '"AccountId": "' + this.accountId + '", ' +
                '"Account": {"Name": "' + ACCOUNT_NAME + '", ' +
                '"npe01__SYSTEMIsIndividual__c": true}' +
                '}', Contact.class);
            return contactDetails;
        }

        private UserRecordAccess queryDeleteRecordAccess(String recordId) {
            UserRecordAccess accessRecord;

            if (recordId == contactId) {
                accessRecord = (UserRecordAccess) JSON.deserialize(
                    '{"RecordId": "' + this.contactId + '", ' +
                    '"HasDeleteAccess": "' + this.canDeleteContact + '"}', UserRecordAccess.class);

            } else {
                accessRecord = (UserRecordAccess) JSON.deserialize(
                    '{"RecordId": "' + this.accountId + '", ' +
                        '"HasDeleteAccess": "' + this.canDeleteAccount + '"}', UserRecordAccess.class);
            }

            return accessRecord;
        }

        public Object handleMethodCall(
            Object stubbedObject, String stubbedMethodName, Type returnType,
            List<Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs
        ) {
            switch on stubbedMethodName {
                when 'queryContact' {
                    return this.queryContact();
                }
                when 'isAccountWithSingleContact' {
                    return this.isAccountWithSingleContact;
                }
                when 'queryDeleteRecordAccess' {
                    return queryDeleteRecordAccess((Id) listOfArgs[0]);
                }
            }
            return null;
        }
    }
}