package demo

import grails.gorm.transactions.Transactional
import groovy.transform.CompileStatic

@CompileStatic
class MovieService {

    @Transactional
    List<Movie> findAll() {
        Movie.where { }.list()
    }
}