package org.grails.onezeroone.repository.gorm

import groovy.transform.CompileStatic
import org.grails.onezeroone.CourseSubscriber
import org.grails.onezeroone.entities.CourseSubscriberImpl

@CompileStatic
class CourseSubscriberGormEntityUtils {
    static CourseSubscriber of(CourseSubscriberGormEntity gormEntity) {
        new CourseSubscriberImpl(email: gormEntity.email, subscriptionDay: gormEntity.day)
    }
}
