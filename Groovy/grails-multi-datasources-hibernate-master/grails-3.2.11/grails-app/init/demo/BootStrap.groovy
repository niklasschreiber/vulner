package demo

class BootStrap {

    def init = { servletContext ->

        new Movie(title: 'Pirates of the Sillicon Valley').save()
        new Movie(title: 'Inception').save()
        new Book(title: 'Daemon').save()
        new Book(title: 'Freedom (TM)').save()

    }
    def destroy = {
    }
}
