package org.grails.onezeroone.repository.gorm

import grails.gorm.DetachedCriteria
import grails.gorm.services.Service
import grails.gorm.transactions.ReadOnly
import grails.gorm.transactions.Transactional
import groovy.transform.CompileStatic
import org.grails.onezeroone.CourseSubscriber
import org.grails.onezeroone.CourseSubscriberRepository
import org.grails.onezeroone.SubscriptionDay

@CompileStatic
@Service(CourseSubscriber)
class CourseSubscriberGormService implements CourseSubscriberRepository {

    CourseSubscriberDataService courseSubscriberDataService

    @ReadOnly
    @Override
    List<CourseSubscriber> findAllByDay(SubscriptionDay day) {
        courseSubscriberDataService.findAllByDay(day).collect { CourseSubscriberGormEntity gormEntity ->
            CourseSubscriberGormEntityUtils.of(gormEntity)
        } as List<CourseSubscriber>
    }

    @Transactional
    @Override
    void moveToDay(List<CourseSubscriber> courseSubscriberList, SubscriptionDay day) {
        List<String> emailList = courseSubscriberList*.email
        DetachedCriteria<CourseSubscriberGormEntity> query = CourseSubscriberGormEntity.where {
            email in emailList
        }
        query.updateAll(day: day)
    }

    @Transactional
    @Override
    CourseSubscriber save(CourseSubscriber subscriber) {
        CourseSubscriberGormEntity gormEntity = courseSubscriberDataService.save(subscriber.email, subscriber.subscriptionDay)
        CourseSubscriberGormEntityUtils.of(gormEntity)
    }
}