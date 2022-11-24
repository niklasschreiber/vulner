package demo

import groovy.transform.CompileStatic

@CompileStatic
class BootStrap {

    CarService carService
    BookService bookService

    def init = { servletContext ->
        carService.saveCar('Audi')
        bookService.saveBook('Grails - The definitive Guide')
    }
    def destroy = {
    }
}
