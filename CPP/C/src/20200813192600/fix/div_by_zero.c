#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int getValue()
{
    int n;
    // FIX improper check for unusual or exceptional conditions: check return value of scanf
    int r = scanf("%d", &n);
    if (r != 1) // failed to read
        return 0;
    else
        return n;
}

void test1(int n)
{
    int m = getValue();
    if (n > 0 && m > 100) {
        printf("%d\n", 1000 / m);
    }
}

void test2(int n)
{
    int m = getValue();
    if (n > 0 && m < 100) {
        if (m > 0) { // FIX division by zero: ensure m is not zero
            printf("%d\n", 1000 / m);
        }
    }
}

// Local variables:
// compile-command: "clang -std=c99 -pedantic -Wall -c div_by_zero-01.c \
// && c2coil.sh div_by_zero-01.c"
// End:
