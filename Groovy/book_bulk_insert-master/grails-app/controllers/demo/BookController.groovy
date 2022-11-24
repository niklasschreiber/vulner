package demo

import groovy.transform.CompileStatic
import demo.Library

@CompileStatic
class BookController {

    BookGateway bookGateway

    def index = {
        def library = new Library()
        def startTime = System.currentTimeMillis()
        bookGateway.importBooksInLibrary(library)
        render "time: ${(startTime - System.currentTimeMillis())/1000} seconds"
    }

}