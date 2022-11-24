package org.grails.onezeroone

import com.agileorbit.schwartz.QuartzService
import grails.test.hibernate.HibernateSpec
import grails.testing.services.ServiceUnitTest
import org.grails.onezeroone.usecase.DailyEmailUseCaseService
import org.grails.spring.beans.factory.InstanceFactoryBean
import org.quartz.JobExecutionContext

class DailyJobServiceSpec extends HibernateSpec implements ServiceUnitTest<DailyJobService>  {

    Closure doWithSpring() {{ ->
        quartzService(InstanceFactoryBean, Mock(QuartzService), QuartzService)
    }}

    void 'test daily email job'() {
        given: 'a mocked service'
        service.dailyEmailUseCaseService = Mock(DailyEmailUseCaseService)

        when: 'executing the job'
        service.execute(Mock(JobExecutionContext))

        then:
        1 * service.dailyEmailUseCaseService.sendDailyEmail()
    }
}