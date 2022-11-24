package org.grails.onezeroone

import com.agileorbit.schwartz.StatefulSchwartzJob
import grails.gorm.transactions.Transactional
import groovy.transform.CompileStatic
import groovy.util.logging.Slf4j
import org.grails.onezeroone.usecase.DailyEmailUseCaseService
import org.quartz.JobExecutionContext
import org.quartz.JobExecutionException
import static org.quartz.DateBuilder.todayAt
import static org.quartz.DateBuilder.tomorrowAt

@Slf4j
@CompileStatic
class DailyJobService implements StatefulSchwartzJob {
    final int HOUR = 7
    final int MINUTE = 30
    final int SECONDS = 0

    DailyEmailUseCaseService dailyEmailUseCaseService

    @Transactional
    void execute(JobExecutionContext context) throws JobExecutionException {
        log.debug "${context?.trigger?.key}/${context?.jobDetail?.key} at ${new Date()}"

        dailyEmailUseCaseService.sendDailyEmail()
    }

    Date dailyDate() {
        Date startAt = todayAt(HOUR, MINUTE, SECONDS)
        if (startAt.before(new Date())) {
            return tomorrowAt(HOUR, MINUTE, SECONDS)
        }
        startAt
    }

    void buildTriggers() {
        Date startAt = dailyDate()
        triggers << factory('Daily_job_at_seven_thirty')
                .startAt(startAt)
                .intervalInDays(1)
                .build()
        triggers << factory('Skroob_EverySecond').intervalInSeconds(30).build()

    }
}
