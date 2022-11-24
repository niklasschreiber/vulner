package org.grails.onezeroone.usecase

import grails.gorm.transactions.Rollback
import grails.testing.mixin.integration.Integration
import grails.validation.ValidationException
import org.grails.onezeroone.CourseSubscriberRepository
import org.grails.onezeroone.SubscriptionDay
import org.grails.onezeroone.entities.CourseSubscriberImpl
import spock.lang.Specification

@Rollback
@Integration
class SubscribeUseCaseServiceIntegrationSpec extends Specification {

    SubscribeUseCaseService subscribeUseCaseService
    CourseSubscriberRepository courseSubscriberRepository

    void 'try to subscribe a user twice'() {
        given: 'a user already subscribed'
            def courseSubscriber = new CourseSubscriberImpl(email: email, subscriptionDay: SubscriptionDay.ONE)
            courseSubscriberRepository.save(courseSubscriber)

        when: 'trying to subscribe the same user again'
            subscribeUseCaseService.subscribe(email)

        then: 'it is not subscribed'
            notThrown(ValidationException)
            courseSubscriberRepository.findAllByDay(SubscriptionDay.ONE).size() == 1

        where:
            email = 'john@example.com'
    }
}
