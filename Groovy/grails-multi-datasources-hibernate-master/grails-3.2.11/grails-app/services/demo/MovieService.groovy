package demo

import grails.transaction.Transactional
import groovy.transform.CompileStatic

@CompileStatic
class MovieService {

    @Transactional
    List<Movie> findAll() {
        Movie.where { }.list()
    }
}