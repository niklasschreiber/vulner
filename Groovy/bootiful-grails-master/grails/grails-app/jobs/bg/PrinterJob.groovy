package bg

class PrinterJob {

    ReservationService reservationService

    static triggers = {
        simple repeatInterval: 5000l // execute job once in 5 seconds
    }

    def execute() {

        println("there are ${reservationService.count()} records in the DB")

        reservationService.list().each { x ->
            println "${x.reservationName} ${x.id}"
        }

    }
}
