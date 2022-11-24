package org.grails.onezeroone.entities

import groovy.transform.CompileStatic
import groovy.transform.TupleConstructor
import org.grails.onezeroone.CourseSubscriber
import org.grails.onezeroone.SubscriptionDay

@CompileStatic
@TupleConstructor
class CourseSubscriberImpl implements CourseSubscriber {
    String email
    SubscriptionDay subscriptionDay
}
