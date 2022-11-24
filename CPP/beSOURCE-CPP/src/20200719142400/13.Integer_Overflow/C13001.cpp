//
// 
//

#include <stdlib.h>

void* intAlloc(int size, int reserve) 
{
  void *rptr; 
  size += reserve;
  rptr = malloc(size * sizeof(int));
  if (rptr == NULL)  exit(1);
  return rptr;
} 
