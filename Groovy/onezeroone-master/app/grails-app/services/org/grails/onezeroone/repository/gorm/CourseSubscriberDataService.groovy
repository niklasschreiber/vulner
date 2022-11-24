package org.grails.onezeroone.repository.gorm

import grails.gorm.services.Service
import groovy.transform.CompileStatic
import org.grails.onezeroone.SubscriptionDay

@CompileStatic
@Service(CourseSubscriberGormEntity)
interface CourseSubscriberDataService {
    CourseSubscriberGormEntity save(String email, SubscriptionDay day)
    List<CourseSubscriberGormEntity> findAllByDay(SubscriptionDay day)
}
