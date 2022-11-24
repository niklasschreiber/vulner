#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int getValue()
{
    int n;
    scanf("%d", &n);
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
        printf("%d\n", 1000 / m);
    }
}

// Local variables:
// compile-command: "clang -std=c99 -pedantic -Wall -c div_by_zero-01.c \
// && c2coil.sh div_by_zero-01.c"
// End:
