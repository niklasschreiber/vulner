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
* @description NPSP_Contact tests.
*/
@IsTest
private class NPSP_Contact_TEST {

    @IsTest
    static void givenAContactWithAddressInfo_thenHasMailingAddress() {
        //Todo: replace with dummy contact with address
       NPSP_Contact npspContact = new NPSP_Contact(
               new Contact(LastName='Test',MailingCity='testCity',MailingPostalCode='12345')
       );

        System.assertNotEquals(null, npspContact.mailingAddress());
    }

    @IsTest
    static void givenAContactWithAddressInfoAndOldContact_thenHasMailingAddress() {
        //Todo: replace with dummy contact with address
        NPSP_Contact npspContact = new NPSP_Contact(
                new Contact(LastName='Test',MailingCity='testCity',MailingPostalCode='12345'),
                new Contact(LastName='Test2',MailingCity='testCity',MailingPostalCode='12345')
        );

        System.assertNotEquals(null, npspContact.mailingAddress());
    }

    @IsTest
    static void givenAContactWithOnlyPrimaryAddressType_thenAddressNotMarkedChanged() {
        //Todo: replace with dummy contact with address
        NPSP_Contact npspContact = new NPSP_Contact(
                new Contact(LastName='Tester',FirstName='Test',npe01__Primary_Address_Type__c='Home')
        );

        System.assertEquals(false, npspContact.isAddressChanged());
    }

}