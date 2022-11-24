package demo

import groovy.transform.CompileStatic

@CompileStatic
class BookController {

    BookService bookService

    def index() {
        render "Books ${bookService.findAll()*.title.join(', ')}"
    }
}