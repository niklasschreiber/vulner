#include <assert.h>
#include <stdio.h>

struct S
{
    int n;
    char *str;
};

typedef struct S s;

extern int nondet;

int test_struct_01(int argc, char *argv[])
{
    struct S s1;
    s s2 = { 1 };

    // FIX use of uninitialized variable: initialize s1
    s1.n = 0;
    s1.str = "hello";
    
    if (nondet) {
        printf("s1.n\t%d\n", s1.n);      // uninitialized field
        printf("s1.str\t%s\n", s1.str);  // uninitialized pointer
    } else {
        assert(s2.n == 1);
        assert(s2.str == NULL);
    }

    return 0;
}

struct S global_s;

int test_struct_02()
{
    // fields of global_s are initialized with 0.
    printf("s.n\t%d\n", global_s.n);      // global_s.n = 0
}