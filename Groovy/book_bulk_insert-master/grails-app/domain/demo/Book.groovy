package demo

import grails.compiler.GrailsCompileStatic

@GrailsCompileStatic
class Book {
    String title
    String isbn
    Integer edition

    static mapping = {
        isbn index: 'isbn_idx'
        edition index: 'isbn_idx,edition_idx'
    }
}