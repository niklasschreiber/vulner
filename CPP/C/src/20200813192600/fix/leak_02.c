#include <stdio.h>
#include <stdlib.h>

int glob = 0;

struct test
{
    int val;
    int arr[10];
};

void inc(int *x)
{
    *x = *x + 1;
}

int leak_test_02()
{
    int          xs[] = { 1, 2, 3 };
    struct test  tt[2];
    int          arr[10];
    struct test *t;
    int          xx, yy;
    int *        ys;
    struct test  ttt;

    ttt.val = 5;

    if ((t = malloc(sizeof(struct test))) == NULL) {
        perror("malloc");
        exit(2);
    }

    xx = yy = 1;
    if (rand()) *ys = (xx && yy) || xs[0];  // ys is not initialized yet.

    t->val = ttt.val;

    if ((ys = malloc(sizeof(int))) == NULL) {
        perror("malloc");
		// FIX resource leak: release t
		free(t);
        exit(3); // leakage
    }

    *ys = yy;
    arr[0] = 1;
    t->val = arr[0] + *ys;

    free(t);

    inc(ys);
    xx = *(&xx) + 1;

    free(ys);
}
