yieldUnescaped '<!DOCTYPE html>'
html {
    head {
        title('Bootiful Groovy Templates')
    }
    body {
        h1 "Bootiful Groovy Templates"

        div(style: 'color: red') {
            ul {
                reservationList.each {
                    li it.reservationName
                }
            }

        }
    }
}
