// Generating a random variable value.
def var = UUID.randomUUID()

// Logging the variable.
log.info var

// Generating a random item identifier.
log.info "Item: ${java.util.UUID.randomUUID()}"