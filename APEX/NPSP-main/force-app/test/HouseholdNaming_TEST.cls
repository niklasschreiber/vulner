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
* @description Household naming tests in NPSP.
*/
@IsTest
private class HouseholdNaming_TEST {

    @IsTest
    static void formalGreetingIsCorrectForDummyContact() {
        Contacts dummyContact = TEST_ContactBuilder.dummyContacts();
        HouseholdName householdName = new HouseholdName(
                new HouseholdMembers(dummyContact.getRecords()));
        System.assertEquals(
                'test Contact_forTests',
                householdName.asFormalGreeting());
    }

    @IsTest
    static void givenDummyHHNamingSettings_thenFormalGreetingIsCorrectForDummyContact() {
        HH_Households_TEST.setupHouseholdNamingSettings();
        Contacts dummyContact = TEST_ContactBuilder.dummyContacts();
        HouseholdName householdName = new HouseholdName(
                new HouseholdMembers(dummyContact.getRecords()));
        System.assertEquals(
                'Doctor Contact_forTests',
                householdName.asFormalGreeting());
    }

    @IsTest
    static void givenDummyHHNamingSettings_thenFormalGreetingIsCorrectForDummyContact_newTitle
            () {
        HH_Households_TEST.setupHouseholdNamingSettings();
        Contact handyMan = TEST_ContactBuilder.dummyContact();
        handyMan.Title = 'Handy Man';
        Contacts dummyContact = new Contacts(new List<Contact>{handyMan});
        HouseholdName householdName = new HouseholdName(
                new HouseholdMembers(dummyContact.getRecords()));
        System.assertEquals(
                'Handy Man Contact_forTests',
                householdName.asFormalGreeting());
    }

}