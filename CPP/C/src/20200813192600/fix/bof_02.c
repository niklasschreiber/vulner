#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char *test1_aux(int *buf)
{
    char *str = malloc(5);
    buf[9] = 1;  // FIX: replace 10 with 9.
    return str;
}

void test1()
{
    int arr[10];
    char *buf;
    buf = test1_aux(arr);
	// FIX: buf could be NULL.
	if (buf) {
		memset(buf, 0x00, 5);  // FIX: replace 10 with 5.
		// FIX: release buf.
		free(buf);
	}
}

