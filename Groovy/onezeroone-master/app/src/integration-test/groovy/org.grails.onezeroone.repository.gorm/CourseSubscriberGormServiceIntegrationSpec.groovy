package org.grails.onezeroone.repository.gorm

import grails.gorm.transactions.Rollback
import grails.testing.mixin.integration.Integration
import org.grails.onezeroone.CourseSubscriber
import org.grails.onezeroone.SubscriptionDay
import org.grails.onezeroone.entities.CourseSubscriberImpl
import spock.lang.Specification

@Integration
@Rollback
class CourseSubscriberGormServiceIntegrationSpec extends Specification {

    CourseSubscriberGormService courseSubscriberGormService
    CourseSubscriberDataService courseSubscriberDataService

    void 'test find all courseSubscribers by day'() {
        given: 'a few courseSubscribers'
        [dayOne, dayTwo, dayThree, dayFour, daySix, dayFinished].flatten().each { Map m ->
            courseSubscriberDataService.save(m.email as String, m.day as SubscriptionDay)
        }

        when: 'finding all by day ONE'
        List<CourseSubscriber> result = courseSubscriberGormService.findAllByDay(SubscriptionDay.ONE)

        then:
        result != null
        result.size() == dayOne.size()
        result.email == dayOne*.email
        result.subscriptionDay.every { it == SubscriptionDay.ONE }

        when: 'finding all by day TWO'
        result = courseSubscriberGormService.findAllByDay(SubscriptionDay.TWO)

        then:
        result != null
        result.size() == dayTwo.size()
        result.email == dayTwo*.email
        result.subscriptionDay.every { it == SubscriptionDay.TWO }


        where:
        dayOne = [[email: 'user1A@example.com', day: SubscriptionDay.ONE], [email: 'user1B@example.com', day: SubscriptionDay.ONE]]
        dayTwo = [[email: 'user2A@example.com', day: SubscriptionDay.TWO]]
        dayThree = [[email: 'user3A@example.com', day: SubscriptionDay.THREE]]
        dayFour = [[email: 'user4A@example.com', day: SubscriptionDay.FOUR]]
        daySix = [[email: 'user5A@example.com', day: SubscriptionDay.SIX]]
        dayFinished = [[email: 'finished@example.com', day: SubscriptionDay.FINISHED]]
    }

    void 'move a list of courseSubscribers to another day'() {
        given: 'a few courseSubscribers'
        Closure save = { String  email, SubscriptionDay day ->
            CourseSubscriberGormEntityUtils.of(courseSubscriberDataService.save(email, day))
        }

        CourseSubscriber day1A = save('user1A@example.com', SubscriptionDay.ONE)
        CourseSubscriber day1B = save('user1B@example.com', SubscriptionDay.ONE)
        save('user2A@example.com', SubscriptionDay.TWO)
        save('user3A@example.com', SubscriptionDay.THREE)

        when: 'moving the courses from day ONE to day TWO'
        courseSubscriberGormService.moveToDay([day1A, day1B], SubscriptionDay.TWO)

        then:
        courseSubscriberGormService.findAllByDay(SubscriptionDay.TWO).size() == 3
    }

    void 'persist a courseSubscriber'() {
        given: 'a courseSubscriber'
        CourseSubscriber courseSubscriber = new CourseSubscriberImpl(email, subscriptionDay)

        when: 'persisting it'
        courseSubscriberGormService.save(courseSubscriber)

        then: 'it is persisted'
        courseSubscriberGormService.findAllByDay(subscriptionDay).size() == old(courseSubscriberGormService.findAllByDay(subscriptionDay)).size() + 1
        courseSubscriberGormService.findAllByDay(subscriptionDay).first().email == email
        courseSubscriberGormService.findAllByDay(subscriptionDay).first().subscriptionDay == subscriptionDay

        where:
        email = 'user1@example.com'
        subscriptionDay = SubscriptionDay.FIVE
    }
}
