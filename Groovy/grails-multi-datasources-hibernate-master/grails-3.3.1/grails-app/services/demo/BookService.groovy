package demo

import grails.gorm.transactions.Transactional
import groovy.transform.CompileStatic

@CompileStatic
class BookService {

    @Transactional('books')
    List<Book> findAll() {
        Book.where { }.list()
    }
}