package demo

import grails.gorm.transactions.Transactional
import groovy.transform.CompileStatic

@CompileStatic
class BookService implements BookGateway {

    @Transactional
    @Override
    void importBooksInLibrary(Library library) {
        library.each { Object bookValueMap ->
            updateOrInsertBook(bookValueMap as Map)
        }
    }

    void updateOrInsertBook(Map bookValueMap) {
        String title = bookValueMap.title
        String isbnValue = bookValueMap.isbn
        String editionValue = bookValueMap.edition
        Book existingBook = Book.where {
            isbn == isbnValue && edition == editionValue
        }.get()

        if (existingBook) { // just update title
            existingBook.title = title
            existingBook.save()
        } else {
            new Book(bookValueMap).save()
        }
    }
}