#include <stdlib.h>
#include <stdio.h>

#define BUFSIZE 256
struct charbuf
{
    int   n;
    char *buf;
};

int main()
{
    int            i;
    struct charbuf cb;

    cb.n = 0;
    cb.buf = malloc(sizeof(char) * BUFSIZE);

    if (cb.buf == NULL) {
        perror("malloc");
        exit(1);
    }

    for (i = 0; i <= BUFSIZE; i++) {
        cb.n += i;
        cb.buf[i] = cb.n; // ARRAY_INDEX_OUT_OF_BOUND
    }

    free(cb.buf);
}

// Local variables:
// compile-command: "clang -std=c99 -pedantic -Wall -c bof-01.c && \
// c2coil.sh bof-01.c"
// End:
