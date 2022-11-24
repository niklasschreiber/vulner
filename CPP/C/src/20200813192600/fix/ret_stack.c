#include <stdlib.h>
#include <stdio.h>

int *test1()
{
    int x = 5;
    
    int *p = malloc(sizeof(int));
    if (p) *p = x;
    return p;

    // return &x;
}

int *test2()
{
    int x = 5;
    // int *p = &x;
    
    int *p = malloc(sizeof(int));
    if (p) *p = x;

    return p;
}

// Local variables:
// compile-command: "clang -pedantic -Wall -c ret_stack-01.c \
// && c2coil.sh ret_stack-01.c"
// End:
