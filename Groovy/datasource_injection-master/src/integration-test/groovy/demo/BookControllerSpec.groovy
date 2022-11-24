package demo

import geb.spock.GebSpec
import grails.testing.mixin.integration.Integration

@Integration
class BookControllerSpec extends GebSpec {

    def "test default datasource can be injected"() {
        when:
        browser.go '/book/index'

        then:
        browser.page.downloadText() == '# of Books: 2'
    }
}
