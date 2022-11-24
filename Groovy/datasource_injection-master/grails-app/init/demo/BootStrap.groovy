package demo

import groovy.transform.CompileStatic

@CompileStatic
class BootStrap {

    def init = { servletContext ->
        new Book(title: 'The pirates of the sillicon valley').save()
        new Book(title: 'Inception').save()
    }
    def destroy = {
    }
}
