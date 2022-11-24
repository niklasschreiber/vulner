package demo

import groovy.transform.CompileStatic

@CompileStatic
interface BookGateway {
    void importBooksInLibrary(Library library)
}