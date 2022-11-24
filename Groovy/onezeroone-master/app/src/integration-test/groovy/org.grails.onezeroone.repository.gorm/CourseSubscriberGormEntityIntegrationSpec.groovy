package org.grails.onezeroone.repository.gorm

import grails.test.hibernate.HibernateSpec
import org.grails.onezeroone.SubscriptionDay
import spock.lang.Unroll

class CourseSubscriberGormEntityIntegrationSpec extends HibernateSpec {

    List<Class> getDomainClasses() {
        [CourseSubscriberGormEntity]
    }

    @Unroll
    void "email '#value' #description"() {
        when:
        def courseSubscriber = new CourseSubscriberGormEntity(email: value)

        then:
        courseSubscriber.validate(['email']) == expected
        courseSubscriber.errors['email']?.code == expectedErrorCode

        where:
        value              | expected | expectedErrorCode
        null               | false    | 'nullable'
        ''                 | false    | 'nullable' // because of conversion empty String to null
        'not-email'        | false    | 'email.invalid'
        'john@example.com' | true     | null
        description = expected ? 'is valid' : 'is not valid'
    }

    @Unroll
    void "day '#value' #description"() {
        when:
        def courseSubscriber = new CourseSubscriberGormEntity(day: value)

        then:
        courseSubscriber.validate(['day']) == expected
        courseSubscriber.errors['day']?.code == expectedErrorCode

        where:
        value               | expected | expectedErrorCode
        null                | false    | 'nullable'
        SubscriptionDay.SIX | true     | null
        description = expected ? 'is valid' : 'is not valid'
    }

    void 'test email unique constraint'() {
        given: 'an existing courseSubscriber'
        def courseSubscriber = new CourseSubscriberGormEntity(email: email, day: SubscriptionDay.FIVE).save()
        assert !courseSubscriber.hasErrors()

        when: 'trying to create another courseSubscriber with the same email'
        def newCourseSubscriber = new CourseSubscriberGormEntity(email: email, day: SubscriptionDay.SEVEN)
        newCourseSubscriber.save()

        then: 'it is not created'
        newCourseSubscriber.hasErrors()
        newCourseSubscriber.errors['email'].code == 'unique'

        and:
        CourseSubscriberGormEntity.count() == 1

        where:
        email = 'john@example.com'

    }
}
