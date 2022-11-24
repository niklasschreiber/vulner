#include "std_testcase.h"
#include <stdio.h>

void cwe497_bad()
{
    char* path = getenv("PATH");
    /*  */
    sprintf(stderr, "cannot find exe on path %s\n", path);    
}
