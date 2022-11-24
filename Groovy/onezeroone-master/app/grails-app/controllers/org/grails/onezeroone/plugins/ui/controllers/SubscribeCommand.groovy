package org.grails.onezeroone.plugins.ui.controllers

import grails.compiler.GrailsCompileStatic
import grails.validation.Validateable

@GrailsCompileStatic
class SubscribeCommand implements Validateable {

    String email

    static constraints = {
        email nullable: false, blank: false, email: true
    }
}
