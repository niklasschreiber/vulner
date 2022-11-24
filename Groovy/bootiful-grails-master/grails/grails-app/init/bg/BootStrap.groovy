package bg

class BootStrap {

    ReservationService reservationService

    def init = { servletContext ->
        ["Jeff", "Josh", "Elroy", "Judy", "Jane", "George", "Astro", "Rosie"].each {
            reservationService.save(new Reservation(reservationName: it))
        }
    }

    def destroy = {
    }
}
