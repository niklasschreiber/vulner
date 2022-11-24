package demo

import geb.spock.GebSpec
import grails.testing.mixin.integration.Integration

@Integration
class BookControllerSpec extends GebSpec {

    def "fetch books"() {
        when:
        browser.go '/book/index'

        then:
        browser.driver.pageSource.contains('Books Grails - The definitive Guide')
    }
}
