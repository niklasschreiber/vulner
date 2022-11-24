package org.grails.onezeroone.plugins.gsp

import grails.gsp.PageRenderer
import grails.testing.services.ServiceUnitTest
import grails.web.mapping.LinkGenerator
import org.grails.onezeroone.SubscriptionDay
import org.springframework.context.MessageSource
import spock.lang.Specification

class GspComposerServiceSpec extends Specification implements ServiceUnitTest<GspComposerService> {

    Closure doWithConfig() {
        { config ->
            config.onezeroone.email.from = 'EMAIL_FROM'
            config.onezeroone.email.replyTo = 'EMAIL_REPLY_TO'
            config.onezeroone.email.days = ['Day ONE', 'Day TWO', 'Day THREE', 'Day FOUR', 'Day FIVE', 'Day SIX', 'Day SEVEN']
            config.onezeroone.email.titles = ['Grails 101 | Day ONE', 'Grails 101 | Day TWO', 'Grails 101 | Day THREE', 'Grails 101 | Day FOUR', 'Grails 101 | Day FIVE', 'Grails 101 | Day SIX', 'Grails 101 | Day SEVEN']
            config.onezeroone.email.bodys = ['Body ONE', 'Body TWO', 'Body THREE', 'Body FOUR', 'Body FIVE', 'Body SIX', 'Body SEVEN']
            config.onezeroone.email.bodys = ['http://guides.grails.org/dayone', 'http://guides.grails.org/daytwo', 'http://guides.grails.org/daythree', 'http://guides.grails.org/dayfour', 'http://guides.grails.org/dayfive', 'http://guides.grails.org/daysix', 'http://guides.grails.org/dayseven']
        }
    }

    void 'compose an email for one specific day'() {
        given: 'mocks for collaborators'
        service.groovyPageRenderer = Stub(PageRenderer) {
            render(_) >> body
        }

        when: 'trying to render one day email'
        def email = service.compose(SubscriptionDay.FIVE)

        then: 'the email is rendered correctly'
        email != null
        email.subject == subject
        email.body == body
        email.from == 'EMAIL_FROM'
        email.replyTo == 'EMAIL_REPLY_TO'

        where:
        subject = 'Grails 101 | Day FIVE'
        body = 'The email body'
    }
}
