package org.grails.onezeroone.usecase

import grails.events.annotation.Subscriber
import grails.testing.services.ServiceUnitTest
import org.grails.onezeroone.CourseSubscriber
import org.grails.onezeroone.CourseSubscriberRepository
import org.grails.onezeroone.EmailComposer
import org.grails.onezeroone.EmailImpl
import org.grails.onezeroone.EmailService
import org.grails.onezeroone.SubscriptionDay
import org.grails.onezeroone.entities.CourseSubscriberImpl
import spock.lang.Specification

class DailyEmailUseCaseServiceSpec extends Specification implements ServiceUnitTest<DailyEmailUseCaseService> {

    void 'test the daily send email'() {
        given: 'mocked collaborators'
        service.emailComposer = Mock(EmailComposer) {
            compose(_) >> new EmailImpl()
        }

        List<CourseSubscriber> dayOne = [new CourseSubscriberImpl(email: 'one@email.com')]
        List<CourseSubscriber> dayTwo = [new CourseSubscriberImpl(email: 'two@email.com'), new CourseSubscriberImpl(email: 'three@email.com')]
        service.courseSubscriberRepository = Mock(CourseSubscriberRepository) {
            findAllByDay(SubscriptionDay.ONE) >> dayOne
            findAllByDay(SubscriptionDay.TWO) >> dayTwo
            findAllByDay(_) >> []
        }
        service.emailService = Mock(EmailService)

        when: 'executing the service to send the templates'
        service.sendDailyEmail()

        then:
        2 * service.emailService.send(*_)
        1 * service.emailComposer.compose(SubscriptionDay.ONE)
        1 * service.emailComposer.compose(SubscriptionDay.TWO)
        1 * service.courseSubscriberRepository.moveToDay(dayOne, SubscriptionDay.TWO)
        1 * service.courseSubscriberRepository.moveToDay(dayTwo, SubscriptionDay.THREE)
    }
}
