package org.grails.onezeroone.plugins.ui.controllers

import grails.testing.web.controllers.ControllerUnitTest
import spock.lang.Specification
import spock.lang.Unroll
import static javax.servlet.http.HttpServletResponse.SC_METHOD_NOT_ALLOWED
import static javax.servlet.http.HttpServletResponse.SC_MOVED_TEMPORARILY

class SubscribeControllerAllowedMethodsSpec extends Specification implements ControllerUnitTest<SubscribeController> {

    @Unroll
    def "test SubscribeController.subscribe() does not accept #method requests"(String method) {
        when:
        request.method = method
        controller.subscribe()

        then:
        response.status == SC_METHOD_NOT_ALLOWED

        where:
        method << ['PATCH', 'DELETE', 'GET', 'PUT']
    }

    def "test SubscribeController.subscribe() accepts POST requests"() {
        when:
        request.method = 'POST'
        controller.subscribe()

        then:
        response.status == SC_MOVED_TEMPORARILY
    }
}
