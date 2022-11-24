package org.grails.onezeroone.usecase

import grails.testing.services.ServiceUnitTest
import org.grails.onezeroone.CourseSubscriberRepository
import org.grails.onezeroone.SubscriptionDay
import spock.lang.Specification

class SubscribeUseCaseServiceSpec extends Specification implements ServiceUnitTest<SubscribeUseCaseService> {

    void 'subscribe a user'() {
        given: 'a repository mocked'
            service.courseSubscriberRepository = Mock(CourseSubscriberRepository)

        when: 'trying to subscribe the user'
            service.subscribe(email)

        then: 'it is subscribed'
            1 * service.courseSubscriberRepository.save(
                { it.email == email && it.subscriptionDay == SubscriptionDay.ONE}
            )

        where:
            email = 'john@example.com'
    }
}
