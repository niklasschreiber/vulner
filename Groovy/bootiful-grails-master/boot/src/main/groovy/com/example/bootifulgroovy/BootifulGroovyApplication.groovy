package com.example.bootifulgroovy

import groovy.transform.EqualsAndHashCode
import groovy.transform.ToString
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.ApplicationRunner
import org.springframework.boot.SpringApplication
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.context.annotation.Bean
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Controller
import org.springframework.ui.Model
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.servlet.ModelAndView

import javax.persistence.Entity
import javax.persistence.GeneratedValue
import javax.persistence.Id

@SpringBootApplication
class BootifulGroovyApplication {

    static void main(String[] args) {
        SpringApplication.run BootifulGroovyApplication, args
    }

    @Bean
    def initializer(ReservationRepository repository) {
        { args ->

            ["Jeff", "Nicki", "Josh"].forEach { repository.save(new Reservation(reservationName: it)) }

            repository.findAll().forEach { println it }

        } as ApplicationRunner
    }
}

@RestController
class ReservationRestController {

    @Autowired
    ReservationRepository reservationRepository

    @GetMapping('/reservations')
    def reservations() {
        reservationRepository.findAll()
    }

    @GetMapping('/reservations/{name}')
    def reservationsByName(@PathVariable String name) {
        reservationRepository.findByReservationName name
    }
}

@Controller
class ReservationMvcController {

    @Autowired
    ReservationRepository reservationRepository

    @GetMapping("/reservations.groovy")
    def groovyReservations() {
        new ModelAndView("reservations", [reservationList: reservationRepository.findAll()])
    }
}

interface ReservationRepository extends JpaRepository<Reservation, Long> {

    Collection<Reservation> findByReservationName(@Param("rn") String rn)
}

@Entity
@ToString
@EqualsAndHashCode
class Reservation {

    @Id
    @GeneratedValue
    Long id

    String reservationName
}