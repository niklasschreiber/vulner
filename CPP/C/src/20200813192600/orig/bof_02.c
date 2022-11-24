#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char *test1_aux(int *buf)
{
    char *str = malloc(5);
    buf[10] = 1;
    return str;
}

void test1()
{
    int arr[10];
    char *buf;
    buf = test1_aux(arr);
    memset(buf, 0x00, 10);
}

