package org.grails.onezeroone.plugins.gsp

import grails.testing.mixin.integration.Integration
import org.grails.onezeroone.Email
import org.grails.onezeroone.SubscriptionDay
import spock.lang.Specification

@Integration
class GspComposerServiceIntegrationSpec extends Specification {

    GspComposerService gspComposerService

    void "a html email is build for an specific day"() {
        when:
        Email email = gspComposerService.compose(SubscriptionDay.FIVE)

        then:
        email.body.contains('html')
        email.body.contains('body')

    }
}
