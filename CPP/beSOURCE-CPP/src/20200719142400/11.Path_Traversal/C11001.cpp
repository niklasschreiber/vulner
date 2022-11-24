//
// 
//

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

void cwe23_bad()
{
  char* rName = getenv("reportName");
  char  buf[30];
          
  strncpy(buf, "/home/www/tmp/", 30);
  strncat(buf, rName, 30);
  unlink(buf);
}
