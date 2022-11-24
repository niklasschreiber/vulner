package demo

import grails.transaction.Transactional
import groovy.transform.CompileStatic

@CompileStatic
class BookService {

    @Transactional
    List<Book> findAll() {
        Book.where { }.list()
    }
}