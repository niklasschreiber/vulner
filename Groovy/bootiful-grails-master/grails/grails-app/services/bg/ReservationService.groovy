package bg

import grails.gorm.services.Service

@Service(Reservation)
interface ReservationService {

    Reservation get(Serializable id)

    List<Reservation> list(Map args)

    Long count()

    void delete(Serializable id)

    Reservation save(Reservation reservation)

}