package org.grails.onezeroone

import grails.util.Environment
import groovy.transform.CompileStatic
import org.quartz.Scheduler

@CompileStatic
class BootStrap {

    Scheduler quartzScheduler

    def init = { servletContext ->
        if ( Environment.current == Environment.DEVELOPMENT ) {
            configureForDevelopment()
        } else if ( Environment.current == Environment.TEST ) {
            configureForTest()
        } else if ( Environment.current == Environment.PRODUCTION ) {
            configureForProduction()
        }
    }

    void configureForDevelopment() {
        quartzScheduler.start()
    }

    void configureForProduction() {
        quartzScheduler.start()
    }

    void configureForTest() {
    }

    def destroy = {
    }
}
