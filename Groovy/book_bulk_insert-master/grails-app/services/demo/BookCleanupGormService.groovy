package demo

import grails.config.Config
import grails.core.support.GrailsConfigurationAware
import grails.gorm.transactions.Transactional
import groovy.transform.CompileStatic
import org.hibernate.SessionFactory

@CompileStatic
class BookCleanupGormService implements BookGateway, GrailsConfigurationAware {

    SessionFactory sessionFactory
    int batchSize

    @Override
    void setConfiguration(Config co) {
        batchSize = co.getProperty('demo.batchsize', Integer, 100)
    }

    @Transactional
    @Override
    void importBooksInLibrary(Library library) {
        library.eachWithIndex { Object bookValueMap, int index ->
            updateOrInsertBook(bookValueMap as Map)
            if (index % batchSize == 0) cleanUpGorm()
        }
    }

    def cleanUpGorm() {
        def session = sessionFactory.currentSession
        session.flush()
        session.clear()
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