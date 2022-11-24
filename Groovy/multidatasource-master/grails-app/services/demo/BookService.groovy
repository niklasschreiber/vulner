package demo

import grails.gorm.transactions.ReadOnly
import grails.gorm.transactions.Transactional
import groovy.transform.CompileStatic

@CompileStatic
class BookService {

    @Transactional('books')
    Book saveBook(String name) {
        Book book = new Book(title: name)
        book.save()
        book
    }

    @ReadOnly('books')
    List<Book> findAll() {
        Book.where { }.list() as List<Book>
    }
}