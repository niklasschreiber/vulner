package org.grails.onezeroone.plugins.gsp

import grails.config.Config
import grails.core.support.GrailsConfigurationAware
import grails.gsp.PageRenderer
import grails.web.mapping.LinkGenerator
import groovy.transform.CompileStatic
import groovy.util.logging.Slf4j
import org.grails.onezeroone.Email
import org.grails.onezeroone.EmailComposer
import org.grails.onezeroone.EmailImpl
import org.grails.onezeroone.SubscriptionDay
import org.springframework.context.MessageSource

@Slf4j
@CompileStatic
class GspComposerService implements EmailComposer, GrailsConfigurationAware {

    PageRenderer groovyPageRenderer
    List<GspModel> gspModelList = []
    String from
    String replyTo

    @Override
    void setConfiguration(Config co) {
        from = co.getRequiredProperty('onezeroone.email.from', String)
        replyTo = co.getRequiredProperty('onezeroone.email.replyTo', String)
        List<String> titles = co.getProperty('onezeroone.email.titles', List, [])
        List<String> bodys = co.getProperty('onezeroone.email.bodys', List, [])
        List<String> days = co.getProperty('onezeroone.email.days', List, [])
        List<String> guides = co.getProperty('onezeroone.email.guides', List, [])

        int enumSize = (SubscriptionDay.values().size() - 1)
        boolean configurationValid = (days.size() == enumSize) && (enumSize == titles.size()) && (enumSize == guides.size()) && ( enumSize == bodys.size())

        log.debug('configurationValid {} - enum #{} bodys #{} guides #{} titles #{} days #{}', configurationValid, enumSize, bodys.size(), guides.size(), titles.size(), days.size())

        if ( !configurationValid ) {
            throw new IllegalStateException('titles, days, guides, and bodys should have the same size. There should be an entry per SubscriptionDay ')
        }

        for ( int i = 0;  i < days.size(); i++ ) {
            gspModelList << new GspModelImpl(title: titles[i],
                    guideUrl: guides[i],
                    day: days[i],
                    body: bodys[i],
            )
        }
    }

    GspModel findGspModel(SubscriptionDay day) {
        SubscriptionDay[] subscriptionDaysArr = SubscriptionDay.values()
        for ( int i = 0; i < subscriptionDaysArr.length; i++ ) {
            if ( subscriptionDaysArr[i] == day ) {
                return gspModelList[i]
            }
        }
        null
    }

    @Override
    Email compose(SubscriptionDay day) {
        GspModel gspModel = findGspModel(day)

        String emailBody = groovyPageRenderer.render([template: '/templates/email', model: gspModel as Map])

        new EmailImpl(
            subject: gspModel.title,
            body: emailBody,
            from: from,
            replyTo: replyTo
        )
    }
}
