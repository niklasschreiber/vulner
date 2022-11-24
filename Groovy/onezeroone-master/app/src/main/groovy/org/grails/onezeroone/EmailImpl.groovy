package org.grails.onezeroone

import groovy.transform.CompileStatic

@CompileStatic
class EmailImpl implements Email {
    String subject
    String body
    String from
    String to
    String replyTo
}
