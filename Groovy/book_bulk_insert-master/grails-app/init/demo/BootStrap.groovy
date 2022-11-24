package demo

class BootStrap {

    def init = { servletContext ->
        println 'Grails env: ' + System.getProperty('grails.env')
    }
    def destroy = {
    }
}
