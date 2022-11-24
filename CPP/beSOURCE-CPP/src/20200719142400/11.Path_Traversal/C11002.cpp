//
// 
//

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void cwe36_bad()
{
  char* rName = getenv("reportName");
  unlink(rName);
}
