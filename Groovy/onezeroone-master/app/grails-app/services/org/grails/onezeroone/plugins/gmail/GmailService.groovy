package org.grails.onezeroone.plugins.gmail

import grails.config.Config
import grails.core.support.GrailsConfigurationAware
import grails.plugins.mail.MailService
import groovy.transform.CompileStatic
import groovy.util.logging.Slf4j
import org.grails.onezeroone.CourseSubscriber
import org.grails.onezeroone.Email
import org.grails.onezeroone.EmailService

@Slf4j
@CompileStatic
class GmailService implements EmailService, GrailsConfigurationAware {

    String username
    String password

    MailService mailService

    @Override
    void setConfiguration(Config co) {
        username = co.getRequiredProperty('grails.mail.username', String)
        password = co.getRequiredProperty('grails.mail.password', String)
    }

    boolean isConfigurationValid() {
        if ( !username || !password ) {
            log.warn('grails.mail.username not configured')
        }
        if ( !password ) {
            log.warn('grails.mail.password not configured')
        }
        username && password
    }

    @Override
    void send(List<CourseSubscriber> subscriberList, Email email) {

        if ( !isConfigurationValid() ) {
            return
        }

        for ( CourseSubscriber courseSubscriber : subscriberList ) {
            log.info "sending email for day ${courseSubscriber.subscriptionDay} to ${courseSubscriber.email}"
            try {
                mailService.sendMail {
                    from email.from
                    to courseSubscriber.email
                    replyTo email.replyTo
                    subject email.subject
                    html email.body
                }
            } catch (Exception e) {
                log.error(e.message, e)
            }
        }
    }
}
