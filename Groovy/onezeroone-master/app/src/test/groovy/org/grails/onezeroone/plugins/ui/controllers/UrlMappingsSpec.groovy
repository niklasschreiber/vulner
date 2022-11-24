package org.grails.onezeroone.plugins.ui.controllers

import grails.testing.web.UrlMappingsUnitTest
import spock.lang.Specification

class UrlMappingsSpec extends Specification implements UrlMappingsUnitTest<UrlMappings> {

    void setup() {
        mockController(SubscribeController)
    }

    void "/subscribe => SubscribeController.subscribe"() {
        expect:
        verifyForwardUrlMapping("/subscribe", controller: 'subscribe', action: 'subscribe')
    }

    void "/ => /index.gsp"() {
        expect:
        verifyForwardUrlMapping("/", view: '/index')
    }
}
