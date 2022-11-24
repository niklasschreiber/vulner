#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>

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
*
*
*
*
*
*
*
*/

int no_release(int a)
{
    int *p;
    
	p = (int *)malloc(sizeof(int));  /*  */

	//

	return 0;
}

int partially_no_release(int control)
{
    int *p;
    
    p = (int *)calloc(10, sizeof(int));  /*  */
    
	//
    if (control > 0) {
        free(p);
	} 

    return 0;
}
