package demo

import grails.gorm.transactions.Transactional

@Transactional
class CarService {

    Car saveCar(String name) {
        Car car = new Car(name: name)
        car.save()
        car
    }

    List<Car> findAll() {
        Car.where { }.list() as List<Car>
    }
}