package demo

import groovy.sql.GroovyRowResult
import groovy.transform.CompileDynamic
import groovy.transform.CompileStatic
import groovy.util.logging.Slf4j
import groovy.sql.Sql

@CompileStatic
@Slf4j
class BookService {

    def dataSource

    @CompileDynamic
    protected Sql sql() {
        new Sql(dataSource)
    }

    int count() {
        Sql sql = sql()
        List<GroovyRowResult> rows = sql.rows('SELECT COUNT(*) FROM book')
        if (rows.isEmpty()) {
            return 0
        }
        rows.get(0).getAt(0) as int
    }
}