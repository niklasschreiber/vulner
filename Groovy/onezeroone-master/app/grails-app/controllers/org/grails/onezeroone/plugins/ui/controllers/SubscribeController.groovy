package org.grails.onezeroone.plugins.ui.controllers

import groovy.transform.CompileStatic
import org.grails.onezeroone.usecase.SubscribeUseCaseService

@CompileStatic
class SubscribeController {
    static responseFormats = ['html']

    static allowedMethods = [subscribe: 'POST']

    SubscribeUseCaseService subscribeUseCaseService

    def subscribe(SubscribeCommand cmd) {
        if (cmd.hasErrors()) {
            flash.error = 'The email is not valid'
            redirect mapping: 'home'
            return
        }

        boolean result = subscribeUseCaseService.subscribe(cmd.email)

        render view: result ? '/subscribe/success' : '/subscribe/failure'
    }
}
