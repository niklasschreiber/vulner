package org.grails.onezeroone.plugins.ui.controllers

import spock.lang.Shared
import spock.lang.Specification
import spock.lang.Subject
import spock.lang.Unroll

class SubscribeCommandSpec extends Specification {

    @Subject
    @Shared
    SubscribeCommand cmd = new SubscribeCommand()

    @Unroll
    void "email '#value' #description"(String value, boolean expected, String expectedErrorCode, String description) {
        when:
        cmd.email = value

        then:
        expected == cmd.validate(['email'])
        cmd.errors['email']?.code == expectedErrorCode

        where:
        value                  | expected | expectedErrorCode
        null                   |  false   | 'nullable'
        ''                     |  false   | 'blank'
        'contact@gmail.com'    |  true    | null
        'contact'              |  false   | 'email.invalid'
        description = expected ? 'is valid' : 'is not valid'
    }
}
