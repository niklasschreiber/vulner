package bg

import grails.rest.Resource

//@Entity
@Resource(uri = "/reservations", formats = ["html", "json", "xml"])
class Reservation {
    /*
        @Id
        @GeneratedValue
        Long id
    */

    String reservationName

    static constraints = {
        reservationName matches: /[A-Z].*/
    }
}
