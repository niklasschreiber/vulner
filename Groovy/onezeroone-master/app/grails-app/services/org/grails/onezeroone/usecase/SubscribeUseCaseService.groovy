package org.grails.onezeroone.usecase

import grails.validation.ValidationException
import groovy.transform.CompileStatic
import org.grails.onezeroone.CourseSubscriber
import org.grails.onezeroone.CourseSubscriberRepository
import org.grails.onezeroone.SubscriptionDay
import org.grails.onezeroone.entities.CourseSubscriberImpl

@CompileStatic
class SubscribeUseCaseService {
    CourseSubscriberRepository courseSubscriberRepository

    /**
     *
     * @param email
     * @return wether the subscription was successful or not
     */
    boolean subscribe(String email) {
        CourseSubscriber courseSubscriber = new CourseSubscriberImpl(email: email, subscriptionDay: SubscriptionDay.ONE)

        try {
            courseSubscriberRepository.save(courseSubscriber)
        } catch (ValidationException ve) {
            log.warn "There was an error saving the subscriber: ${ve.message}"
            return false
        }
        true
    }
}
