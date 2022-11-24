#include <stdafx.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int cwe330_bad(void)
{
    int count = 0;
    int temp;
    
    printf("\n%s\n%s\n",
        "Some randomly distributed integers will be printed.",
        "How many do you want to see? ");

	/*  */
	srand( 100 );
	while ( 1 )
    {
        if ( count % 6 == 0) printf("%s", "\n");
		
        temp = rand()%101;
		
        if( temp != 100 )
            count++;
        else
			break;
		
        printf("%5d",  temp );
    }
	
    printf("\nCount: %d \n" , count );

    return 0;
}
