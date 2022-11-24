package demo

import groovy.transform.CompileStatic

@CompileStatic
class BookController {

    BookService bookService

    def index() {
        List<Book> bookList = bookService.findAll()
        render "Books: ${bookList*.title.join(' ')}"
    }

    def count() {
        int count = Book.withTransaction(readOnly: true) {
            Book.count()
        }
        render "# of Books: ${count}"
    }

}