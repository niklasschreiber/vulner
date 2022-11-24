package org.grails.onezeroone

import groovy.transform.CompileStatic

@CompileStatic
enum SubscriptionDay {
    ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, FINISHED

    static SubscriptionDay nextDay(SubscriptionDay day) {
        if ( day == FINISHED) {
            return FINISHED
        }
        day.next()
    }
}
