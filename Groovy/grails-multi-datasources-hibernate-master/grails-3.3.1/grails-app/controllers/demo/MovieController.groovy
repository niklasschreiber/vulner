package demo

import groovy.transform.CompileStatic

@CompileStatic
class MovieController {

    MovieService movieService

    def index() {
        List<Movie> movieList = movieService.findAll()
        render "Movies: ${movieList*.title.join(' ')}"
    }

    def count() {
        render "# of Movies: ${Movie.count()}"
    }

}