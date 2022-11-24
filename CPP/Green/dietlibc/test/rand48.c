#include <stdio.h>
#include <stdlib.h>

int
main (void)
{
  static unsigned short  data[7] = { 1, 2, 3, 4, 5, 6, 7 };

  printf ("one   %lX\n", mrand48 ());
  printf ("two   %lX\n", mrand48 ());
  printf ("three %lX\n", mrand48 ());

  lcong48 (data);
  printf ("after lcong48:\n");

  printf ("one   %lX\n", mrand48 ());
  printf ("two   %lX\n", mrand48 ());
  printf ("three %lX\n", mrand48 ());

  return 0;
}
