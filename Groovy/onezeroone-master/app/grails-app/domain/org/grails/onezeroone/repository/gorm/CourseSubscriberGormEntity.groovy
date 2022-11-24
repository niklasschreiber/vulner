package org.grails.onezeroone.repository.gorm

import grails.compiler.GrailsCompileStatic
import org.grails.onezeroone.SubscriptionDay

@GrailsCompileStatic
class CourseSubscriberGormEntity {
    String email
    SubscriptionDay day = SubscriptionDay.ONE

    static constraints = {
        email nullable: false, blank: false, email: true, unique: true
        day nullable: false
    }
    static mapping = {
        table 'coursesubscriber'
    }
}
