package org.grails.onezeroone.plugins.ui.controllers

class UrlMappings {

    static mappings = {
        name home: "/"(view: '/index')
        "/subscribe"(controller: 'subscribe', action: 'subscribe')
        "500"(view:'/error')
        "404"(view:'/notFound')
    }
}
