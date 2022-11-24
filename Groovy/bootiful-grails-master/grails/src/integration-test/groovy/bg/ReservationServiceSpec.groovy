package bg

import grails.test.mixin.integration.Integration
import grails.gorm.transactions.Rollback
import spock.lang.Specification
import org.hibernate.SessionFactory

@Integration
@Rollback
class ReservationServiceSpec extends Specification {

    ReservationService reservationService
    SessionFactory sessionFactory

    private Long setupData() {
        // TODO: Populate valid domain instances and return a valid ID
        //new Reservation(...).save(flush: true, failOnError: true)
        //new Reservation(...).save(flush: true, failOnError: true)
        //Reservation reservation = new Reservation(...).save(flush: true, failOnError: true)
        //new Reservation(...).save(flush: true, failOnError: true)
        //new Reservation(...).save(flush: true, failOnError: true)
        assert false, "TODO: Provide a setupData() implementation for this generated test suite"
        //reservation.id
    }

    void "test get"() {
        setupData()

        expect:
        reservationService.get(1) != null
    }

    void "test list"() {
        setupData()

        when:
        List<Reservation> reservationList = reservationService.list(max: 2, offset: 2)

        then:
        reservationList.size() == 2
        assert false, "TODO: Verify the correct instances are returned"
    }

    void "test count"() {
        setupData()

        expect:
        reservationService.count() == 5
    }

    void "test delete"() {
        Long reservationId = setupData()

        expect:
        reservationService.count() == 5

        when:
        reservationService.delete(reservationId)
        sessionFactory.currentSession.flush()

        then:
        reservationService.count() == 4
    }

    void "test save"() {
        when:
        assert false, "TODO: Provide a valid instance to save"
        Reservation reservation = new Reservation()
        reservationService.save(reservation)

        then:
        reservation.id != null
    }
}
