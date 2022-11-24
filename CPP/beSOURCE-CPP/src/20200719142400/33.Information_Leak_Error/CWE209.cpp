#include <stdio.h>
#include <unistd.h>
#include <string.h>

void cwe209_bad()
{
   char* path = getenv("MYPATH");
   // ...
   fprintf(stderr,"File not found:%s\n",path);
}
