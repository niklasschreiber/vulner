package org.grails.onezeroone.repository.gorm

import org.grails.onezeroone.SubscriptionDay
import spock.lang.Specification

class CourseSubscriberGormEntityUtilsSpec extends Specification {

    void 'convert a courseSubscriberGorm to a courseSubscriber entity'() {
        given: 'a courseSubscriberGorm'
        def courseSubscriberGorm = new CourseSubscriberGormEntity(email: email, day: day)

        when: 'converting it to a courseSubscriber entity'
        def courseSubscriber = CourseSubscriberGormEntityUtils.of(courseSubscriberGorm)

        then:
        courseSubscriber != null
        courseSubscriber.email == email
        courseSubscriber.subscriptionDay == day

        where:
        email = 'john@example.com'
        day = SubscriptionDay.FOUR
    }
}
