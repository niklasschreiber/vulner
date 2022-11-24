#include <stdio.h>
#include <stdlib.h>

void *aux_malloc(size_t s)
{
    void *p;

    if ((p = malloc(s)) == NULL) {
        perror("malloc");
        exit(1);
    }

    return p;
}

void leak_test()
{
    int *p;

    p = aux_malloc(sizeof(int));
}


// Local variables:
// compile-command: "clang -std=c99 -pedantic -Wall -c leak-02.c && \
// c2coil.sh leak-02.c"
// End:
