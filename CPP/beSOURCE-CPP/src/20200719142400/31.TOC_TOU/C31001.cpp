#include <stdio.h>
#include <unistd.h>

/**
* 
* 
* 
* 
*
* 
* 
* 
*
*
* 
* 
*
*
*/

void file_operation(char* file) {
  FILE* f;
  if(!access(file,W_OK)) {
    f = fopen(file,"w+"); 
    operate(f);
   }
  else {
    fprintf(stderr,"Unable to open file %s.\n",file);
  }
}
