static int stressone(unsigned long long ramsizeMB)
{
    size_t pagesPerMB = 1024 * 1024 / PAGE_SIZE;
    char *ram = malloc(ramsizeMB * 1024 * 1024);
    char *ramptr;
    size_t i, j, k;
    char *data = malloc(PAGE_SIZE);
    char *dataptr;
    size_t nMB = 0;
    unsigned long long before, after;

    if (!ram) {
        fprintf(stderr, "%s (%05d): ERROR: cannot allocate %llu MB of RAM: %s\n",
                argv0, gettid(), ramsizeMB, strerror(errno));
        return -1;
    }
    if (!data) {
        fprintf(stderr, "%s (%d): ERROR: cannot allocate %d bytes of RAM: %s\n",
                argv0, gettid(), PAGE_SIZE, strerror(errno));
        free(ram);
        return -1;
    }

    /* We don't care about initial state, but we do want
     * to fault it all into RAM, otherwise the first iter
     * of the loop below will be quite slow. We cna't use
     * 0x0 as the byte as gcc optimizes that away into a
     * calloc instead :-) */
    memset(ram, 0xfe, ramsizeMB * 1024 * 1024);

    if (random_bytes(data, PAGE_SIZE) < 0) {
        free(ram);
        free(data);
        return -1;
    }

    before = now();

    while (1) {

        ramptr = ram;
        for (i = 0; i < ramsizeMB; i++, nMB++) {
            for (j = 0; j < pagesPerMB; j++) {
                dataptr = data;
                for (k = 0; k < PAGE_SIZE; k += sizeof(long long)) {
                    ramptr += sizeof(long long);
                    dataptr += sizeof(long long);
                    *(unsigned long long *)ramptr ^= *(unsigned long long *)dataptr;
                }
            }

            if (nMB == 1024) {
                after = now();
                fprintf(stderr, "%s (%05d): INFO: %06llums copied 1 GB in %05llums\n",
                        argv0, gettid(), after, after - before);
                before = now();
                nMB = 0;
            }
        }
    }

    free(data);
    free(ram);
}