import demo.BookCleanupGormService
import demo.BookService

// Place your Spring DSL code here
beans = {
    bookGateway(BookCleanupGormService) {
        sessionFactory = ref('sessionFactory')
    }
    //bookGateway(BookService)
}
