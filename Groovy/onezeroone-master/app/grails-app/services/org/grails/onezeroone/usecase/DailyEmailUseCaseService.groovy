package org.grails.onezeroone.usecase

import groovy.transform.CompileStatic
import groovy.util.logging.Slf4j
import org.grails.onezeroone.CourseSubscriber
import org.grails.onezeroone.CourseSubscriberRepository
import org.grails.onezeroone.Email
import org.grails.onezeroone.EmailComposer
import org.grails.onezeroone.EmailService
import org.grails.onezeroone.SubscriptionDay

@Slf4j
@CompileStatic
class DailyEmailUseCaseService {

    CourseSubscriberRepository courseSubscriberRepository
    EmailComposer emailComposer
    EmailService emailService

    void sendEmailToSubscribers() {
        for (SubscriptionDay day : SubscriptionDay.values()) {
            if ( day == SubscriptionDay.FINISHED) {
                continue
            }
            List<CourseSubscriber> subscribers = courseSubscriberRepository.findAllByDay(day)
            if ( !subscribers ) {
                log.debug 'no DAY {} email sent. No subscribers', day.name()
                continue
            }
            Email email = emailComposer.compose(day)

            log.debug('sending {} email to {} subscribers', day.name(), subscribers.size())

            emailService.send(subscribers, email)

        }
    }

    void moveSubscribersToNextDay() {
        for ( SubscriptionDay day : SubscriptionDay.values().reverse() ) {
            if ( day == SubscriptionDay.FINISHED) {
                continue
            }
            List<CourseSubscriber> subscribers = courseSubscriberRepository.findAllByDay(day)
            if ( !subscribers ) {
                log.debug 'no DAY {} subscribers', day.name()
                continue
            }
            SubscriptionDay nextDay = SubscriptionDay.nextDay(day)
            log.debug('moving {}  subscribers from {} to {}', subscribers.size(), day, nextDay)
            courseSubscriberRepository.moveToDay(subscribers, nextDay)
        }
    }

    void sendDailyEmail() {
        sendEmailToSubscribers()
        moveSubscribersToNextDay()
    }
}
