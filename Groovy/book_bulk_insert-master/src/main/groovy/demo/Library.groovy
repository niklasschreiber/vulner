package demo

import groovy.util.logging.Slf4j

@Slf4j
class Library implements Iterator {
    def startTime = System.currentTimeMillis()
    def lastBatchStarted = startTime
    def BOOKS_IN_LIBRARY = 100000
    def currentBook = 1
    def random = new Random(12345) // random generator with defined seed

    Iterator iterator() { return this as Iterator }
    boolean hasNext() { currentBook <= BOOKS_IN_LIBRARY }
    void remove() { }
    def next() {
        if (! (currentBook % 100) ) printStatus()

        return [
                title: "Book ${currentBook++}",
                isbn: randomIsbn(),
                edition: randomEdition()
        ]
    }

    def randomIsbn() {
        // one of 50,000 random isbn numbers
        return "isbn-${random.nextInt(50000)}"
    }

    def randomEdition() {
        // first through tenth editions
        return random.nextInt(9) + 1
    }

    def printStatus() {
        def batchEnded = System.currentTimeMillis()
        def seconds = (batchEnded-lastBatchStarted)/1000
        def total = (batchEnded-startTime)/1000
        log.info "Library Book $currentBook, last batch: ${seconds}s, total: ${total}s"
        lastBatchStarted = batchEnded
    }

}
