package demo

import groovy.transform.CompileStatic

@CompileStatic
class CarController {

    CarService carService

    def index() {
        render "Cars ${carService.findAll()*.name.join(', ')}"
    }
}