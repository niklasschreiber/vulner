/**
 * Copyright (c) 2013, Andrew Fawcett
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the Andrew Fawcett, nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **/

public with sharing class RollupScheduledCalculateController {
  private ApexPages.StandardController standardController;
  public String masterObjectWhere { get; set; }
  public String minute { get; set; }
  public List<SelectOption> minutes { get; set; }
  public List<String> hour { get; set; }
  public List<String> day { get; set; }
  public List<String> month { get; set; }
  public List<String> weekday { get; set; }
  public String uniqueNameForJob { get; set; }

  public RollupScheduledCalculateController(
    ApexPages.StandardController standardController
  ) {
    // Since thie controller is shared between custom object and custom mestadata, determine the applicable unique field
    String uniqueNameField = ((Id) standardController.getId())
        .getSObjectType() == Schema.LookupRollupSummary2__mdt.SObjectType
      ? 'DeveloperName'
      : 'UniqueName__c';

    // Ensure the unique name field is included in the standard controller read fields
    this.standardController = standardController;
    if (!Test.isRunningTest()) {
      // See https://developer.salesforce.com/forums/?id=906F00000008ytQIAQ
      this.standardController.addFields(new List<String>{ uniqueNameField });
    }

    // Calculate unique name
    String rollupUniqueName = (String) standardController.getRecord()
      .get(uniqueNameField);
    uniqueNameForJob =
      'rollup_' +
      (rollupUniqueName == null || rollupUniqueName.equals('')
        ? standardController.getId()
        : rollupUniqueName + ' (' + standardController.getId() + ')');

    // Deprication warning
    if (standardController.getRecord() instanceof LookupRollupSummary__c) {
      ApexPages.addMessage(
        new ApexPages.Message(
          ApexPages.Severity.Warning,
          'Use of the Lookup Rollup Summaries tab is still functional but no longer being enhanced. Consider using the Manage Lookup Rollup Summaries tab.'
        )
      );
    }

    // Page load messages
    ApexPages.addMessage(
      new ApexPages.Message(
        ApexPages.Severity.Info,
        'Clicking the Schedule Full Calculate Job will schedule a recurring background rebuild for this rollup only.'
      )
    );
    ApexPages.addMessage(
      new ApexPages.Message(
        ApexPages.Severity.Info,
        'The default shown below will run the Calculate job at 2am every day.'
      )
    );
    ApexPages.addMessage(
      new ApexPages.Message(
        ApexPages.Severity.Info,
        'Once the job completes any failed rollups will be shown in the Rollup Summary Logs tab.'
      )
    );
    ApexPages.addMessage(
      new ApexPages.Message(
        ApexPages.Severity.Info,
        'The Calculate job can be managed at Setup -> Jobs -> Scheduled Jobs; its name will be ' +
        uniqueNameForJob
      )
    );

    // Minutes
    minutes = new List<SelectOption>();
    for (Integer minute = 0; minute < 60; minute++) {
      minutes.add(new SelectOption(minute + '', minute + ''));
    }

    // Default is 2am everyday
    minute = '0';
    hour = new List<String>{ '2' };
    day = new List<String>{ '*' };
    month = new List<String>{ '*' };
    weekday = new List<String>{ '?' };
  }

  public PageReference scheduleCalculateJob() {
    try {
      // Build the CRON string
      String cronString = String.join(
        new List<String>{
          '0',
          minute,
          String.join(hour, ','),
          String.join(day, ','),
          String.join(month, ','),
          String.join(weekday, ',')
        },
        ' '
      );

      // Kickoff the calculate job for this lookup
      System.schedule(
        uniqueNameForJob,
        cronString,
        new RollupCalculateJobSchedulable(
          standardController.getId(),
          masterObjectWhere
        )
      );
      ApexPages.addMessage(
        new ApexPages.Message(
          ApexPages.Severity.Info,
          'Calculate job scheduled for this lookup.'
        )
      );
    } catch (Exception e) {
      ApexPages.addMessages(e);
      return null;
    }

    // Custom Metadata backed rollup?
    if (standardController.getRecord() instanceof LookupRollupSummary2__mdt) {
      PageReference manageRollupsPage = Page.managelookuprollupsummaries;
      manageRollupsPage.getParameters().put('id', standardController.getId());
      return manageRollupsPage;
    }

    return standardController.view();
  }
}
